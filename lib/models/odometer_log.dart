import 'package:isar/isar.dart';
import 'car.dart';

part 'odometer_log.g.dart';

@collection
class OdometerLog {
  Id id = Isar.autoIncrement;

  final car = IsarLink<Car>();

  @Index()
  int? carId; // Для упрощения индексации

  late String dateString; // формат "YYYY-MM-DD"

  late int odometer;

  @Index(composite: [CompositeIndex('carId')], unique: true)
  String get uniqueKey => '$carId-$dateString';
}
