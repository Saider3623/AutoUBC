import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/cloud_sync_controller.dart';
import '../services/cloud_sync_policy.dart';
import '../theme/app_theme.dart';

/// Asks which copy to keep when the phone and Google Drive hold different
/// data. Returns `null` when the user postpones the decision.
Future<ConflictChoice?> showCloudConflictDialog(
  BuildContext context,
  CloudComparison comparison,
) {
  return showDialog<ConflictChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final loc = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(loc.cloudConflictTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.cloudConflictBody),
              const SizedBox(height: 16),
              CloudComparisonTable(comparison: comparison),
            ],
          ),
        ),
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cloudDecideLater),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, ConflictChoice.usePhone),
            child: Text(loc.cloudUsePhone),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ConflictChoice.useCloud),
            child: Text(loc.cloudUseDrive),
          ),
        ],
      );
    },
  );
}

/// Confirms replacing the phone data with a copy. [sourceColumn] names the
/// copy's column (Google Drive by default, "Backup" for a local backup).
Future<bool> showCloudRestoreDialog(
  BuildContext context,
  CloudComparison comparison, {
  String? sourceColumn,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final loc = AppLocalizations.of(context)!;
      return AlertDialog(
        title: Text(loc.cloudRestoreTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.cloudRestoreBody),
              const SizedBox(height: 16),
              CloudComparisonTable(
                comparison: comparison,
                sourceColumn: sourceColumn,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.cloudRestoreAction),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

/// Shows a blocking progress dialog while [action] runs.
Future<T> runWithProgress<T>(
  BuildContext context,
  String message,
  Future<T> Function() action,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await action();
  } finally {
    navigator.pop();
  }
}

/// Side-by-side summary of the phone and Google Drive copies.
class CloudComparisonTable extends StatelessWidget {
  final CloudComparison comparison;
  final String? sourceColumn;

  const CloudComparisonTable({
    super.key,
    required this.comparison,
    this.sourceColumn,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final textTheme = Theme.of(context).textTheme;
    final header = textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    final local = comparison.local;
    final cloud = comparison.cloud;

    String date(String? value) {
      final parsed = value == null ? null : DateTime.tryParse(value);
      return parsed == null
          ? '—'
          : DateFormat.yMMMd(languageCode).format(parsed);
    }

    TableRow row(String label, String phone, String drive) {
      final differs = phone != drive;
      final valueStyle = textTheme.bodyMedium?.copyWith(
        fontWeight: differs ? FontWeight.w700 : FontWeight.w400,
      );
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label, style: textTheme.bodyMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(phone, textAlign: TextAlign.end, style: valueStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(drive, textAlign: TextAlign.end, style: valueStyle),
          ),
        ],
      );
    }

    int other(DatabaseSummary summary) =>
        summary.reminders + summary.serviceLogs + summary.notes;

    final modified = comparison.cloudModified;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.6),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.2),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              children: [
                const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    loc.cloudColumnPhone,
                    textAlign: TextAlign.end,
                    style: header,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    sourceColumn ?? loc.cloudColumnDrive,
                    textAlign: TextAlign.end,
                    style: header,
                  ),
                ),
              ],
            ),
            row(loc.cloudRowCars, '${local.cars}', '${cloud.cars}'),
            row(
              loc.cloudRowOdometer,
              '${local.odometerLogs}',
              '${cloud.odometerLogs}',
            ),
            row(loc.cloudRowFuel, '${local.fuelLogs}', '${cloud.fuelLogs}'),
            row(loc.cloudRowOther, '${other(local)}', '${other(cloud)}'),
            row(
              loc.cloudRowLastEntry,
              date(local.lastEntryDate),
              date(cloud.lastEntryDate),
            ),
          ],
        ),
        if (modified != null && sourceColumn == null) ...[
          const SizedBox(height: 8),
          Text(
            loc.cloudModifiedAt(
              DateFormat.yMMMd(languageCode).add_Hm().format(modified),
            ),
            textAlign: TextAlign.end,
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}
