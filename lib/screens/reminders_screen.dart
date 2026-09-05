import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reminder.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';

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
            onPressed: () => _showAddReminderDialog(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.cars.isEmpty) {
            return Center(
              child: Text(loc.addCarFirst),
            );
          }

          final activeReminders =
              provider.reminders.where((r) => !r.isCompleted).toList();
          final completedReminders =
              provider.reminders.where((r) => r.isCompleted).toList();

          if (activeReminders.isEmpty && completedReminders.isEmpty) {
            return Center(
              child: Text(loc.noReminders),
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
        onSave: (reminder) {
          provider.addReminder(reminder);
        },
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const _ReminderCard({required this.reminder});

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final now = DateTime.now();
    bool isUpcoming = false;
    bool isOverdue = false;

    // Build the subtitle according to the reminder type.
    String subtitleText = '';
    if (reminder.type == ReminderType.maintenance ||
        (reminder.type == ReminderType.custom && reminder.repeatKm != null)) {
      final odometerLogs = provider.odometerLogs;
      final currentKm =
          odometerLogs.isNotEmpty ? odometerLogs.first.odometer : 0;
      final dueKm = (reminder.startKm ?? 0) + (reminder.repeatKm ?? 0);
      subtitleText = loc.mileage(currentKm, dueKm);
      // Check overdue and upcoming states (when less than 1000 km remain).
      isUpcoming = currentKm >= dueKm - 1000 &&
          currentKm < dueKm &&
          !reminder.isCompleted;
      isOverdue = currentKm >= dueKm && !reminder.isCompleted;
    } else {
      isUpcoming =
          reminder.dueDate.isBefore(now.add(const Duration(days: 7))) &&
              !reminder.isCompleted;
      isOverdue = reminder.dueDate.isBefore(now) && !reminder.isCompleted;
      subtitleText = DateFormat.yMMMd(languageCode).format(reminder.dueDate);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
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
              (reminder.type == ReminderType.maintenance ||
                      (reminder.type == ReminderType.custom &&
                          reminder.repeatKm != null))
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
                onPressed: () {
                  provider.completeReminder(reminder);
                },
              ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _ReminderDialog(
              carId: reminder.carId!,
              reminder: reminder,
              onSave: (updatedReminder) {
                provider.updateReminder(updatedReminder);
              },
              onDelete: () {
                provider.deleteReminder(reminder);
              },
            ),
          );
        },
        tileColor: isUpcoming && !isOverdue
            ? Colors.yellow.withValues(alpha: 0.1)
            : isOverdue
                ? Colors.red.withValues(alpha: 0.1)
                : null,
      ),
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  final int carId;
  final Reminder? reminder;
  final Function(Reminder) onSave;
  final Function()? onDelete;

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
  late ReminderType _type;
  late DateTime _dueDate;
  late int _repeatMonths;
  late int _repeatKm;
  late bool _useKmForCustom;
  late bool _repeatMonthsEnabled;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _repeatMonthsController = TextEditingController();
  final TextEditingController _repeatKmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _type = widget.reminder!.type;
      _dueDate = widget.reminder!.dueDate;
      _repeatMonths = widget.reminder!.repeatMonths;
      _repeatKm = widget.reminder!.repeatKm ?? 10000;
      _titleController.text = widget.reminder!.title ?? '';
      _useKmForCustom = widget.reminder!.repeatKm != null;
      _repeatMonthsEnabled = _repeatMonths > 0;
      _repeatMonthsController.text =
          _repeatMonthsEnabled ? _repeatMonths.toString() : '';
      _repeatKmController.text = _repeatKm.toString();
    } else {
      _type = ReminderType.insurance;
      _dueDate = DateTime.now().add(const Duration(days: 30));
      _repeatMonths = 0;
      _repeatKm = 10000;
      _useKmForCustom = false;
      _repeatMonthsEnabled = false;
      _titleController.text = '';
      _repeatMonthsController.text = '';
      _repeatKmController.text = '10000';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final currentKm = provider.odometerLogs.isNotEmpty
        ? provider.odometerLogs.first.odometer
        : 0;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(widget.reminder != null ? loc.edit : loc.addReminder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ReminderType>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: 'Тип',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  setState(() {
                    _type = value!;
                    if (_type == ReminderType.custom) {
                      _useKmForCustom = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_type == ReminderType.custom) ...[
                TextField(
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
                      _useKmForCustom = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_type != ReminderType.maintenance &&
                  !(_type == ReminderType.custom && _useKmForCustom))
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
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 10)),
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
              if (_type != ReminderType.maintenance &&
                  !(_type == ReminderType.custom && _useKmForCustom))
                const SizedBox(height: 16),
              if (_type != ReminderType.maintenance &&
                  !(_type == ReminderType.custom && _useKmForCustom))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${loc.repeatEvery} (${loc.months})'),
                      value: _repeatMonthsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _repeatMonthsEnabled = value;
                          if (!_repeatMonthsEnabled) {
                            _repeatMonths = 0;
                            _repeatMonthsController.clear();
                          }
                        });
                      },
                    ),
                    if (_repeatMonthsEnabled)
                      TextField(
                        controller: _repeatMonthsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: loc.repeatEvery,
                          suffixText: loc.months,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (value) {
                          _repeatMonths = int.tryParse(value) ?? _repeatMonths;
                        },
                      ),
                  ],
                ),
              if (_type == ReminderType.maintenance ||
                  (_type == ReminderType.custom && _useKmForCustom))
                TextField(
                  controller: _repeatKmController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${loc.repeatEvery} (${loc.km})',
                    hintText: '${loc.currentMileage}: $currentKm ${loc.km}',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    _repeatKm = int.tryParse(value) ?? _repeatKm;
                  },
                ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: () {
              widget.onDelete!();
              Navigator.pop(context);
            },
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final parsedRepeatMonths =
                int.tryParse(_repeatMonthsController.text);
            final repeatMonths =
                _repeatMonthsEnabled ? (parsedRepeatMonths ?? 0) : 0;
            final reminder = Reminder()
              ..carId = widget.carId
              ..type = _type
              ..title =
                  _type == ReminderType.custom ? _titleController.text : null
              ..dueDate = _dueDate
              ..repeatMonths = repeatMonths
              ..repeatKm = (_type == ReminderType.maintenance ||
                      (_type == ReminderType.custom && _useKmForCustom))
                  ? _repeatKm
                  : null
              ..startKm = (_type == ReminderType.maintenance ||
                      (_type == ReminderType.custom && _useKmForCustom))
                  ? currentKm
                  : null
              ..isCompleted = widget.reminder?.isCompleted ?? false;
            if (widget.reminder != null) {
              reminder.id = widget.reminder!.id;
            }
            widget.onSave(reminder);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(loc.save),
        ),
      ],
    );
  }
}
