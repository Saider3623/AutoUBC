import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/reminder_status.dart';
import '../l10n/app_localizations.dart';
import '../models/reminder.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/error_messages.dart';
import '../utils/form_validators.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/inline_form_error.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reminders),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.addReminder,
            onPressed: () => _showAddReminderDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.cars.isEmpty) {
            return AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: loc.addCarFirst,
            );
          }

          final currentKm = currentMileage(provider.odometerLogs);
          final sorted = sortRemindersByUrgency(
            provider.reminders,
            currentKm: currentKm,
            today: DateTime.now(),
          );
          final activeReminders = sorted.where((r) => !r.isCompleted).toList();
          final completedReminders =
              sorted.where((r) => r.isCompleted).toList();

          if (sorted.isEmpty) {
            return AppEmptyState(
              icon: Icons.notifications_none,
              title: loc.noReminders,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (activeReminders.isNotEmpty) ...[
                Text(
                  loc.active,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...activeReminders.map((reminder) => _ReminderCard(
                      reminder: reminder,
                      currentKm: currentKm,
                    )),
                const SizedBox(height: 16),
              ],
              if (completedReminders.isNotEmpty) ...[
                Text(
                  loc.completed,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...completedReminders.map((reminder) => _ReminderCard(
                      reminder: reminder,
                      currentKm: currentKm,
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.selectedCar == null) return;

    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        carId: provider.selectedCar!.id,
        onSave: (reminder) async {
          await provider.addReminder(reminder);
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final int currentKm;

  const _ReminderCard({required this.reminder, required this.currentKm});

  String _getReminderTypeName(ReminderType type, AppLocalizations loc) {
    switch (type) {
      case ReminderType.insurance:
        return loc.insuranceReminder;
      case ReminderType.maintenance:
        return loc.maintenanceReminder;
      case ReminderType.inspection:
        return loc.inspectionReminder;
      case ReminderType.custom:
        return reminder.title ?? loc.customReminder;
    }
  }

  Color _getReminderTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.insurance:
        return Colors.blue;
      case ReminderType.maintenance:
        return Colors.orange;
      case ReminderType.inspection:
        return Colors.green;
      case ReminderType.custom:
        return Colors.purple;
    }
  }

  IconData _getReminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.insurance:
        return Icons.security;
      case ReminderType.maintenance:
        return Icons.build;
      case ReminderType.inspection:
        return Icons.car_repair;
      case ReminderType.custom:
        return Icons.edit;
    }
  }

  Future<void> _complete(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.completeReminder(reminder);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(error, loc))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final status = reminderStatus(
      reminder,
      currentKm: currentKm,
      today: DateTime.now(),
    );
    final isOverdue = status.isOverdue;
    final isUpcoming = status.isUpcoming;
    final usesKm = isMileageReminder(reminder);

    final subtitleText = usesKm
        ? loc.mileage(currentKm, status.dueKm ?? 0)
        : DateFormat.yMMMd(languageCode).format(reminder.dueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getReminderTypeColor(reminder.type),
          child: Icon(
            _getReminderIcon(reminder.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          _getReminderTypeName(reminder.type, loc),
          style: TextStyle(
            decoration:
                reminder.isCompleted ? TextDecoration.lineThrough : null,
            color: isOverdue ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitleText,
              style: TextStyle(
                decoration:
                    reminder.isCompleted ? TextDecoration.lineThrough : null,
                color: isOverdue ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              usesKm
                  ? '${loc.repeatEvery} ${reminder.repeatKm} ${loc.km}'
                  : '${loc.repeatEvery} ${reminder.repeatMonths} ${loc.months}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: reminder.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _complete(context),
              ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _ReminderDialog(
              carId: reminder.carId!,
              reminder: reminder,
              onSave: (updatedReminder) async {
                await provider.updateReminder(updatedReminder);
              },
              onDelete: () async {
                await provider.deleteReminder(reminder);
              },
            ),
          );
        },
        tileColor: isOverdue
            ? Colors.red.withValues(alpha: 0.1)
            : isUpcoming
                ? Colors.yellow.withValues(alpha: 0.1)
                : null,
      ),
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  final int carId;
  final Reminder? reminder;
  final Future<void> Function(Reminder) onSave;
  final Future<void> Function()? onDelete;

  const _ReminderDialog({
    required this.carId,
    this.reminder,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _saveError;
  late ReminderType _type;
  late DateTime _dueDate;
  late bool _useKmForCustom;
  late bool _repeatMonthsEnabled;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _repeatMonthsController = TextEditingController();
  final TextEditingController _repeatKmController = TextEditingController();
  final TextEditingController _startKmController = TextEditingController();

  bool get _usesKm =>
      _type == ReminderType.maintenance ||
      (_type == ReminderType.custom && _useKmForCustom);

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final currentKm = currentMileage(provider.odometerLogs);
    if (reminder != null) {
      _type = reminder.type;
      _dueDate = reminder.dueDate;
      _titleController.text = reminder.title ?? '';
      _useKmForCustom = reminder.repeatKm != null;
      _repeatMonthsEnabled = reminder.repeatMonths > 0;
      _repeatMonthsController.text =
          _repeatMonthsEnabled ? reminder.repeatMonths.toString() : '';
      _repeatKmController.text = (reminder.repeatKm ?? 10000).toString();
      // Editing keeps the original starting mileage; it is no longer reset to
      // the current reading on every save.
      _startKmController.text = (reminder.startKm ?? currentKm).toString();
    } else {
      final now = DateTime.now();
      _type = ReminderType.insurance;
      _dueDate = DateTime(now.year, now.month, now.day + 30);
      _useKmForCustom = false;
      _repeatMonthsEnabled = false;
      _repeatKmController.text = '10000';
      _startKmController.text = currentKm > 0 ? currentKm.toString() : '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _repeatMonthsController.dispose();
    _repeatKmController.dispose();
    _startKmController.dispose();
    super.dispose();
  }

  String? _wholeNumber(String? value, AppLocalizations loc) {
    return validateWholeNumber(
      value,
      requiredMessage: loc.fieldRequired,
      invalidMessage: loc.invalidWholeNumber,
      nonNegativeMessage: loc.numberMustBeNonNegative,
    );
  }

  Future<void> _delete() async {
    final loc = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirmDelete),
        content: Text(loc.deleteReminderConfirmation),
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
    if (confirmed != true || !mounted) return;
    try {
      await widget.onDelete!();
      if (mounted) navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = describeError(error, loc));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final loc = AppLocalizations.of(context)!;

    final usesKm = _usesKm;
    // Only fields that are visible for the chosen type are read, so a value
    // typed for another type can never break the save.
    final repeatMonths = !usesKm && _repeatMonthsEnabled
        ? int.parse(_repeatMonthsController.text.trim())
        : 0;
    final repeatKm = usesKm ? int.parse(_repeatKmController.text.trim()) : null;
    final startKm =
        usesKm ? int.parse(_startKmController.text.trim()) : null;

    final reminder = Reminder()
      ..carId = widget.carId
      ..type = _type
      ..title = _type == ReminderType.custom ? _titleController.text.trim() : null
      ..dueDate = _dueDate
      ..repeatMonths = repeatMonths
      ..repeatKm = repeatKm
      ..startKm = startKm
      ..isCompleted = widget.reminder?.isCompleted ?? false;
    if (widget.reminder != null) {
      reminder.id = widget.reminder!.id;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final navigator = Navigator.of(context);
    try {
      await widget.onSave(reminder);
      if (mounted) navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = describeError(error, loc);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final currentKm = currentMileage(provider.odometerLogs);
    final usesKm = _usesKm;
    final today = DateTime.now();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Text(widget.reminder != null ? loc.edit : loc.addReminder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ReminderType>(
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: loc.reminderType,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: ReminderType.insurance,
                      child: Text(loc.insuranceReminder),
                    ),
                    DropdownMenuItem(
                      value: ReminderType.maintenance,
                      child: Text(loc.maintenanceReminder),
                    ),
                    DropdownMenuItem(
                      value: ReminderType.inspection,
                      child: Text(loc.inspectionReminder),
                    ),
                    DropdownMenuItem(
                      value: ReminderType.custom,
                      child: Text(loc.customReminder),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _type = value;
                      if (_type == ReminderType.custom) {
                        _useKmForCustom = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_type == ReminderType.custom) ...[
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: loc.reminderTitle,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<bool>(
                    initialValue: _useKmForCustom,
                    decoration: InputDecoration(
                      labelText: loc.reminderCondition,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: false,
                        child: Text(loc.byDate),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text(loc.byMileage),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _useKmForCustom = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (!usesKm) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading:
                          const Icon(Icons.calendar_today, color: Colors.grey),
                      title: Text(
                        DateFormat.yMMMd(languageCode).format(_dueDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(today.year + 10, 12, 31),
                          locale: localeProvider.locale,
                        );
                        if (picked != null) {
                          setState(() {
                            _dueDate = picked;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${loc.repeatEvery} (${loc.months})'),
                    value: _repeatMonthsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _repeatMonthsEnabled = value;
                        if (!value) _repeatMonthsController.clear();
                      });
                    },
                  ),
                  if (_repeatMonthsEnabled)
                    TextFormField(
                      controller: _repeatMonthsController,
                      keyboardType: TextInputType.number,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => _wholeNumber(value, loc),
                      decoration: InputDecoration(
                        labelText: loc.repeatEvery,
                        suffixText: loc.months,
                      ),
                    ),
                ] else ...[
                  TextFormField(
                    controller: _repeatKmController,
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => _wholeNumber(value, loc),
                    decoration: InputDecoration(
                      labelText: '${loc.repeatEvery} (${loc.km})',
                      suffixText: loc.km,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _startKmController,
                    keyboardType: TextInputType.number,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => _wholeNumber(value, loc),
                    decoration: InputDecoration(
                      labelText: loc.reminderStartKm,
                      suffixText: loc.km,
                      helperText: loc.currentMileage(currentKm),
                    ),
                  ),
                ],
                InlineFormError(message: _saveError),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: _isSaving ? null : _delete,
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
