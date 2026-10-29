import '../models/odometer_log.dart';
import '../models/reminder.dart';
import '../utils/date_utils.dart';

/// How urgent a reminder is, from the most to the least urgent.
enum ReminderUrgency { overdue, upcoming, scheduled, completed }

/// A mileage reminder becomes "upcoming" this many kilometres before its
/// target.
const int reminderUpcomingKm = 1000;

/// A date reminder becomes "upcoming" this many days before its due date.
const int reminderUpcomingDays = 7;

/// Whether [reminder] is counted in kilometres rather than by date.
bool isMileageReminder(Reminder reminder) =>
    reminder.type == ReminderType.maintenance ||
    (reminder.type == ReminderType.custom && reminder.repeatKm != null);

/// The car's current mileage: the highest odometer reading, 0 without any.
int currentMileage(Iterable<OdometerLog> logs) {
  var highest = 0;
  for (final log in logs) {
    if (log.odometer > highest) highest = log.odometer;
  }
  return highest;
}

class ReminderStatus {
  final ReminderUrgency urgency;

  /// Target mileage of a mileage reminder.
  final int? dueKm;

  /// Kilometres left until [dueKm]; negative when overdue.
  final int? remainingKm;

  /// Calendar days left until the due date; negative when overdue.
  final int? daysLeft;

  const ReminderStatus({
    required this.urgency,
    this.dueKm,
    this.remainingKm,
    this.daysLeft,
  });

  bool get isOverdue => urgency == ReminderUrgency.overdue;
  bool get isUpcoming => urgency == ReminderUrgency.upcoming;

  /// Position inside the urgency group: 1.0 marks the "upcoming" threshold
  /// for both kinds of reminders, so date and mileage reminders interleave.
  double get _closeness {
    final km = remainingKm;
    if (km != null) return km / reminderUpcomingKm;
    return (daysLeft ?? 0) / reminderUpcomingDays;
  }
}

ReminderStatus reminderStatus(
  Reminder reminder, {
  required int currentKm,
  required DateTime today,
}) {
  if (isMileageReminder(reminder)) {
    final dueKm = (reminder.startKm ?? 0) + (reminder.repeatKm ?? 0);
    final remaining = dueKm - currentKm;
    return ReminderStatus(
      urgency: reminder.isCompleted
          ? ReminderUrgency.completed
          : remaining <= 0
              ? ReminderUrgency.overdue
              : remaining <= reminderUpcomingKm
                  ? ReminderUrgency.upcoming
                  : ReminderUrgency.scheduled,
      dueKm: dueKm,
      remainingKm: remaining,
    );
  }

  final days = calendarDaysBetween(today, reminder.dueDate);
  return ReminderStatus(
    urgency: reminder.isCompleted
        ? ReminderUrgency.completed
        : days < 0
            ? ReminderUrgency.overdue
            : days <= reminderUpcomingDays
                ? ReminderUrgency.upcoming
                : ReminderUrgency.scheduled,
    daysLeft: days,
  );
}

/// Active reminders first, the most urgent on top; completed ones last,
/// newest first.
List<Reminder> sortRemindersByUrgency(
  Iterable<Reminder> reminders, {
  required int currentKm,
  required DateTime today,
}) {
  final entries = [
    for (final reminder in reminders)
      (
        reminder: reminder,
        status: reminderStatus(reminder, currentKm: currentKm, today: today),
      ),
  ];
  entries.sort((a, b) {
    final byUrgency = a.status.urgency.index.compareTo(b.status.urgency.index);
    if (byUrgency != 0) return byUrgency;
    if (a.status.urgency == ReminderUrgency.completed) {
      return b.reminder.dueDate.compareTo(a.reminder.dueDate);
    }
    final byCloseness = a.status._closeness.compareTo(b.status._closeness);
    if (byCloseness != 0) return byCloseness;
    return a.reminder.id.compareTo(b.reminder.id);
  });
  return [for (final entry in entries) entry.reminder];
}
