import 'package:isar/isar.dart';

part 'car.g.dart';

@collection
class Car {
  Id id = Isar.autoIncrement;

  late String name;

  List<String>? fuelTypes;

  /// Registration plate, printed in the PDF report when set.
  String? plateNumber;

  /// Driver name, printed in the PDF report when set.
  String? driverName;

  // Legacy field retained in the Isar schema so existing backups keep opening.
  // The current report logic derives consumption from all configured fuel types.
  List<String>? selectedFuelTypesForConsumption;
}
