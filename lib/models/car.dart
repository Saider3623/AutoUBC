import 'package:isar/isar.dart';

part 'car.g.dart';

@collection
class Car {
  Id id = Isar.autoIncrement;

  late String name;

  List<String>? fuelTypes;
  
  List<String>? selectedFuelTypesForConsumption; // Типы топлива для показа расхода
}
