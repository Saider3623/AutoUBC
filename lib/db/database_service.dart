import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/car.dart';
import '../models/odometer_log.dart';
import '../models/fuel_log.dart';
import '../models/reminder.dart';
import '../models/service_log.dart';
import '../models/note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Isar? _isar;

  Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    await _init();
    return _isar!;
  }

  Future<void> _init() async {
    // Try multiple directories to find a writable one
    Directory? appDir;
    final dirsToTry = <Future<Directory>>[
      getApplicationSupportDirectory(),
      getApplicationDocumentsDirectory(),
      getTemporaryDirectory(),
    ];

    for (final dirFuture in dirsToTry) {
      try {
        final dir = await dirFuture;
        final testDir = Directory('${dir.path}/autoubc');
        if (!await testDir.exists()) {
          await testDir.create(recursive: true);
        }
        // Try to write a test file to check access
        final testFile = File('${testDir.path}/.test');
        await testFile.writeAsString('test');
        await testFile.delete();
        appDir = testDir;
        break;
      } catch (_) {
        continue;
      }
    }

    if (appDir == null) {
      throw StateError('Could not find a writable directory for the database');
    }

    _isar = await Isar.open(
      [
        CarSchema,
        OdometerLogSchema,
        FuelLogSchema,
        ReminderSchema,
        ServiceLogSchema,
        NoteSchema
      ],
      directory: appDir.path,
      name: 'autoubc',
    );
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  // Методы для работы с Car
  Future<List<Car>> getAllCars() async {
    final db = await isar;
    return db.cars.where().findAll();
  }

  Future<void> addCar(Car car) async {
    final db = await isar;
    if (car.fuelTypes == null || car.fuelTypes!.isEmpty) {
      car.fuelTypes = ['ГАЗ', '95'];
    }
    await db.writeTxn(() => db.cars.put(car));
  }

  Future<void> updateCar(Car car) async {
    final db = await isar;
    await db.writeTxn(() => db.cars.put(car));
  }

  Future<void> deleteCar(Car car) async {
    final db = await isar;
    await db.writeTxn(() async {
      // Удаляем все связанные записи сразу по фильтру, без извлечения
      await db.odometerLogs.filter().carIdEqualTo(car.id).deleteAll();
      await db.fuelLogs.filter().carIdEqualTo(car.id).deleteAll();
      await db.reminders.filter().carIdEqualTo(car.id).deleteAll();
      await db.serviceLogs.filter().carIdEqualTo(car.id).deleteAll();
      await db.notes.filter().carIdEqualTo(car.id).deleteAll();
      // Удаляем саму машину
      await db.cars.delete(car.id);
    });
  }

  // Методы для работы с OdometerLog
  Future<OdometerLog?> getOdometerLog(int carId, String dateString) async {
    final db = await isar;
    return db.odometerLogs
        .filter()
        .carIdEqualTo(carId)
        .dateStringEqualTo(dateString)
        .findFirst();
  }

  Future<void> saveOdometerLog(
      int carId, String dateString, int odometer) async {
    final db = await isar;
    final car = await db.cars.get(carId);
    if (car == null) return;

    await db.writeTxn(() async {
      // Проверяем, есть ли уже запись за этот день
      final existing = await db.odometerLogs
          .filter()
          .carIdEqualTo(carId)
          .dateStringEqualTo(dateString)
          .findFirst();
      if (existing != null) {
        existing.odometer = odometer;
        await db.odometerLogs.put(existing);
      } else {
        final log = OdometerLog()
          ..car.value = car
          ..carId = carId
          ..dateString = dateString
          ..odometer = odometer;
        await db.odometerLogs.put(log);
      }
    });
  }

  Future<void> deleteOdometerLog(OdometerLog log) async {
    final db = await isar;
    await db.writeTxn(() => db.odometerLogs.delete(log.id));
  }

  Future<List<OdometerLog>> getOdometerLogsForCar(int carId) async {
    final db = await isar;
    return db.odometerLogs
        .filter()
        .carIdEqualTo(carId)
        .sortByDateStringDesc()
        .findAll();
  }

  // Методы для работы с FuelLog
  Future<void> addFuelLog(int carId, String dateString, String timeString,
      String fuelType, double liters) async {
    final db = await isar;
    final car = await db.cars.get(carId);
    if (car == null) return;

    await db.writeTxn(() async {
      final log = FuelLog()
        ..car.value = car
        ..carId = carId
        ..dateString = dateString
        ..timeString = timeString
        ..fuelType = fuelType
        ..liters = liters;
      await db.fuelLogs.put(log);
    });
  }

  Future<void> deleteFuelLog(FuelLog log) async {
    final db = await isar;
    await db.writeTxn(() => db.fuelLogs.delete(log.id));
  }

  Future<List<FuelLog>> getFuelLogsForCar(int carId) async {
    final db = await isar;
    return db.fuelLogs
        .filter()
        .carIdEqualTo(carId)
        .sortByDateStringDesc()
        .thenByTimeStringDesc()
        .findAll();
  }

  // Методы для отчетов
  Future<List<OdometerLog>> getOdometerLogsInRange(
      int carId, String startDate, String endDate) async {
    final db = await isar;
    return db.odometerLogs
        .filter()
        .carIdEqualTo(carId)
        .dateStringBetween(startDate, endDate)
        .findAll();
  }

  Future<OdometerLog?> getLastOdometerLogBeforeDate(
      int carId, String dateString) async {
    final db = await isar;
    return db.odometerLogs
        .filter()
        .carIdEqualTo(carId)
        .dateStringLessThan(dateString)
        .sortByDateStringDesc()
        .findFirst();
  }

  Future<List<FuelLog>> getFuelLogsInRange(
      int carId, String startDate, String endDate) async {
    final db = await isar;
    return db.fuelLogs
        .filter()
        .carIdEqualTo(carId)
        .dateStringBetween(startDate, endDate)
        .findAll();
  }

  // Методы для работы с Reminder
  Future<List<Reminder>> getRemindersForCar(int carId) async {
    final db = await isar;
    return db.reminders
        .filter()
        .carIdEqualTo(carId)
        .sortByDueDateDesc()
        .findAll();
  }

  Future<void> addReminder(Reminder reminder) async {
    final db = await isar;
    final car = await db.cars.get(reminder.carId!);
    if (car == null) return;

    await db.writeTxn(() async {
      reminder.car.value = car;
      await db.reminders.put(reminder);
    });
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await isar;
    await db.writeTxn(() => db.reminders.put(reminder));
  }

  Future<void> deleteReminder(Reminder reminder) async {
    final db = await isar;
    await db.writeTxn(() => db.reminders.delete(reminder.id));
  }

  Future<void> completeReminder(Reminder reminder) async {
    final db = await isar;
    final car = await db.cars.get(reminder.carId!);
    if (car == null) return;

    final newReminder = Reminder()
      ..carId = reminder.carId
      ..type = reminder.type
      ..repeatMonths = reminder.repeatMonths
      ..repeatKm = reminder.repeatKm
      ..isCompleted = false;

    if (reminder.type == ReminderType.maintenance) {
      // Для ТО беремо останній пробіг та додаємо repeatKm
      final odometerLogs = await db.odometerLogs
          .filter()
          .carIdEqualTo(reminder.carId!)
          .sortByDateStringDesc()
          .findFirst();
      final currentKm = odometerLogs?.odometer ?? 0;
      newReminder.startKm = currentKm;
      newReminder.dueDate = DateTime.now(); // Для ТО дата менш важлива
    } else {
      // Для страхування та техогляду - додаємо місяці
      newReminder.dueDate = DateTime(
        reminder.dueDate.year + (reminder.repeatMonths ~/ 12),
        reminder.dueDate.month + (reminder.repeatMonths % 12),
        reminder.dueDate.day,
      );
      newReminder.startKm = reminder.startKm;
    }

    await db.writeTxn(() async {
      // Обновляем старое напоминание как выполненное
      reminder.isCompleted = true;
      await db.reminders.put(reminder);
      // Добавляем новое напоминание
      newReminder.car.value = car;
      await db.reminders.put(newReminder);
    });
  }

  // Методы для работы с ServiceLog
  Future<List<ServiceLog>> getServiceLogsForCar(int carId) async {
    final db = await isar;
    return db.serviceLogs
        .filter()
        .carIdEqualTo(carId)
        .sortByDateDesc()
        .findAll();
  }

  Future<void> addServiceLog(ServiceLog log) async {
    final db = await isar;
    final car = await db.cars.get(log.carId!);
    if (car == null) return;

    await db.writeTxn(() async {
      log.car.value = car;
      await db.serviceLogs.put(log);
    });
  }

  Future<void> deleteServiceLog(ServiceLog log) async {
    final db = await isar;
    await db.writeTxn(() => db.serviceLogs.delete(log.id));
  }

  // Методы для работы с Note
  Future<List<Note>> getNotesForCar(int carId) async {
    final db = await isar;
    return db.notes.filter().carIdEqualTo(carId).sortByDateTimeDesc().findAll();
  }

  Future<void> addNote(Note note) async {
    final db = await isar;
    final car = await db.cars.get(note.carId!);
    if (car == null) return;

    await db.writeTxn(() async {
      note.car.value = car;
      await db.notes.put(note);
    });
  }

  Future<void> updateNote(Note note) async {
    final db = await isar;
    await db.writeTxn(() => db.notes.put(note));
  }

  Future<void> deleteNote(Note note) async {
    final db = await isar;
    await db.writeTxn(() => db.notes.delete(note.id));
  }

  // Методы для бэкапа и восстановления
  Future<String> getDatabasePath() async {
    final db = await isar;
    return db.path!;
  }

  Future<void> createAutoLocalBackup() async {
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);

      // Получаем директорию для сохранения бэкапов
      Directory directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final backupDir = Directory('${directory.path}/AutoUBC_Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Создаем имя файла бэкапа с датой и временем
      final now = DateTime.now();
      final backupFileName =
          'autoubc_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.isar';
      final backupFile = File('${backupDir.path}/$backupFileName');

      // Копируем файл базы данных
      await dbFile.copy(backupFile.path);

      // Удаляем старые бэкапы, оставляем последние 7
      await _cleanOldBackups(backupDir);
    } catch (e) {
      debugPrint('Помилка створення автобэкапу: $e');
    }
  }

  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().toList();
      final backupFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.isar'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Удаляем все бэкапы, кроме последних 7
      if (backupFiles.length > 7) {
        for (int i = 7; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Помилка очистки старих бэкапів: $e');
    }
  }
}
