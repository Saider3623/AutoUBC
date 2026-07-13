import 'package:isar/isar.dart';
import 'car.dart';

part 'service_log.g.dart';

@collection
class ServiceLog {
  Id id = Isar.autoIncrement;

  final car = IsarLink<Car>();

  @Index()
  int? carId;

  late DateTime date;

  late int odometer;

  late String description;
}
