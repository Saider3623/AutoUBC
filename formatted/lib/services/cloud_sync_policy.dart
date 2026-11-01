/// Pure decision rules for Google Drive synchronization.
///
/// Nothing here touches the network, the file system or Flutter, so every
/// rule that can overwrite user data is covered by plain unit tests.
library;

/// Content summary of one copy of the database (local or cloud).
///
/// Two summaries are compared to decide whether a copy can replace another
/// one without losing data, and they are shown to the user when the copies
/// differ.
class DatabaseSummary {
  final int cars;
  final int odometerLogs;
  final int fuelLogs;
  final int reminders;
  final int serviceLogs;
  final int notes;

  /// Newest odometer or fuel entry date (`YYYY-MM-DD`), `null` when none.
  final String? lastEntryDate;

  const DatabaseSummary({
    required this.cars,
    required this.odometerLogs,
    required this.fuelLogs,
    required this.reminders,
    required this.serviceLogs,
    required this.notes,
    this.lastEntryDate,
  });

  static const DatabaseSummary empty = DatabaseSummary(
    cars: 0,
    odometerLogs: 0,
    fuelLogs: 0,
    reminders: 0,
    serviceLogs: 0,
    notes: 0,
  );

  /// Number of records of every kind except cars.
  int get entries => odometerLogs + fuelLogs + reminders + serviceLogs + notes;

  /// A database without cars holds no user data that could be lost.
  bool get isEmpty => cars == 0 && entries == 0;

  bool sameContentAs(DatabaseSummary other) =>
      cars == other.cars &&
      odometerLogs == other.odometerLogs &&
      fuelLogs == other.fuelLogs &&
      reminders == other.reminders &&
      serviceLogs == other.serviceLogs &&
      notes == other.notes &&
      lastEntryDate == other.lastEntryDate;

  /// Whether this copy has at least as many records of every kind as [other]
  /// and entries at least as recent. Used only to recognise a local database
  /// that is simply newer than its own earlier upload.
  bool covers(DatabaseSummary other) =>
      cars >= other.cars &&
      odometerLogs >= other.odometerLogs &&
      fuelLogs >= other.fuelLogs &&
      reminders >= other.reminders &&
      serviceLogs >= other.serviceLogs &&
      notes >= other.notes &&
      _compareDates(lastEntryDate, other.lastEntryDate) >= 0;

  @override
  String toString() =>
      'DatabaseSummary(cars: $cars, odometer: $odometerLogs, '
      'fuel: $fuelLogs, reminders: $reminders, service: $serviceLogs, '
      'notes: $notes, last: $lastEntryDate)';
}

int _compareDates(String? a, String? b) {
  if (a == b) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return a.compareTo(b);
}

/// What to do when this device has not yet confirmed which copy is the
/// reference for the signed-in Google account.
enum BaselineAction {
  /// Both copies are empty or identical: nothing to transfer.
  alreadyInSync,

  /// The cloud has no backup (or an empty one): local data becomes the cloud
  /// copy.
  uploadLocal,

  /// The local database is empty and the cloud has data: restore it.
  restoreCloud,

  /// The copies differ and neither can replace the other safely: the user
  /// must choose.
  ask,
}

/// Decides how the local and the cloud copies relate before the first upload
/// of this device for an account.
///
/// [cloud] is `null` when Drive has no backup file. [interactive] is true for
/// an explicit sign-in: there the user is asked whenever the copies differ.
/// During a silent start (an app update on a device that was already syncing)
/// a local copy that [DatabaseSummary.covers] the cloud copy is treated as
/// its newer version.
BaselineAction resolveBaseline({
  required DatabaseSummary local,
  required DatabaseSummary? cloud,
  required bool interactive,
}) {
  if (cloud == null) {
    return local.isEmpty
        ? BaselineAction.alreadyInSync
        : BaselineAction.uploadLocal;
  }
  if (local.sameContentAs(cloud)) return BaselineAction.alreadyInSync;
  if (local.isEmpty) return BaselineAction.restoreCloud;
  if (cloud.isEmpty) return BaselineAction.uploadLocal;
  if (!interactive && local.covers(cloud)) return BaselineAction.uploadLocal;
  return BaselineAction.ask;
}

/// File name of the main cloud backup in the Drive app data folder.
const String cloudBackupFileName = 'autoubc_backup.isar';

/// Prefix of the dated cloud copies kept before the main backup is replaced.
const String cloudDatedCopyPrefix = 'autoubc_backup_';

/// Name of the dated cloud copy for [now]. With [unique] the time is added,
/// so an explicit replacement never reuses the copy of the day.
String datedCloudCopyName(DateTime now, {bool unique = false}) {
  String two(int value) => value.toString().padLeft(2, '0');
  final date = '${now.year}-${two(now.month)}-${two(now.day)}';
  final time = unique
      ? '_${two(now.hour)}${two(now.minute)}${two(now.second)}'
      : '';
  return '$cloudDatedCopyPrefix$date$time.isar';
}

/// Returns the dated copies to delete: the [keepRecent] newest copies are
/// kept, plus the newest copy of each of the [keepMonths] newest months.
/// Names that do not carry a date are never deleted.
List<String> datedCopiesToDelete(
  Iterable<String> names, {
  int keepRecent = 14,
  int keepMonths = 6,
}) {
  final dated = <String>[];
  for (final name in names) {
    if (_copyDate(name) != null) dated.add(name);
  }
  dated.sort((a, b) => b.compareTo(a));

  final keep = <String>{...dated.take(keepRecent)};
  final months = <String>{};
  for (final name in dated) {
    final month = _copyDate(name)!.substring(0, 7);
    if (months.contains(month)) continue;
    if (months.length >= keepMonths) break;
    months.add(month);
    keep.add(name);
  }
  return [
    for (final name in dated)
      if (!keep.contains(name)) name,
  ];
}

final RegExp _datedCopyPattern = RegExp(
  r'^autoubc_backup_(\d{4}-\d{2}-\d{2})(_\d{6})?\.isar$',
);

String? _copyDate(String name) => _datedCopyPattern.firstMatch(name)?.group(1);

/// Returns the local backup files to delete.
///
/// Kept: the [keepRecent] newest backups, the newest backup of each of the
/// [keepDays] newest days and of each of the [keepWeeks] newest weeks, and
/// the [keepTagged] newest tagged copies (made before a restore or a car
/// deletion). Names look like `autoubc_backup_20261029_0815.isar` or
/// `autoubc_backup_20261029_0815_before-restore.isar`; other names are kept.
List<String> localBackupsToDelete(
  Iterable<String> names, {
  int keepRecent = 3,
  int keepDays = 7,
  int keepWeeks = 4,
  int keepTagged = 5,
}) {
  final regular = <String>[];
  final tagged = <String>[];
  final stamps = <String, DateTime>{};
  for (final name in names) {
    final match = _localBackupPattern.firstMatch(name);
    if (match == null) continue;
    final stamp = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
    stamps[name] = stamp;
    (match.group(6) == null ? regular : tagged).add(name);
  }
  int newestFirst(String a, String b) {
    final byTime = stamps[b]!.compareTo(stamps[a]!);
    return byTime != 0 ? byTime : b.compareTo(a);
  }

  regular.sort(newestFirst);
  tagged.sort(newestFirst);

  final keep = <String>{
    ...regular.take(keepRecent),
    ...tagged.take(keepTagged),
  };
  final days = <String>{};
  final weeks = <String>{};
  for (final name in regular) {
    final stamp = stamps[name]!;
    final day = '${stamp.year}-${stamp.month}-${stamp.day}';
    if (days.length < keepDays && days.add(day)) keep.add(name);
    final monday = DateTime(
      stamp.year,
      stamp.month,
      stamp.day - (stamp.weekday - 1),
    );
    final week = '${monday.year}-${monday.month}-${monday.day}';
    if (weeks.length < keepWeeks && weeks.add(week)) keep.add(name);
  }
  return [
    for (final name in [...regular, ...tagged])
      if (!keep.contains(name)) name,
  ];
}

final RegExp _localBackupPattern = RegExp(
  r'^autoubc_backup_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(_[a-z-]+)?\.isar$',
);

/// Time and tag of a local backup file name, `null` for other names.
({DateTime time, String? tag})? parseLocalBackupName(String name) {
  final match = _localBackupPattern.firstMatch(name);
  if (match == null) return null;
  final tag = match.group(6);
  return (
    time: DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    ),
    tag: tag?.substring(1),
  );
}

/// Date of a dated cloud copy name, `null` for other names.
DateTime? parseDatedCopyDate(String name) {
  final date = _copyDate(name);
  return date == null ? null : DateTime.tryParse(date);
}
