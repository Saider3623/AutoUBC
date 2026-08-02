import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/models/car.dart';
import 'package:autoubc/models/fuel_log.dart';
import 'package:autoubc/models/note.dart';
import 'package:autoubc/models/odometer_log.dart';
import 'package:autoubc/models/reminder.dart';
import 'package:autoubc/models/service_log.dart';

void main() {
  test('all child collections retain indexed carId compatibility', () {
    expect(CarSchema.properties['name'], isNotNull);
    expect(OdometerLogSchema.properties['carId'], isNotNull);
    expect(FuelLogSchema.properties['carId'], isNotNull);
    expect(ReminderSchema.properties['carId'], isNotNull);
    expect(ServiceLogSchema.properties['carId'], isNotNull);
    expect(NoteSchema.properties['carId'], isNotNull);
  });
}
