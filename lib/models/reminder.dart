import 'package:isar/isar.dart';
import 'car.dart';

part 'reminder.g.dart';

enum ReminderType {
  insurance, // Страхування
  maintenance, // Технічне обслуговування
  inspection, // Техогляд
  custom, // Користувацьке нагадування
}

@collection
class Reminder {
  Id id = Isar.autoIncrement;
  // Retained for backwards-compatible Isar schema reads; business logic uses carId.
  final car = IsarLink<Car>();
  @Index()
  int? carId; // Canonical relationship key; kept nullable for old backups.

  @Enumerated(EnumType.name)
  ReminderType type = ReminderType.insurance;

  String? title; // Назва нагадування (для користувацьких)
  DateTime dueDate = DateTime.now(); // Дата виконання
  int repeatMonths = 0; // Повторювати кожні N місяців (для страхування, техогляду, кастомних по даті)
  int? repeatKm; // Повторювати через N км (для ТО, кастомних по пробегу)
  int? startKm; // Пробіг під час створення нагадування (для ТО, кастомних по пробегу)
  bool isCompleted = false; // Виконано чи ні
}
