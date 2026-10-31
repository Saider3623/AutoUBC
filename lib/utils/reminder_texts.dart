import '../domain/reminder_status.dart';
import '../l10n/app_localizations.dart';
import '../models/reminder.dart';

/// Display name of [reminder]: its type, or its own title for a custom one.
String reminderTitle(Reminder reminder, AppLocalizations loc) {
  switch (reminder.type) {
    case ReminderType.insurance:
      return loc.insuranceReminder;
    case ReminderType.maintenance:
      return loc.maintenanceReminder;
    case ReminderType.inspection:
      return loc.inspectionReminder;
    case ReminderType.custom:
      final title = reminder.title?.trim();
      return title == null || title.isEmpty ? loc.customReminder : title;
  }
}

/// "12 days left", "Overdue by 300 km" and the like; `null` for a completed
/// reminder.
String? reminderTimeLeft(ReminderStatus status, AppLocalizations loc) {
  if (status.urgency == ReminderUrgency.completed) return null;
  final km = status.remainingKm;
  if (km != null) {
    return km > 0 ? loc.reminderKmLeft(km) : loc.reminderKmOverdue(-km);
  }
  final days = status.daysLeft ?? 0;
  if (days == 0) return loc.reminderDueToday;
  return days > 0 ? loc.reminderDaysLeft(days) : loc.reminderDaysOverdue(-days);
}
