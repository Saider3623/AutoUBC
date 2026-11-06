import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/fuel_log.dart';
import '../models/odometer_log.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/fuel_colors.dart';
import '../utils/error_messages.dart';
import '../utils/form_validators.dart';
import '../utils/weekly_report_utils.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/inline_form_error.dart';
import 'weekly_report_screen.dart' show formatLiters;
import '../theme/app_theme.dart';

/// Entries of one day inside the week.
class _DayEntries {
  final List<OdometerLog> odometer = [];
  final List<FuelLog> fuel = [];
}

class WeekDetailScreen extends StatelessWidget {
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeekDetailScreen({
    super.key,
    required this.weekStart,
    required this.weekEnd,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final week = ReportWeek(weekStart, weekEnd);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            loc.weekDetailTitle(formatReportWeekRange(week, languageCode)),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.selectedCar == null) {
            return AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: loc.selectCarGeneric,
            );
          }

          // Group the week's entries by day, newest day first.
          final days = <String, _DayEntries>{};
          for (final log in provider.odometerLogs) {
            final date = DateTime.tryParse(log.dateString);
            if (date != null && week.contains(date)) {
              days
                  .putIfAbsent(log.dateString, _DayEntries.new)
                  .odometer
                  .add(log);
            }
          }
          for (final log in provider.fuelLogs) {
            final date = DateTime.tryParse(log.dateString);
            if (date != null && week.contains(date)) {
              days.putIfAbsent(log.dateString, _DayEntries.new).fuel.add(log);
            }
          }
          final dates = days.keys.toList()..sort((a, b) => b.compareTo(a));

          if (dates.isEmpty) {
            return AppEmptyState(icon: Icons.history, title: loc.noRecords);
          }

          final numbers = NumberFormat.decimalPattern(languageCode);
          final colorScheme = Theme.of(context).colorScheme;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final entries = days[date]!;
              entries.fuel.sort((a, b) => a.timeString.compareTo(b.timeString));
              final formattedDate = DateFormat('dd.MM.yy (EEEE)', languageCode)
                  .format(DateTime.parse(date));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      for (final log in entries.odometer)
                        _EntryRow(
                          icon: Icons.speed,
                          color: AppColors.muted,
                          text: '${loc.odometerLabel}: '
                              '${numbers.format(log.odometer)} ${loc.kilometers}',
                          onEdit: () => _editOdometer(context, log),
                          onDelete: () => _confirmDeleteOdometer(context, log),
                          editTooltip: loc.edit,
                          deleteTooltip: loc.delete,
                        ),
                      for (final log in entries.fuel)
                        _EntryRow(
                          icon: Icons.local_gas_station,
                          color: fuelTypeColor(log.fuelType, colorScheme),
                          text: '${log.fuelType}: ${formatLiters(log.liters)} '
                              '${loc.litersShort}',
                          trailingText: log.timeString,
                          onEdit: () => _editFuel(context, log),
                          onDelete: () => _confirmDeleteFuel(context, log),
                          editTooltip: loc.edit,
                          deleteTooltip: loc.delete,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(error, loc))),
      );
    }
  }

  Future<void> _confirmDeleteOdometer(
      BuildContext context, OdometerLog log) async {
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!await _confirm(context, loc.deleteOdometerLogConfirmation)) return;
    if (!context.mounted) return;
    await _run(context, () => provider.deleteOdometerLog(log));
  }

  Future<void> _confirmDeleteFuel(BuildContext context, FuelLog log) async {
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (!await _confirm(context, loc.deleteFuelLogConfirmation)) return;
    if (!context.mounted) return;
    await _run(context, () => provider.deleteFuelLog(log));
  }

  Future<void> _editOdometer(BuildContext context, OdometerLog log) {
    return showDialog<void>(
      context: context,
      builder: (context) => _EditOdometerDialog(log: log),
    );
  }

  Future<void> _editFuel(BuildContext context, FuelLog log) {
    return showDialog<void>(
      context: context,
      builder: (context) => _EditFuelDialog(log: log),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String? trailingText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String editTooltip;
  final String deleteTooltip;

  const _EntryRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.onEdit,
    required this.onDelete,
    required this.editTooltip,
    required this.deleteTooltip,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            IconButton(
              tooltip: editTooltip,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: deleteTooltip,
              icon: const Icon(Icons.delete_outline,
                  size: 22, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditOdometerDialog extends StatefulWidget {
  final OdometerLog log;

  const _EditOdometerDialog({required this.log});

  @override
  State<_EditOdometerDialog> createState() => _EditOdometerDialogState();
}

class _EditOdometerDialogState extends State<_EditOdometerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
      TextEditingController(text: widget.log.odometer.toString());
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await provider.saveOdometerLog(
        widget.log.dateString,
        int.parse(_controller.text.trim()),
      );
      if (mounted) navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = describeError(error, loc);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(loc.editOdometerTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              validator: (value) => validateWholeNumber(
                value,
                requiredMessage: loc.fieldRequired,
                invalidMessage: loc.invalidWholeNumber,
                nonNegativeMessage: loc.numberMustBeNonNegative,
              ),
              decoration: InputDecoration(
                labelText: loc.odometer,
                suffixText: loc.km,
              ),
            ),
            InlineFormError(message: _error),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(loc.save),
        ),
      ],
    );
  }
}

class _EditFuelDialog extends StatefulWidget {
  final FuelLog log;

  const _EditFuelDialog({required this.log});

  @override
  State<_EditFuelDialog> createState() => _EditFuelDialogState();
}

class _EditFuelDialogState extends State<_EditFuelDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _litersController =
      TextEditingController(text: formatLiters(widget.log.liters));
  late String _fuelType = widget.log.fuelType;
  late String _time = widget.log.timeString;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _litersController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 12,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    String two(int value) => value.toString().padLeft(2, '0');
    setState(() => _time = '${two(picked.hour)}:${two(picked.minute)}');
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final updated = FuelLog()
      ..id = widget.log.id
      ..carId = widget.log.carId
      ..dateString = widget.log.dateString
      ..timeString = _time
      ..fuelType = _fuelType
      ..liters =
          double.parse(normalizeDecimalInput(_litersController.text.trim()));
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await provider.updateFuelLog(updated);
      if (mounted) navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = describeError(error, loc);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final carTypes =
        Provider.of<AppProvider>(context, listen: false).selectedCar?.fuelTypes;
    final fuelTypes = {...?carTypes, widget.log.fuelType}.toList();

    return AlertDialog(
      title: Text(loc.editRefuelTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in fuelTypes)
                    ChoiceChip(
                      label: Text(type),
                      selected: type == _fuelType,
                      selectedColor: fuelTypeColor(type, colorScheme)
                          .withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _fuelType = type),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _litersController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => validateNonNegativeDecimal(
                  value,
                  requiredMessage: loc.fieldRequired,
                  invalidMessage: loc.invalidNumber,
                  nonNegativeMessage: loc.numberMustBeNonNegative,
                  positiveMessage: loc.numberMustBePositive,
                ),
                decoration: InputDecoration(
                  labelText: loc.fuel,
                  suffixText: loc.litersShort,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(loc.timeLabel),
                trailing: Text(_time, style: const TextStyle(fontSize: 16)),
                onTap: _pickTime,
              ),
              InlineFormError(message: _error),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(loc.save),
        ),
      ],
    );
  }
}
