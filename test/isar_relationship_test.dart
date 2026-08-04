import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:autoubc/models/car.dart';
import 'package:autoubc/models/fuel_log.dart';
import 'package:autoubc/models/note.dart';
import 'package:autoubc/models/odometer_log.dart';
import 'package:autoubc/models/reminder.dart';
import 'package:autoubc/models/service_log.dart';

void main() {
  late Directory directory;
  Isar? db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('autoubc_isar_test_');
    try {
      db = await Isar.open(
        [
          CarSchema,
          OdometerLogSchema,
          FuelLogSchema,
          ReminderSchema,
          ServiceLogSchema,
          NoteSchema,
        ],
        directory: directory.path,
        name: 'contract',
      );
    } on ArgumentError {
      // `flutter test` on Windows does not load the plugin DLL. This test is
      // still executed in Flutter integration/device test environments.
      db = null;
    }
  });

  tearDown(() async {
    await db?.close(deleteFromDisk: true);
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('child records are queryable by canonical carId', () async {
    if (db == null) {
      markTestSkipped(
          'Isar native library is unavailable in this test runner.');
      return;
    }
    final isar = db!;
    final car = Car()
      ..name = 'Test car'
      ..fuelTypes = ['95'];
    final otherCar = Car()
      ..name = 'Other car'
      ..fuelTypes = ['ГАЗ'];

    await isar.writeTxn(() async {
      await isar.cars.putAll([car, otherCar]);
      final log = OdometerLog()
        ..carId = car.id
        ..dateString = '2026-01-01'
        ..odometer = 100;
      final otherLog = OdometerLog()
        ..carId = otherCar.id
        ..dateString = '2026-01-01'
        ..odometer = 200;
      await isar.odometerLogs.putAll([log, otherLog]);
    });

    final logs =
        await isar.odometerLogs.filter().carIdEqualTo(car.id).findAll();
    expect(logs, hasLength(1));
    expect(logs.single.odometer, 100);
  });
}
