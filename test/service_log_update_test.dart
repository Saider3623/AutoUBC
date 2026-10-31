import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/db/database_service.dart';
import 'package:autoubc/models/car.dart';
import 'package:autoubc/models/service_log.dart';

import 'support/test_database.dart';

void main() {
  Directory? root;

  setUpAll(() async => root = await useTemporaryDatabase());
  tearDownAll(() => disposeTemporaryDatabase(root));

  test('updates an existing service log without creating a duplicate',
      () async {
    if (root == null) {
      markTestSkipped(
          'Isar native library is unavailable in this test runner.');
      return;
    }
    final database = DatabaseService();
    final car = Car()
      ..name = 'Service update test'
      ..fuelTypes = ['95'];
    await database.addCar(car);

    final log = ServiceLog()
      ..carId = car.id
      ..date = DateTime(2026, 9, 1)
      ..odometer = 120000
      ..description = 'Oil change';
    await database.addServiceLog(log);

    log
      ..date = DateTime(2026, 9, 2)
      ..odometer = 120500
      ..description = 'Oil and filter change';
    await database.updateServiceLog(log);

    final logs = await database.getServiceLogsForCar(car.id);
    expect(logs, hasLength(1));
    expect(logs.single.id, log.id);
    expect(logs.single.odometer, 120500);
    expect(logs.single.description, 'Oil and filter change');
  });
}
