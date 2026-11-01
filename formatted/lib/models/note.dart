import 'package:isar/isar.dart';

import 'car.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;
  // Retained for backwards-compatible Isar schema reads; business logic uses carId.
  final car = IsarLink<Car>();
  @Index()
  int? carId; // Canonical relationship key; kept nullable for old backups.

  String description = '';
  DateTime? dateTime;
}
