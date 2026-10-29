import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/domain/reminder_status.dart';
import 'package:autoubc/models/odometer_log.dart';
import 'package:autoubc/models/reminder.dart';

Reminder _dateReminder(DateTime due, {bool completed = false, int id = 1}) {
  return Reminder()
    ..id = id
    ..type = ReminderType.insurance
    ..dueDate = due
    ..isCompleted = completed;
}

Reminder _mileageReminder({
  required int startKm,
  required int repeatKm,
  int id = 1,
}) {
  return Reminder()
    ..id = id
    ..type = ReminderType.maintenance
    ..startKm = startKm
    ..repeatKm = repeatKm;
}

void main() {
  final today = DateTime(2026, 10, 29);

  group('date reminders', () {
    test('a reminder due today is upcoming, not overdue', () {
      final status = reminderStatus(
        _dateReminder(DateTime(2026, 10, 29)),
        currentKm: 0,
        today: today,
      );
      expect(status.urgency, ReminderUrgency.upcoming);
      expect(status.daysLeft, 0);
    });

    test('becomes overdue the day after the due date', () {
      final status = reminderStatus(
        _dateReminder(DateTime(2026, 10, 28)),
        currentKm: 0,
        today: today,
      );
      expect(status.urgency, ReminderUrgency.overdue);
      expect(status.daysLeft, -1);
    });

    test('counts calendar days across the DST change', () {
      final status = reminderStatus(
        _dateReminder(DateTime(2026, 10, 26)),
        currentKm: 0,
        today: DateTime(2026, 10, 24),
      );
      expect(status.daysLeft, 2);
    });

    test('is scheduled more than seven days ahead', () {
      final status = reminderStatus(
        _dateReminder(DateTime(2026, 11, 6)),
        currentKm: 0,
        today: today,
      );
      expect(status.urgency, ReminderUrgency.scheduled);
    });
  });

  group('mileage reminders', () {
    test('turns upcoming 1000 km before the target and overdue at it', () {
      final reminder = _mileageReminder(startKm: 150000, repeatKm: 10000);
      ReminderUrgency at(int km) =>
          reminderStatus(reminder, currentKm: km, today: today).urgency;
      expect(at(158999), ReminderUrgency.scheduled);
      expect(at(159000), ReminderUrgency.upcoming);
      expect(at(160000), ReminderUrgency.overdue);
    });
  });

  test('current mileage is the highest reading, 0 without readings', () {
    OdometerLog log(int km) => OdometerLog()
      ..odometer = km
      ..dateString = '2026-10-01';
    expect(currentMileage([log(120), log(150), log(130)]), 150);
    expect(currentMileage(const []), 0);
  });

  test('sorts the most urgent active reminders first', () {
    final overdueByDate = _dateReminder(DateTime(2026, 10, 20), id: 1);
    final dueSoon = _dateReminder(DateTime(2026, 10, 31), id: 2);
    final farAway = _dateReminder(DateTime(2027, 3, 1), id: 3);
    final overdueByKm = _mileageReminder(startKm: 100000, repeatKm: 10000, id: 4);
    final done = _dateReminder(DateTime(2026, 9, 1), completed: true, id: 5);

    final sorted = sortRemindersByUrgency(
      [farAway, done, dueSoon, overdueByKm, overdueByDate],
      currentKm: 125000,
      today: today,
    );

    expect(sorted.map((r) => r.id), [4, 1, 2, 3, 5]);
  });
}
