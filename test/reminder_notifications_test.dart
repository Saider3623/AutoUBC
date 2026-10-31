import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/domain/reminder_status.dart';
import 'package:autoubc/l10n/app_localizations.dart';
import 'package:autoubc/models/reminder.dart';
import 'package:autoubc/services/reminder_notifications.dart';
import 'package:autoubc/utils/reminder_texts.dart';

Reminder _dateReminder(
  DateTime due, {
  int id = 1,
  bool completed = false,
  ReminderType type = ReminderType.insurance,
}) {
  return Reminder()
    ..id = id
    ..carId = 1
    ..type = type
    ..dueDate = due
    ..isCompleted = completed;
}

void main() {
  group('planReminderNotifications', () {
    test('plans a week before, the day before and the due day at 09:00', () {
      final planned = planReminderNotifications(
        [_dateReminder(DateTime(2026, 11, 20))],
        now: DateTime(2026, 10, 29, 12),
      );
      expect(planned.map((p) => p.when), [
        DateTime(2026, 11, 13, 9),
        DateTime(2026, 11, 19, 9),
        DateTime(2026, 11, 20, 9),
      ]);
      expect(planned.map((p) => p.daysBefore), [7, 1, 0]);
    });

    test('skips moments that have already passed', () {
      final planned = planReminderNotifications(
        [_dateReminder(DateTime(2026, 10, 30))],
        now: DateTime(2026, 10, 29, 10),
      );
      // The day-before notification (29th, 09:00) is already in the past.
      expect(planned.map((p) => p.when), [DateTime(2026, 10, 30, 9)]);
    });

    test('a week before crosses month boundaries and the DST change', () {
      // 2026-10-25 is the autumn DST change in Kyiv.
      final planned = planReminderNotifications(
        [_dateReminder(DateTime(2026, 11, 1))],
        now: DateTime(2026, 10, 1),
      );
      expect(planned.first.when, DateTime(2026, 10, 25, 9));
      expect(planned.first.when.hour, 9);
    });

    test('ignores completed and mileage reminders', () {
      final mileage = Reminder()
        ..id = 2
        ..carId = 1
        ..type = ReminderType.maintenance
        ..startKm = 100000
        ..repeatKm = 10000
        ..dueDate = DateTime(2026, 11, 20);
      final planned = planReminderNotifications(
        [
          _dateReminder(DateTime(2026, 11, 20), completed: true),
          mileage,
        ],
        now: DateTime(2026, 10, 29),
      );
      expect(planned, isEmpty);
    });

    test('ids are stable per reminder and never collide', () {
      final planned = planReminderNotifications(
        [
          _dateReminder(DateTime(2026, 12, 1), id: 1),
          _dateReminder(DateTime(2026, 12, 1), id: 2),
        ],
        now: DateTime(2026, 10, 29),
      );
      final ids = planned.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      final again = planReminderNotifications(
        [_dateReminder(DateTime(2026, 12, 1), id: 2)],
        now: DateTime(2026, 10, 29),
      );
      expect(again.map((p) => p.id), ids.sublist(3));
    });
  });

  group('reminderTimeLeft', () {
    final loc = lookupAppLocalizations(const Locale('en'));

    test('describes days left, today and overdue days', () {
      expect(
        reminderTimeLeft(
          const ReminderStatus(
              urgency: ReminderUrgency.scheduled, daysLeft: 12),
          loc,
        ),
        'Days left: 12',
      );
      expect(
        reminderTimeLeft(
          const ReminderStatus(urgency: ReminderUrgency.upcoming, daysLeft: 0),
          loc,
        ),
        'Due today',
      );
      expect(
        reminderTimeLeft(
          const ReminderStatus(urgency: ReminderUrgency.overdue, daysLeft: -3),
          loc,
        ),
        'Days overdue: 3',
      );
    });

    test('describes kilometres left and overdue kilometres', () {
      expect(
        reminderTimeLeft(
          const ReminderStatus(
              urgency: ReminderUrgency.upcoming, remainingKm: 450),
          loc,
        ),
        '450 km left',
      );
      expect(
        reminderTimeLeft(
          const ReminderStatus(
              urgency: ReminderUrgency.overdue, remainingKm: -120),
          loc,
        ),
        'Overdue by 120 km',
      );
    });

    test('says nothing for a completed reminder', () {
      expect(
        reminderTimeLeft(
          const ReminderStatus(urgency: ReminderUrgency.completed, daysLeft: 5),
          loc,
        ),
        isNull,
      );
    });

    test('a custom reminder without a title uses the type name', () {
      final reminder = _dateReminder(DateTime(2026, 11, 1),
          type: ReminderType.custom)
        ..title = '  ';
      expect(reminderTitle(reminder, loc), loc.customReminder);
    });
  });
}
