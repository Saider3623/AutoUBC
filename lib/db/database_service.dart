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
import '../models/five_day_period.dart';
import '../utils/date_utils.dart';
import '../utils/validation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Isar? _isar;
  Future<void>? _initialization;
  Future<void> _lifecycleQueue = Future<void>.value();
  bool? _hadDatabaseAtStartup;

  /// Whether the database file existed before the first local open.
  /// A missing file is the only startup condition that permits cloud restore.
  bool get hadDatabaseAtStartup => _hadDatabaseAtStartup ?? false;

  Future<T> _enqueueLifecycle<T>(Future<T> Function() operation) {
    final result = _lifecycleQueue.then((_) => operation());
    _lifecycleQueue = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<Isar> get isar {
    return _enqueueLifecycle(() async {
      if (_isar == null) {
        _initialization ??= _init();
        try {
          await _initialization;
        } finally {
          _initialization = null;
        }
      }
      return _isar!;
    });
  }

  Future<void> _init() async {
    // Try multiple directories to find a writable one
    Directory? appDir;
    final dirsToTry = <Future<Directory>>[
      getApplicationSupportDirectory(),
      getApplicationDocumentsDirectory(),
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

    _hadDatabaseAtStartup ??=
        await File('${appDir.path}${Platform.pathSeparator}autoubc.isar')
            .exists();

    _isar = await Isar.open(
      [
        CarSchema,
        OdometerLogSchema,
        FuelLogSchema,
        ReminderSchema,
        ServiceLogSchema,
        NoteSchema,
        FiveDayPeriodSchema,
      ],
      directory: appDir.path,
      name: 'autoubc',
    );

    // Make a local snapshot before the non-destructive compatibility repair.
    // Use the already opened instance here; calling the public `isar` getter
    // would enqueue behind this initialization and deadlock the lifecycle queue.
    await _createAutoLocalBackup(_isar!);
    // Compatibility repair must not prevent a valid database from opening. An
    // old backup can contain duplicate or partially migrated child records;
    // those records are retained and can be repaired later without hiding all
    // valid cars from the user.
    try {
      await _repairCarIdsFromLinks(_isar!);
    } catch (error, stackTrace) {
      debugPrint('[Database] Compatibility repair skipped: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> close() {
    return _enqueueLifecycle(() async {
      final db = _isar;
      _isar = null;
      await db?.close();
    });
  }

  /// Reopens the active database after an external file replacement.
  Future<Isar> reopen() {
    return _enqueueLifecycle(() async {
      if (_isar != null) return _isar!;
      _initialization ??= _init();
      try {
        await _initialization;
      } finally {
        _initialization = null;
      }
      return _isar!;
    });
  }

  /// Closes the database, runs [operation], then always reopens it.
  ///
  /// The whole sequence is a single lifecycle operation, so any other database
  /// request queues behind it instead of interleaving with the close/reopen
  /// pair. Overlapping `close()`/`reopen()` calls used to leave the app either
  /// without a usable database or attached to the database file that was just
  /// replaced, which froze the UI thread.
  Future<T> withClosedDatabase<T>(Future<T> Function() operation) {
    return _enqueueLifecycle(() async {
      final db = _isar;
      _isar = null;
      await db?.close();
      try {
        final value = await operation();
        return value;
      } finally {
        if (_isar == null) {
          _initialization ??= _init();
          try {
            await _initialization;
          } finally {
            _initialization = null;
          }
        }
      }
    });
  }

  // Car data operations.
  Future<List<Car>> getAllCars() async {
    final db = await isar;
    return db.cars.where().findAll();
  }

  Future<Car> addCar(Car car) async {
    final db = await isar;
    _validateCar(car);
    await db.writeTxn(() => db.cars.put(car));
    return car;
  }

  Future<void> updateCar(Car car) async {
    final db = await isar;
    _validateCar(car);
    await db.writeTxn(() => db.cars.put(car));
  }

  void _validateCar(Car car) {
    car.name = car.name.trim();
    if (car.name.isEmpty) {
      throw const DataValidationException('Car name cannot be empty.');
    }

    final fuelTypes = (car.fuelTypes ?? const <String>[])
        .map((fuelType) => fuelType.trim())
        .where((fuelType) => fuelType.isNotEmpty)
        .toSet()
        .toList();
    car.fuelTypes = fuelTypes.isEmpty ? ['ГАЗ', '95'] : fuelTypes;
  }

  Future<void> _repairCarIdsFromLinks(Isar db) async {
    await db.writeTxn(() async {
      final odometerLogs = await db.odometerLogs.where().findAll();
      for (final log in odometerLogs) {
        final linkedCarId = log.car.value?.id;
        if (linkedCarId != null && log.carId != linkedCarId) {
          final duplicate = await db.odometerLogs
              .filter()
              .carIdEqualTo(linkedCarId)
              .dateStringEqualTo(log.dateString)
              .findFirst();
          if (duplicate == null || duplicate.id == log.id) {
            log.carId = linkedCarId;
            await db.odometerLogs.put(log);
          }
        }
      }

      final fuelLogs = await db.fuelLogs.where().findAll();
      for (final log in fuelLogs) {
        final linkedCarId = log.car.value?.id;
        if (linkedCarId != null && log.carId != linkedCarId) {
          log.carId = linkedCarId;
          await db.fuelLogs.put(log);
        }
      }

      final reminders = await db.reminders.where().findAll();
      for (final reminder in reminders) {
        final linkedCarId = reminder.car.value?.id;
        if (linkedCarId != null && reminder.carId != linkedCarId) {
          reminder.carId = linkedCarId;
          await db.reminders.put(reminder);
        }
      }

      final serviceLogs = await db.serviceLogs.where().findAll();
      for (final log in serviceLogs) {
        final linkedCarId = log.car.value?.id;
        if (linkedCarId != null && log.carId != linkedCarId) {
          log.carId = linkedCarId;
          await db.serviceLogs.put(log);
        }
      }

      final notes = await db.notes.where().findAll();
      for (final note in notes) {
        final linkedCarId = note.car.value?.id;
        if (linkedCarId != null && note.carId != linkedCarId) {
          note.carId = linkedCarId;
          await db.notes.put(note);
        }
      }
    });
  }

  Future<void> deleteCar(Car car) async {
    final db = await isar;
    await db.writeTxn(() async {
      // Delete all related records through filters without loading them first.
      await db.odometerLogs.filter().carIdEqualTo(car.id).deleteAll();
      await db.fuelLogs.filter().carIdEqualTo(car.id).deleteAll();
      await db.reminders.filter().carIdEqualTo(car.id).deleteAll();
      await db.serviceLogs.filter().carIdEqualTo(car.id).deleteAll();
      await db.notes.filter().carIdEqualTo(car.id).deleteAll();
      // Delete the car itself.
      await db.cars.delete(car.id);
    });
  }

  // Odometer log operations.
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
    await _requireCar(db, carId);
    validateDateString(dateString);
    validateNonNegativeNumber(odometer, 'Odometer');

    await db.writeTxn(() async {
      final existing = await db.odometerLogs
          .filter()
          .carIdEqualTo(carId)
          .dateStringEqualTo(dateString)
          .findFirst();

      final previous = await db.odometerLogs
          .filter()
          .carIdEqualTo(carId)
          .dateStringLessThan(dateString)
          .sortByDateStringDesc()
          .findFirst();
      if (previous != null && odometer < previous.odometer) {
        throw DataValidationException(
            'Odometer cannot be lower than the previous reading (${previous.odometer}).');
      }

      final next = await db.odometerLogs
          .filter()
          .carIdEqualTo(carId)
          .dateStringGreaterThan(dateString)
          .sortByDateString()
          .findFirst();
      if (next != null && odometer > next.odometer) {
        throw DataValidationException(
            'Odometer cannot be higher than the next reading (${next.odometer}).');
      }

      if (existing != null) {
        existing.odometer = odometer;
        await db.odometerLogs.put(existing);
      } else {
        final log = OdometerLog()
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

  // Fuel log operations.
  Future<void> addFuelLog(int carId, String dateString, String timeString,
      String fuelType, double liters) async {
    final db = await isar;
    await _requireCar(db, carId);
    validateDateString(dateString);
    validateTimeString(timeString);
    validateNonNegativeNumber(liters, 'Liters');
    if (fuelType.trim().isEmpty) {
      throw const DataValidationException('Fuel type cannot be empty.');
    }

    await db.writeTxn(() async {
      final log = FuelLog()
        ..carId = carId
        ..dateString = dateString
        ..timeString = timeString
        ..fuelType = fuelType.trim()
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

  Future<Car> _requireCar(Isar db, int carId) async {
    final car = await db.cars.get(carId);
    if (car == null) {
      throw const DataValidationException('Car no longer exists.');
    }
    return car;
  }

  // Report data operations.
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
    final log = await db.odometerLogs
        .filter()
        .carIdEqualTo(carId)
        .dateStringLessThan(dateString)
        .sortByDateStringDesc()
        .findFirst();
    if (log != null) {
      return log;
    }

    final target = DateTime.tryParse(dateString);
    if (target == null) {
      return null;
    }

    final all = await db.odometerLogs
        .filter()
        .carIdEqualTo(carId)
        .sortByDateStringDesc()
        .findAll();

    for (final item in all) {
      final d = DateTime.tryParse(item.dateString);
      if (d != null && d.isBefore(target)) {
        return item;
      }
    }
    return null;
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

  // Reminder operations.
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
    final carId = reminder.carId;
    if (carId == null) {
      throw const DataValidationException('Reminder must have a car.');
    }
    await _requireCar(db, carId);
    _validateReminder(reminder);

    await db.writeTxn(() => db.reminders.put(reminder));
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await isar;
    final carId = reminder.carId;
    if (carId == null) {
      throw const DataValidationException('Reminder must have a car.');
    }
    await _requireCar(db, carId);
    _validateReminder(reminder);
    await db.writeTxn(() => db.reminders.put(reminder));
  }

  void _validateReminder(Reminder reminder) {
    validateNonNegativeNumber(reminder.repeatMonths, 'Repeat months');
    if (reminder.repeatKm != null) {
      validateNonNegativeNumber(reminder.repeatKm!, 'Repeat kilometers');
    }
    if (reminder.startKm != null) {
      validateNonNegativeNumber(reminder.startKm!, 'Starting kilometers');
    }
    if (reminder.title != null && reminder.title!.trim().isEmpty) {
      reminder.title = null;
    }
  }

  Future<void> deleteReminder(Reminder reminder) async {
    final db = await isar;
    await db.writeTxn(() => db.reminders.delete(reminder.id));
  }

  Future<void> completeReminder(Reminder reminder) async {
    final db = await isar;
    final carId = reminder.carId;
    if (carId == null) {
      throw const DataValidationException('Reminder must have a car.');
    }
    await _requireCar(db, carId);
    _validateReminder(reminder);

    final hasKmRepeat = (reminder.repeatKm ?? 0) > 0;
    final hasMonthRepeat = reminder.repeatMonths > 0;

    if (!hasKmRepeat && !hasMonthRepeat) {
      await db.writeTxn(() async {
        reminder.isCompleted = true;
        await db.reminders.put(reminder);
      });
      return;
    }

    final newReminder = Reminder()
      ..carId = carId
      ..type = reminder.type
      ..title = reminder.title
      ..repeatMonths = reminder.repeatMonths
      ..repeatKm = reminder.repeatKm
      ..isCompleted = false;

    if (hasKmRepeat) {
      // For mileage-based reminders, use the latest reading and add repeatKm.
      final odometerLogs = await db.odometerLogs
          .filter()
          .carIdEqualTo(carId)
          .sortByDateStringDesc()
          .findFirst();
      final currentKm = odometerLogs?.odometer ?? 0;
      newReminder.startKm = currentKm;
      newReminder.dueDate =
          DateTime.now(); // The date is less important for maintenance.
    } else {
      // For insurance and inspection reminders, add the configured months.
      newReminder.dueDate = addMonthsClamped(
        reminder.dueDate,
        reminder.repeatMonths,
      );
      newReminder.startKm = reminder.startKm;
    }

    await db.writeTxn(() async {
      reminder.isCompleted = true;
      await db.reminders.put(reminder);
      await db.reminders.put(newReminder);
    });
  }

  // Service log operations.
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
    await _validateServiceLog(db, log);
    await db.writeTxn(() => db.serviceLogs.put(log));
  }

  Future<void> updateServiceLog(ServiceLog log) async {
    final db = await isar;
    await _validateServiceLog(db, log);
    final existing = await db.serviceLogs.get(log.id);
    if (existing == null) {
      throw const DataValidationException('Service entry no longer exists.');
    }
    await db.writeTxn(() => db.serviceLogs.put(log));
  }

  Future<void> _validateServiceLog(Isar db, ServiceLog log) async {
    final carId = log.carId;
    if (carId == null) {
      throw const DataValidationException('Service entry must have a car.');
    }
    await _requireCar(db, carId);
    validateNonNegativeNumber(log.odometer, 'Service odometer');
    log.description = log.description.trim();
    if (log.description.isEmpty) {
      throw const DataValidationException(
          'Service description cannot be empty.');
    }
  }

  Future<void> deleteServiceLog(ServiceLog log) async {
    final db = await isar;
    await db.writeTxn(() => db.serviceLogs.delete(log.id));
  }

  // Note operations.
  Future<List<Note>> getNotesForCar(int carId) async {
    final db = await isar;
    final notes = await db.notes
        .filter()
        .carIdEqualTo(carId)
        .sortByDateTimeDesc()
        .findAll();
    notes.sort((a, b) {
      final aDate = a.dateTime;
      final bDate = b.dateTime;
      if (aDate == null && bDate == null) {
        return b.id.compareTo(a.id);
      }
      if (aDate == null) {
        return 1;
      }
      if (bDate == null) {
        return -1;
      }
      final dateCompare = bDate.compareTo(aDate);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return b.id.compareTo(a.id);
    });
    return notes;
  }

  Future<void> addNote(Note note) async {
    final db = await isar;
    final carId = note.carId;
    if (carId == null) {
      throw const DataValidationException('Note must have a car.');
    }
    await _requireCar(db, carId);
    _validateNote(note);

    await db.writeTxn(() => db.notes.put(note));
  }

  Future<void> updateNote(Note note) async {
    final db = await isar;
    final carId = note.carId;
    if (carId == null) {
      throw const DataValidationException('Note must have a car.');
    }
    await _requireCar(db, carId);
    _validateNote(note);
    await db.writeTxn(() => db.notes.put(note));
  }

  void _validateNote(Note note) {
    note.description = note.description.trim();
    if (note.description.isEmpty) {
      throw const DataValidationException('Note cannot be empty.');
    }
  }

  Future<void> deleteNote(Note note) async {
    final db = await isar;
    await db.writeTxn(() => db.notes.delete(note.id));
  }

  // Working-week schedule operations (app-wide, not tied to a car).
  Future<List<FiveDayPeriod>> getFiveDayPeriods() async {
    final db = await isar;
    final periods = await db.fiveDayPeriods.where().findAll();
    // Newest periods first.
    periods.sort((a, b) => b.startDate.compareTo(a.startDate));
    return periods;
  }

  /// Replaces the five-day period with [startDate]..[endDate] (`YYYY-MM-DD`,
  /// `null` end = open-ended). A `null` [startDate] removes the period, so
  /// every week has six days. Only one period is kept.
  Future<void> setFiveDayPeriod(String? startDate, String? endDate) async {
    final db = await isar;
    final start = startDate?.trim();
    final trimmedEnd = endDate?.trim();
    final end = (trimmedEnd == null || trimmedEnd.isEmpty) ? null : trimmedEnd;
    if (start != null) {
      validateDateString(start);
      if (end != null) {
        validateDateString(end);
        if (end.compareTo(start) < 0) {
          throw const DataValidationException(
              'Five-day period cannot end before it starts.');
        }
      }
    }

    await db.writeTxn(() async {
      await db.fiveDayPeriods.clear();
      if (start == null) return;
      final period = FiveDayPeriod()
        ..startDate = start
        ..endDate = end;
      await db.fiveDayPeriods.put(period);
    });
  }

  // Backup and restore operations.
  Future<String> getDatabasePath() async {
    final db = await isar;
    return db.path!;
  }

  /// Opens a downloaded snapshot with the current schemas before it replaces
  /// the active database file.
  Future<bool> verifyDatabaseSnapshot(String filePath) async {
    final file = File(filePath);
    if (!await file.exists() || await file.length() == 0) return false;

    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    if (!fileName.endsWith('.isar')) return false;
    final databaseName =
        fileName.substring(0, fileName.length - '.isar'.length);
    Isar? checkDb;
    try {
      checkDb = await Isar.open(
        [
          CarSchema,
          OdometerLogSchema,
          FuelLogSchema,
          ReminderSchema,
          ServiceLogSchema,
          NoteSchema,
          FiveDayPeriodSchema,
        ],
        directory: file.parent.path,
        name: databaseName,
      );
      final cars = await checkDb.cars.where().findAll();
      debugPrint(
          '[Database] Snapshot verified: ${file.path}, cars=${cars.length}');
      return true;
    } catch (error) {
      debugPrint('[Database] Snapshot validation failed: $error');
      return false;
    } finally {
      await checkDb?.close();
      final lockFile = File('$filePath.lock');
      if (await lockFile.exists()) await lockFile.delete();
    }
  }

  /// Creates a compact snapshot for cloud upload without reading the live DB
  /// file while it may still be changing.
  Future<String> createDatabaseSnapshot() async {
    final db = await isar;
    final directory = await getTemporaryDirectory();
    final snapshot = File(
      '${directory.path}/autoubc_sync_${DateTime.now().microsecondsSinceEpoch}.isar',
    );
    await db.copyToFile(snapshot.path);
    return snapshot.path;
  }

  Future<void> createAutoLocalBackup() async {
    await _createAutoLocalBackup(await isar);
  }

  Future<void> _createAutoLocalBackup(Isar db) async {
    try {
      // Resolve the directory used for local backups.
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

      // Create a timestamped backup filename.
      final now = DateTime.now();
      final backupFileName =
          'autoubc_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.isar';
      final backupFile = File('${backupDir.path}/$backupFileName');
      final tempBackupFile = File('${backupFile.path}.tmp');

      // Isar creates a compact, transaction-safe snapshot for backups.
      if (await tempBackupFile.exists()) await tempBackupFile.delete();
      await db.copyToFile(tempBackupFile.path);
      if (!await tempBackupFile.exists() ||
          await tempBackupFile.length() == 0) {
        throw StateError('Local backup snapshot is empty.');
      }
      if (await backupFile.exists()) await backupFile.delete();
      await tempBackupFile.rename(backupFile.path);

      // Remove old backups and keep only the seven newest files.
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

      // Remove every backup except the seven newest files.
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
