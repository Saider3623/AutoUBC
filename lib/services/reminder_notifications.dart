import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_status.dart';
import '../l10n/app_localizations.dart';
import '../models/car.dart';
import '../models/reminder.dart';
import '../utils/reminder_texts.dart';

/// Days before the due date when a date reminder notifies: a week before, the
/// day before and on the due day.
const List<int> reminderNotificationDaysBefore = [7, 1, 0];

/// Local time of day for reminder notifications.
const int reminderNotificationHour = 9;

/// Android resource of the status bar icon; kept from resource shrinking by
/// res/raw/keep.xml.
const String _notificationIcon = 'ic_notification';

/// One planned notification of a date reminder.
class PlannedNotification {
  final int id;
  final Reminder reminder;
  final DateTime when;
  final int daysBefore;

  const PlannedNotification({
    required this.id,
    required this.reminder,
    required this.when,
    required this.daysBefore,
  });
}

/// Plans the notifications of active date reminders that are still ahead of
/// [now]. Mileage reminders cannot be planned by time; the data entry screen
/// shows them instead.
List<PlannedNotification> planReminderNotifications(
  Iterable<Reminder> reminders, {
  required DateTime now,
}) {
  final planned = <PlannedNotification>[];
  for (final reminder in reminders) {
    if (reminder.isCompleted || isMileageReminder(reminder)) continue;
    final due = reminder.dueDate;
    for (final (index, daysBefore) in reminderNotificationDaysBefore.indexed) {
      // The DateTime constructor normalises day underflow and keeps 09:00
      // local time across DST changes.
      final when = DateTime(
        due.year,
        due.month,
        due.day - daysBefore,
        reminderNotificationHour,
      );
      if (!when.isAfter(now)) continue;
      planned.add(PlannedNotification(
        // Ids stay stable for a reminder, so a reschedule replaces them.
        id: reminder.id * reminderNotificationDaysBefore.length + index,
        reminder: reminder,
        when: when,
        daysBefore: daysBefore,
      ));
    }
  }
  return planned;
}

/// Schedules local notifications for insurance, inspection and other date
/// reminders of all cars. Works on Android only; elsewhere it does nothing.
class ReminderNotifications {
  ReminderNotifications._();

  static final ReminderNotifications instance = ReminderNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<bool>? _initialization;

  /// Notifications are scheduled on Android only.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> _ensureInitialized() {
    return _initialization ??= () async {
      try {
        tz_data.initializeTimeZones();
        // A scheduled instant does not depend on the zone; Kyiv only names
        // the wall-clock time passed to Android.
        try {
          tz.setLocalLocation(tz.getLocation('Europe/Kyiv'));
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
        }
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings(_notificationIcon),
          ),
        );
        return true;
      } catch (error) {
        debugPrint('[Notifications] Initialization failed: $error');
        return false;
      }
    }();
  }

  /// Whether the user allows notifications; `true` where they are not used.
  Future<bool> areEnabled() async {
    if (!isSupported || !await _ensureInitialized()) return true;
    try {
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Shows the system permission prompt (Android 13+). Returns whether
  /// notifications are allowed afterwards.
  Future<bool> requestPermission() async {
    if (!isSupported || !await _ensureInitialized()) return true;
    try {
      return await _android?.requestNotificationsPermission() ?? true;
    } catch (error) {
      debugPrint('[Notifications] Permission request failed: $error');
      return false;
    }
  }

  /// Opens the app's notification settings, for a user who declined the
  /// prompt earlier and can no longer be asked.
  Future<void> openSettings() async {
    if (!isSupported || !await _ensureInitialized()) return;
    try {
      await _plugin.openAppNotificationSettings();
    } catch (error) {
      debugPrint('[Notifications] Opening settings failed: $error');
    }
  }

  Future<void> _queue = Future<void>.value();

  /// Replaces all scheduled reminder notifications with the ones planned for
  /// [reminders]. Calls run one after another, so a quick series of edits
  /// cannot leave notifications of a stale list behind.
  Future<void> reschedule({
    required List<Reminder> reminders,
    required List<Car> cars,
    required Locale locale,
  }) {
    if (!isSupported) return Future<void>.value();
    return _queue = _queue.then((_) => _reschedule(reminders, cars, locale));
  }

  Future<void> _reschedule(
    List<Reminder> reminders,
    List<Car> cars,
    Locale locale,
  ) async {
    if (!await _ensureInitialized()) return;
    try {
      final planned = planReminderNotifications(reminders, now: DateTime.now());
      await _plugin.cancelAll();
      if (planned.isEmpty) return;

      final loc = lookupAppLocalizations(locale);
      final carNames = {for (final car in cars) car.id: car.name};
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          loc.reminders,
          channelDescription: loc.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: _notificationIcon,
        ),
      );
      final dateFormat = DateFormat.yMMMd(locale.languageCode);

      for (final item in planned) {
        final reminder = item.reminder;
        final title = reminderTitle(reminder, loc);
        final car = carNames[reminder.carId];
        final dueText = dateFormat.format(reminder.dueDate);
        final body = switch (item.daysBefore) {
          0 => loc.notificationDueToday(dueText),
          1 => loc.notificationDueTomorrow(dueText),
          _ => loc.notificationDueInWeek(dueText),
        };
        await _plugin.zonedSchedule(
          id: item.id,
          title: car == null ? title : '$title · $car',
          body: body,
          scheduledDate: tz.TZDateTime.from(item.when, tz.local),
          notificationDetails: details,
          // Inexact alarms need no special permission; a few minutes of
          // delay do not matter for a reminder days ahead.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (error) {
      debugPrint('[Notifications] Scheduling failed: $error');
    }
  }
}
