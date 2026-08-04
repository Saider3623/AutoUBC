import 'package:isar/isar.dart';
import 'car.dart';

part 'fuel_log.g.dart';

@collection
class FuelLog {
  Id id = Isar.autoIncrement;

  // Retained for backwards-compatible Isar schema reads; business logic uses carId.
  final car = IsarLink<Car>();

  @Index()
  int? carId; // Canonical relationship key; kept nullable for old backups.

  late String dateString; // Date in "YYYY-MM-DD" format.

  late String timeString; // Exact time, for example "HH:mm".

  late String fuelType; // "95" or "ГАЗ".

  late double liters;
}
