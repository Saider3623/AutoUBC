import 'package:isar/isar.dart';
import 'car.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;
  final car = IsarLink<Car>();
  @Index()
  int? carId;

  String description = '';
  DateTime? dateTime;
}
