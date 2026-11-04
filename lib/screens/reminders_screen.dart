import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/reminder_status.dart';
import '../l10n/app_localizations.dart';
import '../models/reminder.dart';
import '../providers/app_provider.dart';
import '../providers/locale_provider.dart';
import '../services/reminder_notifications.dart';
import '../utils/error_messages.dart';
import '../utils/form_validators.dart';
import '../utils/reminder_texts.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/inline_form_error.dart';
import 'service_book_screen.dart';
import '../theme/app_theme.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  late Future<bool> _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationsEnabled = ReminderNotifications.instance.areEnabled();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may come back from the system notification settings.
    if (state == AppLifecycleState.resumed) _refreshNotificationState();
  }

  void _refreshNotificationState() {
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = ReminderNotifications.instance.areEnabled();
    });
  }

  Future<void> _enableNotifications() async {
    final notifications = ReminderNotifications.instance;
    // Android shows the prompt only until the user declines it twice; after
    // that the app settings are the only way.
    if (!await notifications.requestPermission()) {
      await notifications.openSettings();
    }
    _refreshNotificationState();
  }

  /// Asks for the notification permission when a date reminder is saved:
  /// that is the moment the user expects to be notified.
  Future<void> _afterSave(Reminder reminder) async {
    if (isMileageReminder(reminder) || reminder.isCompleted) return;
    await ReminderNotifications.instance.requestPermission();
    _refreshNotificationState();
  }

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
            onPressed: _showAddReminderDialog,
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
          final today = DateTime.now();
          final sorted = sortRemindersByUrgency(
            provider.reminders,
            currentKm: currentKm,
            today: today,
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

          final hasDateReminders =
              activeReminders.any((r) => !isMileageReminder(r));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (hasDateReminders)
                FutureBuilder<bool>(
                  future: _notificationsEnabled,
                  builder: (context, snapshot) {
                    if (snapshot.data != false) return const SizedBox.shrink();
                    return _NotificationsOffCard(
                      onEnable: _enableNotifications,
                    );
                  },
                ),
              if (activeReminders.isNotEmpty) ...[
                Text(
                  loc.active,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (final reminder in activeReminders)
                  _ReminderCard(
                    key: ValueKey(reminder.id),
                    reminder: reminder,
                    status: reminderStatus(
                      reminder,
                      currentKm: currentKm,
                      today: today,
                    ),
                    currentKm: currentKm,
                    onComplete: () => _complete(reminder),
                    onEdit: () => _showEditReminderDialog(reminder),
                  ),
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
                for (final reminder in completedReminders)
                  _ReminderCard(
                    key: ValueKey(reminder.id),
                    reminder: reminder,
                    status: reminderStatus(
                      reminder,
                      currentKm: currentKm,
                      today: today,
                    ),
                    currentKm: currentKm,
                    onEdit: () => _showEditReminderDialog(reminder),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddReminderDialog() {
    final provider = context.read<AppProvider>();
    final car = provider.selectedCar;
    if (car == null) return;

    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        carId: car.id,
        onSave: (reminder) async {
          await provider.addReminder(reminder);
          await _afterSave(reminder);
        },
      ),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (context) => _ReminderDialog(
        carId: reminder.carId!,
        reminder: reminder,
        onSave: (updatedReminder) async {
          await provider.updateReminder(updatedReminder);
          await _afterSave(updatedReminder);
        },
        onDelete: () async {
          await provider.deleteReminder(reminder);
          _offerUndoDelete(reminder);
        },
      ),
    );
  }

  void _offerUndoDelete(Reminder reminder) {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(loc.reminderDeletedMessage(reminderTitle(reminder, loc))),
      duration: const Duration(seconds: 6),
      persist: false,
      action: SnackBarAction(
        label: loc.undo,
        onPressed: () async {
          try {
            await provider.restoreReminder(reminder);
          } catch (error) {
            messenger.showSnackBar(
              SnackBar(content: Text(describeError(error, loc))),
            );
          }
        },
      ),
    ));
  }

  /// Marks [reminder] done. A finished maintenance is offered for the service
  /// book; then a snackbar lets the user undo the completion.
  Future<void> _complete(Reminder reminder) async {
    final provider = context.read<AppProvider>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final title = reminderTitle(reminder, loc);

    int? nextId;
    try {
      nextId = await provider.completeReminder(reminder);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(error, loc))),
      );
      return;
    }

    if (reminder.type == ReminderType.maintenance && mounted) {
      await _offerServiceBookEntry(reminder, title);
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(loc.reminderCompletedMessage(title)),
      duration: const Duration(seconds: 6),
      // A snackbar with an action would otherwise stay until dismissed.
      persist: false,
      action: SnackBarAction(
        label: loc.undo,
        onPressed: () async {
          try {
            await provider.undoCompleteReminder(reminder, nextId);
          } catch (error) {
            messenger.showSnackBar(
              SnackBar(content: Text(describeError(error, loc))),
            );
          }
        },
      ),
    ));
  }

  Future<void> _offerServiceBookEntry(Reminder reminder, String title) async {
    final loc = AppLocalizations.of(context)!;
    final add = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.menu_book_outlined),
        title: Text(loc.serviceBookOfferTitle),
        content: Text(loc.serviceBookOfferBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.addRecord),
          ),
        ],
      ),
    );
    if (add != true || !mounted) return;
    final provider = context.read<AppProvider>();
    final carId = reminder.carId ?? provider.selectedCar?.id;
    if (carId == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => ServiceLogDialog(
        carId: carId,
        initialDescription: title,
        onSave: provider.addServiceLog,
      ),
    );
  }
}

class _NotificationsOffCard extends StatelessWidget {
  final VoidCallback onEnable;

  const _NotificationsOffCard({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            Icon(Icons.notifications_off_outlined,
                color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(child: Text(loc.notificationsDisabledHint)),
            TextButton(
              onPressed: onEnable,
              child: Text(loc.enableNotifications),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final ReminderStatus status;
  final int currentKm;
  final VoidCallback? onComplete;
  final VoidCallback onEdit;

  const _ReminderCard({
    super.key,
    required this.reminder,
    required this.status,
    required this.currentKm,
    required this.onEdit,
    this.onComplete,
  });

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
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final languageCode = localeProvider.locale?.languageCode ?? 'uk';
    final isOverdue = status.isOverdue;
    final isUpcoming = status.isUpcoming;
    final usesKm = isMileageReminder(reminder);
    final timeLeft = reminderTimeLeft(status, loc);

    final subtitleText = usesKm
        ? loc.mileage(currentKm, status.dueKm ?? 0)
        : DateFormat('dd.MM.yy', languageCode).format(reminder.dueDate);
    final repeats =
        usesKm ? (reminder.repeatKm ?? 0) > 0 : reminder.repeatMonths > 0;
    final decoration = reminder.isCompleted ? TextDecoration.lineThrough : null;

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
          reminderTitle(reminder, loc),
          style: TextStyle(
            decoration: decoration,
            color: isOverdue ? AppColors.error : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitleText,
              style: TextStyle(
                decoration: decoration,
                color: isOverdue ? AppColors.error : null,
              ),
            ),
            if (timeLeft != null)
              Text(
                timeLeft,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isOverdue
                      ? AppColors.error
                      : isUpcoming
                          ? AppColors.warning
                          : null,
                ),
              ),
            if (repeats) ...[
              const SizedBox(height: 4),
              Text(
                usesKm
                    ? '${loc.repeatEvery} ${reminder.repeatKm} ${loc.km}'
                    : '${loc.repeatEvery} ${reminder.repeatMonths} ${loc.months}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ],
        ),
        trailing: reminder.isCompleted
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: loc.completed,
                onPressed: onComplete,
              ),
        onTap: onEdit,
        tileColor: isOverdue
            ? AppColors.error.withValues(alpha: 0.1)
            : isUpcoming
                ? AppColors.warning.withValues(alpha: 0.1)
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

  /// Deletes without a confirmation: the reminders screen offers "Undo".
  Future<void> _delete() async {
    final loc = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
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
    final startKm = usesKm ? int.parse(_startKmController.text.trim()) : null;

    final reminder = Reminder()
      ..carId = widget.carId
      ..type = _type
      ..title =
          _type == ReminderType.custom ? _titleController.text.trim() : null
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
                      border: Border.all(color: AppColors.line, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today,
                          color: AppColors.muted),
                      title: Text(
                        DateFormat('d MMMM yyyy', languageCode)
                            .format(_dueDate),
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
            child: Text(loc.delete,
                style: const TextStyle(color: AppColors.error)),
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
