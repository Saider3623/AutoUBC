import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/five_day_period.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/work_schedule.dart';
import 'inline_form_error.dart';

/// Settings card for the app-wide working-week schedule: six-day weeks by
/// default and a list of editable five-day periods.
class WorkScheduleCard extends StatelessWidget {
  const WorkScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context);
    final languageCode =
        Provider.of<LocaleProvider>(context).locale?.languageCode ?? 'uk';
    final periods = appProvider.fiveDayPeriods;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.workWeekSection,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              loc.workWeekScheduleHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (periods.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  loc.fiveDayPeriodsEmpty,
                  style: const TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...periods.map(
                (period) => _FiveDayPeriodTile(
                  period: period,
                  languageCode: languageCode,
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(loc.addFiveDayPeriod),
                onPressed: () => showFiveDayPeriodDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Human-readable range of [period], e.g. `01.10.2026 — 15.03.2027`.
String describeFiveDayPeriod(
  FiveDayPeriod period,
  AppLocalizations loc,
  String languageCode,
) {
  final format = DateFormat.yMd(languageCode);
  String formatDate(String value) {
    final date = parseScheduleDate(value);
    return date == null ? value : format.format(date);
  }

  final end = period.endDate;
  final endText = end == null ? loc.fiveDayPeriodOpenEnd : formatDate(end);
  return '${formatDate(period.startDate)} — $endText';
}

class _FiveDayPeriodTile extends StatelessWidget {
  final FiveDayPeriod period;
  final String languageCode;

  const _FiveDayPeriodTile({
    required this.period,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isActive =
        WorkSchedule.fromPeriods([period]).isFiveDayDate(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.line,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
        leading: Icon(
          Icons.date_range,
          color: isActive ? AppColors.primary : AppColors.muted,
        ),
        title: Text(describeFiveDayPeriod(period, loc, languageCode)),
        subtitle: isActive
            ? Text(
                loc.fiveDayPeriodActive,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: loc.delete,
          onPressed: () => _confirmDelete(context, loc),
        ),
        onTap: () => showFiveDayPeriodDialog(context, period: period),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations loc) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final description = describeFiveDayPeriod(period, loc, languageCode);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.deleteFiveDayPeriodConfirm(description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await appProvider.deleteFiveDayPeriod(period);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(loc.saveError(e.toString()))),
      );
    }
  }
}

/// Opens the dialog for adding a new five-day period or editing [period].
Future<void> showFiveDayPeriodDialog(
  BuildContext context, {
  FiveDayPeriod? period,
}) async {
  final loc = AppLocalizations.of(context)!;
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => _FiveDayPeriodDialog(period: period),
  );
  if (saved == true) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(loc.fiveDayPeriodSaved)),
    );
  }
}

class _FiveDayPeriodDialog extends StatefulWidget {
  final FiveDayPeriod? period;

  const _FiveDayPeriodDialog({this.period});

  @override
  State<_FiveDayPeriodDialog> createState() => _FiveDayPeriodDialogState();
}

class _FiveDayPeriodDialogState extends State<_FiveDayPeriodDialog> {
  late DateTime _start;
  DateTime? _end;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final period = widget.period;
    if (period != null) {
      _start = parseScheduleDate(period.startDate) ?? _today();
      final end = period.endDate;
      _end = end == null ? null : parseScheduleDate(end);
    } else {
      _start = _defaultStart();
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The five-day week usually starts on 1 October. Fall back to today when
  /// that date is already covered by another period.
  DateTime _defaultStart() {
    final today = _today();
    final october = DateTime(today.year, 10, 1);
    final periods =
        Provider.of<AppProvider>(context, listen: false).fiveDayPeriods;
    final octoberString = formatScheduleDate(october);
    final isOctoberTaken =
        findOverlappingFiveDayPeriod(periods, octoberString, octoberString) !=
            null;
    return isOctoberTaken ? today : october;
  }

  Future<void> _pickStart() async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: locale,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _start = picked;
      _error = null;
    });
  }

  Future<void> _pickEnd() async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final today = _today();
    var initial = _end ?? (today.isBefore(_start) ? _start : today);
    if (initial.isBefore(_start)) initial = _start;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _start,
      lastDate: DateTime(2100),
      locale: locale,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _end = picked;
      _error = null;
    });
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final languageCode =
        Provider.of<LocaleProvider>(context, listen: false)
                .locale
                ?.languageCode ??
            'uk';
    final navigator = Navigator.of(context);

    final startString = formatScheduleDate(_start);
    final end = _end;
    final endString = end == null ? null : formatScheduleDate(end);

    if (endString != null && endString.compareTo(startString) < 0) {
      setState(() => _error = loc.fiveDayPeriodEndBeforeStart);
      return;
    }

    final overlapping = findOverlappingFiveDayPeriod(
      appProvider.fiveDayPeriods,
      startString,
      endString,
      excludeId: widget.period?.id,
    );
    if (overlapping != null) {
      setState(() => _error = loc.fiveDayPeriodOverlap(
          describeFiveDayPeriod(overlapping, loc, languageCode)));
      return;
    }

    // Save a fresh object so a failed save never alters the in-memory list.
    final toSave = FiveDayPeriod()
      ..startDate = startString
      ..endDate = endString;
    final existing = widget.period;
    if (existing != null) toSave.id = existing.id;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await appProvider.saveFiveDayPeriod(toSave);
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = loc.saveError(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final languageCode =
        Provider.of<LocaleProvider>(context).locale?.languageCode ?? 'uk';
    final dateFormat = DateFormat.yMMMd(languageCode);
    final end = _end;

    return AlertDialog(
      title: Text(
        widget.period == null ? loc.addFiveDayPeriod : loc.editFiveDayPeriod,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DateField(
              label: loc.fiveDayPeriodStart,
              value: dateFormat.format(_start),
              onTap: _isSaving ? null : _pickStart,
            ),
            const SizedBox(height: 16),
            _DateField(
              label: loc.fiveDayPeriodEnd,
              value: end == null
                  ? loc.fiveDayPeriodEndNotSet
                  : dateFormat.format(end),
              isPlaceholder: end == null,
              onTap: _isSaving ? null : _pickEnd,
              onClear: end == null || _isSaving
                  ? null
                  : () => setState(() {
                        _end = null;
                        _error = null;
                      }),
            ),
            const SizedBox(height: 8),
            Text(
              loc.fiveDayPeriodEndHint,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            InlineFormError(message: _error),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: Text(loc.cancel),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.save),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool isPlaceholder;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    this.isPlaceholder = false,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: loc.clearDate,
                  onPressed: onClear,
                ),
        ),
        child: Text(
          value,
          style: isPlaceholder
              ? const TextStyle(color: AppColors.muted)
              : const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
