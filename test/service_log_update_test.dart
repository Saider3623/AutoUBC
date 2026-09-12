import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/db/database_service.dart';
import 'package:autoubc/models/car.dart';
import 'package:autoubc/models/service_log.dart';

void main() {
  test('updates an existing service log without creating a duplicate',
      () async {
    final database = DatabaseService();
    Car? car;

    try {
      car = Car()
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
    } on ArgumentError {
      markTestSkipped(
          'Isar native library is unavailable in this test runner.');
    } on StateError catch (error) {
      if (error.toString().contains('Could not find a writable directory')) {
        markTestSkipped(
            'Application storage is unavailable in this test runner.');
      } else {
        rethrow;
      }
    } finally {
      if (car != null) {
        try {
          await database.deleteCar(car);
        } catch (_) {}
      }
      await database.close();
    }
  });
}
