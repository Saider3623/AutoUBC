import 'package:isar/isar.dart';
import 'car.dart';

part 'odometer_log.g.dart';

@collection
class OdometerLog {
  Id id = Isar.autoIncrement;

  // Retained for backwards-compatible Isar schema reads; business logic uses carId.
  final car = IsarLink<Car>();

  @Index()
  int? carId; // Canonical relationship key; kept nullable for old backups.

  late String dateString; // Date in "YYYY-MM-DD" format.

  late int odometer;

  @Index(composite: [CompositeIndex('carId')], unique: true)
  String get uniqueKey => '$carId-$dateString';
}
