import '../models/five_day_period.dart';

/// Upper bound used for open-ended periods in `YYYY-MM-DD` comparisons.
const String _openEndDateString = '9999-12-31';

/// Inclusive date range of the five-day working-week mode.
///
/// [end] is `null` while the end of the period is not decided yet; such a
/// period lasts indefinitely.
class FiveDayRange {
  final DateTime start;
  final DateTime? end;

  FiveDayRange(DateTime start, [DateTime? end])
      : start = _dateOnly(start),
        end = end == null ? null : _dateOnly(end);

  bool contains(DateTime date) {
    final day = _dateOnly(date);
    if (day.isBefore(start)) return false;
    final currentEnd = end;
    return currentEnd == null || !day.isAfter(currentEnd);
  }
}

/// App-wide working-week schedule.
///
/// The working week has six days (Mon–Sat) by default and five days (Mon–Fri)
/// inside every configured [FiveDayRange]. Sunday is always a day off.
class WorkSchedule {
  static const int fiveDayWeek = 5;
  static const int sixDayWeek = 6;

  final List<FiveDayRange> fiveDayRanges;

  /// A schedule without five-day periods: every week has six days.
  const WorkSchedule([this.fiveDayRanges = const []]);

  /// Builds a schedule from stored periods, skipping malformed records so a
  /// damaged entry from an old backup cannot break the reports.
  factory WorkSchedule.fromPeriods(Iterable<FiveDayPeriod> periods) {
    final ranges = <FiveDayRange>[];
    for (final period in periods) {
      final start = parseScheduleDate(period.startDate);
      if (start == null) continue;
      final endString = period.endDate;
      final end = endString == null ? null : parseScheduleDate(endString);
      if (endString != null && end == null) continue;
      if (end != null && end.isBefore(start)) continue;
      ranges.add(FiveDayRange(start, end));
    }
    return WorkSchedule(ranges);
  }

  /// Whether [date] falls inside a five-day period.
  bool isFiveDayDate(DateTime date) =>
      fiveDayRanges.any((range) => range.contains(date));

  /// Whether [date] is a Saturday that is a day off under this schedule.
  bool isNonWorkingSaturday(DateTime date) =>
      date.weekday == DateTime.saturday && isFiveDayDate(date);

  /// Working week length (5 or 6) for the calendar week containing [date].
  ///
  /// The two modes only differ on Saturday, so the mode of a week is decided
  /// by its Saturday: a working Saturday belongs to the week (Mon–Sat), a
  /// day-off Saturday is grouped with Sunday (Mon–Fri + weekend). A period
  /// that starts or ends in the middle of a week therefore never splits the
  /// working days of that week.
  int workWeekDaysForWeekOf(DateTime date) {
    final day = _dateOnly(date);
    final saturday = DateTime(
      day.year,
      day.month,
      day.day + (DateTime.saturday - day.weekday),
    );
    return isFiveDayDate(saturday) ? fiveDayWeek : sixDayWeek;
  }
}

/// Parses a strict `YYYY-MM-DD` schedule date into local midnight.
DateTime? parseScheduleDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3 ||
      parts[0].length != 4 ||
      parts[1].length != 2 ||
      parts[2].length != 2) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

/// Formats [date] as `YYYY-MM-DD`.
String formatScheduleDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Returns the first stored period that shares at least one day with the
/// range [startDate]..[endDate] (`null` end = open-ended), ignoring the record
/// with [excludeId] (the period being edited).
FiveDayPeriod? findOverlappingFiveDayPeriod(
  Iterable<FiveDayPeriod> periods,
  String startDate,
  String? endDate, {
  int? excludeId,
}) {
  final end = endDate ?? _openEndDateString;
  for (final period in periods) {
    if (excludeId != null && period.id == excludeId) continue;
    final otherEnd = period.endDate ?? _openEndDateString;
    final overlaps = period.startDate.compareTo(end) <= 0 &&
        startDate.compareTo(otherEnd) <= 0;
    if (overlaps) return period;
  }
  return null;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
