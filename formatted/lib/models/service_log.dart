import 'package:isar/isar.dart';

import 'car.dart';

part 'service_log.g.dart';

@collection
class ServiceLog {
  Id id = Isar.autoIncrement;

  // Retained for backwards-compatible Isar schema reads; business logic uses carId.
  final car = IsarLink<Car>();

  @Index()
  int? carId; // Canonical relationship key; kept nullable for old backups.

  late DateTime date;

  late int odometer;

  late String description;
}
