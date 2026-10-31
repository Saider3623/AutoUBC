import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/db/database_service.dart';
import 'package:autoubc/models/car.dart';
import 'package:autoubc/models/odometer_log.dart';
import 'package:autoubc/models/reminder.dart';
import 'package:autoubc/utils/validation.dart';

import 'support/test_database.dart';

void main() {
  final database = DatabaseService();
  Directory? root;

  setUpAll(() async => root = await useTemporaryDatabase());
  tearDownAll(() => disposeTemporaryDatabase(root));
  setUp(() async {
    if (root != null) await clearDatabase();
  });

  bool unavailable() {
    if (root != null) return false;
    markTestSkipped('Isar native library is unavailable in this test runner.');
    return true;
  }

  Future<Car> addCar(String name, {List<String> fuel = const ['ГАЗ', '95']}) {
    return database.addCar(Car()
      ..name = name
      ..fuelTypes = [...fuel]);
  }

  Matcher validation(ValidationCode code, {int? reading, String? date}) {
    var matcher = isA<DataValidationException>()
        .having((e) => e.code, 'code', code);
    if (reading != null) {
      matcher = matcher.having((e) => e.reading, 'reading', reading);
    }
    if (date != null) {
      matcher = matcher.having((e) => e.readingDate, 'readingDate', date);
    }
    return throwsA(matcher);
  }

  group('saveOdometerLog', () {
    test('keeps readings monotonic around the neighbouring dates', () async {
      if (unavailable()) return;
      final car = await addCar('Monotonic');
      await database.saveOdometerLog(car.id, '2026-10-05', 100000);
      await database.saveOdometerLog(car.id, '2026-10-07', 100400);

      await expectLater(
        database.saveOdometerLog(car.id, '2026-10-06', 99999),
        validation(ValidationCode.odometerBelowPrevious,
            reading: 100000, date: '2026-10-05'),
      );
      await expectLater(
        database.saveOdometerLog(car.id, '2026-10-06', 100401),
        validation(ValidationCode.odometerAboveNext,
            reading: 100400, date: '2026-10-07'),
      );

      await database.saveOdometerLog(car.id, '2026-10-06', 100200);
      final logs = await database.getOdometerLogsForCar(car.id);
      expect(logs.map((log) => log.odometer), [100400, 100200, 100000]);
    });

    test('a second reading for the same date replaces the first', () async {
      if (unavailable()) return;
      final car = await addCar('Upsert');
      await database.saveOdometerLog(car.id, '2026-10-05', 100000);
      await database.saveOdometerLog(car.id, '2026-10-05', 100050);

      final logs = await database.getOdometerLogsForCar(car.id);
      expect(logs, hasLength(1));
      expect(logs.single.odometer, 100050);
    });

    test('readings of another car do not count as neighbours', () async {
      if (unavailable()) return;
      final first = await addCar('First');
      final second = await addCar('Second');
      await database.saveOdometerLog(first.id, '2026-10-05', 200000);

      await database.saveOdometerLog(second.id, '2026-10-06', 1000);
      expect(await database.getOdometerLogsForCar(second.id), hasLength(1));
    });

    test('rejects a malformed date and an unknown car', () async {
      if (unavailable()) return;
      final car = await addCar('Validation');
      await expectLater(
        database.saveOdometerLog(car.id, '2026-13-01', 1),
        validation(ValidationCode.invalidDate),
      );
      await expectLater(
        database.saveOdometerLog(car.id + 1000, '2026-10-01', 1),
        validation(ValidationCode.carMissing),
      );
    });
  });

  group('updateCarWithFuelRenames', () {
    test('moves the refuels of this car to the new fuel name', () async {
      if (unavailable()) return;
      final car = await addCar('Rename', fuel: ['95', 'ГАЗ']);
      final other = await addCar('Other', fuel: ['95']);
      await database.addFuelLog(car.id, '2026-10-05', '08:00', '95', 40);
      await database.addFuelLog(car.id, '2026-10-06', '08:00', 'ГАЗ', 30);
      await database.addFuelLog(other.id, '2026-10-05', '09:00', '95', 20);

      car.fuelTypes = ['А-95', 'ГАЗ'];
      await database.updateCarWithFuelRenames(car, {'95': 'А-95'});

      final logs = await database.getFuelLogsForCar(car.id);
      expect(logs.map((log) => log.fuelType).toSet(), {'А-95', 'ГАЗ'});
      final otherLogs = await database.getFuelLogsForCar(other.id);
      expect(otherLogs.single.fuelType, '95');
      final saved = (await database.getAllCars())
          .firstWhere((candidate) => candidate.id == car.id);
      expect(saved.fuelTypes, ['А-95', 'ГАЗ']);
    });

    test('trims the registration plate and the driver', () async {
      if (unavailable()) return;
      final car = await addCar('Plate');
      car
        ..plateNumber = '  АА 1234 ВВ '
        ..driverName = '   ';
      await database.updateCarWithFuelRenames(car, const {});

      final saved = (await database.getAllCars()).single;
      expect(saved.plateNumber, 'АА 1234 ВВ');
      expect(saved.driverName, isNull);
    });
  });

  group('completeReminder', () {
    Future<Reminder> addReminder(Car car, void Function(Reminder) setup) async {
      final reminder = Reminder()
        ..carId = car.id
        ..type = ReminderType.insurance
        ..dueDate = DateTime(2026, 1, 31)
        ..repeatMonths = 0;
      setup(reminder);
      await database.addReminder(reminder);
      return reminder;
    }

    test('a monthly reminder moves to the clamped next month', () async {
      if (unavailable()) return;
      final car = await addCar('Monthly');
      final reminder = await addReminder(car, (r) => r.repeatMonths = 1);

      final nextId = await database.completeReminder(reminder);

      final reminders = await database.getRemindersForCar(car.id);
      final next = reminders.firstWhere((r) => r.id == nextId);
      expect(next.dueDate, DateTime(2026, 2, 28));
      expect(next.isCompleted, isFalse);
      expect(reminders.firstWhere((r) => r.id == reminder.id).isCompleted,
          isTrue);
    });

    test('a mileage reminder restarts from the latest reading', () async {
      if (unavailable()) return;
      final car = await addCar('Mileage');
      await database.saveOdometerLog(car.id, '2026-10-01', 150000);
      await database.saveOdometerLog(car.id, '2026-10-20', 151200);
      final reminder = await addReminder(car, (r) {
        r
          ..type = ReminderType.maintenance
          ..startKm = 140000
          ..repeatKm = 10000;
      });

      final nextId = await database.completeReminder(reminder);

      final next = (await database.getRemindersForCar(car.id))
          .firstWhere((r) => r.id == nextId);
      expect(next.startKm, 151200);
      expect(next.repeatKm, 10000);
    });

    test('a one-off reminder is only marked done', () async {
      if (unavailable()) return;
      final car = await addCar('One-off');
      final reminder = await addReminder(car, (_) {});

      expect(await database.completeReminder(reminder), isNull);
      final reminders = await database.getRemindersForCar(car.id);
      expect(reminders, hasLength(1));
      expect(reminders.single.isCompleted, isTrue);
    });

    test('undo removes the next occurrence and reactivates', () async {
      if (unavailable()) return;
      final car = await addCar('Undo');
      final reminder = await addReminder(car, (r) => r.repeatMonths = 12);

      final nextId = await database.completeReminder(reminder);
      await database.undoCompleteReminder(reminder, nextId);

      final reminders = await database.getRemindersForCar(car.id);
      expect(reminders, hasLength(1));
      expect(reminders.single.id, reminder.id);
      expect(reminders.single.isCompleted, isFalse);
    });
  });

  group('snapshots and restore', () {
    test('a snapshot summarizes like the live database', () async {
      if (unavailable()) return;
      final car = await addCar('Snapshot');
      await database.saveOdometerLog(car.id, '2026-10-05', 1000);
      await database.addFuelLog(car.id, '2026-10-06', '08:00', 'ГАЗ', 30);

      final snapshot = await database.createDatabaseSnapshot();
      final live = await database.summarizeLocal();
      final copy = await database.summarizeSnapshot(snapshot);

      expect(copy, isNotNull);
      expect(copy!.sameContentAs(live), isTrue);
      expect(live.lastEntryDate, '2026-10-06');
    });

    test('restoring a snapshot keeps the replaced data as a backup', () async {
      if (unavailable()) return;
      final car = await addCar('Restore');
      await database.saveOdometerLog(car.id, '2026-10-05', 1000);
      final snapshot = await database.createDatabaseSnapshot();
      await database.saveOdometerLog(car.id, '2026-10-06', 1100);

      final messages = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        messages.add(message ?? '');
        originalDebugPrint(message, wrapWidth: wrapWidth);
      };
      try {
        await database.replaceWithSnapshot(snapshot);
      } finally {
        debugPrint = originalDebugPrint;
      }
      // Reopening after the replacement runs the compatibility repair.
      expect(messages.where((m) => m.contains('repair skipped')), isEmpty);

      final summary = await database.summarizeLocal();
      expect(summary.odometerLogs, 1);
      expect(summary.lastEntryDate, '2026-10-05');
      final backups = await database.listLocalBackups();
      expect(backups.map((backup) => backup.tag), contains('before-restore'));
    });
  });

  group('compatibility repair', () {
    test('reopening moves a legacy car link into carId', () async {
      if (unavailable()) return;
      final car = await addCar('Legacy');
      final db = await database.isar;
      // Records of old backups point at the car only through the link.
      final log = OdometerLog()
        ..dateString = '2026-01-01'
        ..odometer = 5;
      log.car.value = car;
      await db.writeTxn(() async {
        await db.odometerLogs.put(log);
        await log.car.save();
      });
      expect(await database.getOdometerLogsForCar(car.id), isEmpty);

      await database.close();
      await database.reopen();

      final logs = await database.getOdometerLogsForCar(car.id);
      expect(logs.single.odometer, 5);
    });
  });
}
