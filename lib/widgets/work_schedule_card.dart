import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/work_schedule.dart';

/// Settings card for the app-wide working-week schedule: six-day weeks by
/// default and one five-day period with a start date and an optional end date.
/// Every change is saved immediately.
class WorkScheduleCard extends StatefulWidget {
  const WorkScheduleCard({super.key});

  @override
  State<WorkScheduleCard> createState() => _WorkScheduleCardState();
}

class _WorkScheduleCardState extends State<WorkScheduleCard> {
  bool _isSaving = false;

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _save(DateTime? start, DateTime? end) async {
    final loc = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);
    try {
      await appProvider.setFiveDayPeriod(
        start == null ? null : formatScheduleDate(start),
        start == null || end == null ? null : formatScheduleDate(end),
      );
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(loc.fiveDayPeriodSaved)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(loc.saveError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickStart(DateTime? start, DateTime? end) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    // The five-day week usually starts on 1 October.
    var initial = start ?? DateTime(_today().year, 10, 1);
    if (end != null && initial.isAfter(end)) initial = end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: end ?? DateTime(2100),
      locale: locale,
    );
    if (picked == null || !mounted || picked == start) return;
    await _save(picked, end);
  }

  Future<void> _pickEnd(DateTime start, DateTime? end) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final today = _today();
    final initial = end ?? (today.isBefore(start) ? start : today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: start,
      lastDate: DateTime(2100),
      locale: locale,
    );
    if (picked == null || !mounted || picked == end) return;
    await _save(start, picked);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context);
    final languageCode =
        Provider.of<LocaleProvider>(context).locale?.languageCode ?? 'uk';
    final dateFormat = DateFormat.yMd(languageCode);

    final period = appProvider.fiveDayPeriod;
    final start = period == null ? null : parseScheduleDate(period.startDate);
    final endString = period?.endDate;
    final end = endString == null ? null : parseScheduleDate(endString);

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
            const SizedBox(height: 16),
            _DateField(
              label: loc.fiveDayPeriodStart,
              value: start == null
                  ? loc.fiveDayPeriodStartNotSet
                  : dateFormat.format(start),
              isPlaceholder: start == null,
              onTap: _isSaving ? null : () => _pickStart(start, end),
              // Clearing the start removes the five-day period entirely.
              onClear: start == null || _isSaving
                  ? null
                  : () => _save(null, null),
            ),
            if (start != null) ...[
              const SizedBox(height: 16),
              _DateField(
                label: loc.fiveDayPeriodEnd,
                value: end == null
                    ? loc.fiveDayPeriodOpenEnd
                    : dateFormat.format(end),
                isPlaceholder: end == null,
                onTap: _isSaving ? null : () => _pickEnd(start, end),
                onClear: end == null || _isSaving
                    ? null
                    : () => _save(start, null),
              ),
              const SizedBox(height: 8),
              Text(
                loc.fiveDayPeriodEndHint,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
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
