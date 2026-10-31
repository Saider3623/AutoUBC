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
import '../services/cloud_sync_policy.dart';
import '../utils/date_utils.dart';
import '../utils/validation.dart';

/// A local backup file in the `AutoUBC_Backups` folder.
class LocalBackup {
  final String path;
  final DateTime time;

  /// `before-restore` or `before-delete` for copies made before those
  /// actions, `null` for routine backups.
  final String? tag;
  final int size;

  const LocalBackup({
    required this.path,
    required this.time,
    required this.size,
    this.tag,
  });
}

const List<CollectionSchema<dynamic>> _schemas = [
  CarSchema,
  OdometerLogSchema,
  FuelLogSchema,
  ReminderSchema,
  ServiceLogSchema,
  NoteSchema,
  FiveDayPeriodSchema,
];

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Test-only replacement for the platform folders: the database, the local
  /// backups and temporary files live under this folder. `path_provider` has
  /// no implementation in `flutter test`.
  @visibleForTesting
  static Directory? debugStorageRoot;

  Future<Directory> _storageFolder(
    String name,
    Future<Directory> Function() platformFolder,
  ) async {
    final root = debugStorageRoot;
    if (root == null) return platformFolder();
    final folder = Directory('${root.path}${Platform.pathSeparator}$name');
    await folder.create(recursive: true);
    return folder;
  }

  Future<Directory> _temporaryFolder() =>
      _storageFolder('tmp', getTemporaryDirectory);

  Isar? _isar;
  Future<void>? _initialization;
  Future<void> _lifecycleQueue = Future<void>.value();
  String? _databaseFilePath;

  Future<T> _enqueueLifecycle<T>(Future<T> Function() operation) {
    final result = _lifecycleQueue.then((_) => operation());
    _lifecycleQueue = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  Future<Isar> get isar => _enqueueLifecycle(_openInQueue);

  /// Opens the database if needed. Must only run inside the lifecycle queue.
  Future<Isar> _openInQueue() async {
    if (_isar == null) {
      _initialization ??= _init();
      try {
        await _initialization;
      } finally {
        _initialization = null;
      }
    }
    return _isar!;
  }

  /// Runs [action] inside the lifecycle queue, so the database cannot be
  /// closed or replaced while it reads the open instance.
  Future<T> runExclusive<T>(Future<T> Function(Isar db) action) {
    return _enqueueLifecycle(() async => action(await _openInQueue()));
  }

  Future<void> _init() async {
    // Try multiple directories to find a writable one
    Directory? appDir;
    final dirsToTry = <Future<Directory>>[
      _storageFolder('support', getApplicationSupportDirectory),
      _storageFolder('documents', getApplicationDocumentsDirectory),
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

    final databasePath = '${appDir.path}${Platform.pathSeparator}autoubc.isar';
    _databaseFilePath = databasePath;
    // A replacement interrupted after the old file was moved aside leaves only
    // the `.previous` copy: put it back before opening.
    final previous = File('$databasePath.previous');
    if (!await File(databasePath).exists() && await previous.exists()) {
      await previous.rename(databasePath);
    }

    _isar = await Isar.open(
      _schemas,
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

  /// Saves [car] and renames fuel types in its existing refuels in one
  /// transaction. [renames] maps an old fuel type name to the new one, so
  /// "95" → "А-95" keeps the history under one fuel type.
  Future<void> updateCarWithFuelRenames(
    Car car,
    Map<String, String> renames,
  ) async {
    final db = await isar;
    _validateCar(car);
    await db.writeTxn(() async {
      await db.cars.put(car);
      for (final entry in renames.entries) {
        final from = entry.key.trim();
        final to = entry.value.trim();
        if (from.isEmpty || to.isEmpty || from == to) continue;
        final logs = await db.fuelLogs
            .filter()
            .carIdEqualTo(car.id)
            .fuelTypeEqualTo(from)
            .findAll();
        for (final log in logs) {
          log.fuelType = to;
        }
        await db.fuelLogs.putAll(logs);
      }
    });
  }

  /// Number of records that a deletion of the car would remove.
  Future<({int odometer, int fuel, int reminders, int service, int notes})>
      countCarRecords(int carId) async {
    final db = await isar;
    return (
      odometer: await db.odometerLogs.filter().carIdEqualTo(carId).count(),
      fuel: await db.fuelLogs.filter().carIdEqualTo(carId).count(),
      reminders: await db.reminders.filter().carIdEqualTo(carId).count(),
      service: await db.serviceLogs.filter().carIdEqualTo(carId).count(),
      notes: await db.notes.filter().carIdEqualTo(carId).count(),
    );
  }

  void _validateCar(Car car) {
    car.name = car.name.trim();
    final plate = car.plateNumber?.trim();
    car.plateNumber = (plate == null || plate.isEmpty) ? null : plate;
    final driver = car.driverName?.trim();
    car.driverName = (driver == null || driver.isEmpty) ? null : driver;
    if (car.name.isEmpty) {
      throw const DataValidationException(
          ValidationCode.carNameEmpty, 'Car name cannot be empty.');
    }

    final fuelTypes = (car.fuelTypes ?? const <String>[])
        .map((fuelType) => fuelType.trim())
        .where((fuelType) => fuelType.isNotEmpty)
        .toSet()
        .toList();
    car.fuelTypes = fuelTypes.isEmpty ? ['ГАЗ', '95'] : fuelTypes;
  }

  /// Reads a legacy link inside the repair transaction. `IsarLink.value`
  /// loads lazily with a synchronous transaction, which Isar refuses inside
  /// `writeTxn`, so the repair failed whenever the database had records.
  Future<int?> _linkedCarId(IsarLink<Car> link) async {
    if (!link.isLoaded) await link.load();
    return link.value?.id;
  }

  Future<void> _repairCarIdsFromLinks(Isar db) async {
    await db.writeTxn(() async {
      final odometerLogs = await db.odometerLogs.where().findAll();
      for (final log in odometerLogs) {
        final linkedCarId = await _linkedCarId(log.car);
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
        final linkedCarId = await _linkedCarId(log.car);
        if (linkedCarId != null && log.carId != linkedCarId) {
          log.carId = linkedCarId;
          await db.fuelLogs.put(log);
        }
      }

      final reminders = await db.reminders.where().findAll();
      for (final reminder in reminders) {
        final linkedCarId = await _linkedCarId(reminder.car);
        if (linkedCarId != null && reminder.carId != linkedCarId) {
          reminder.carId = linkedCarId;
          await db.reminders.put(reminder);
        }
      }

      final serviceLogs = await db.serviceLogs.where().findAll();
      for (final log in serviceLogs) {
        final linkedCarId = await _linkedCarId(log.car);
        if (linkedCarId != null && log.carId != linkedCarId) {
          log.carId = linkedCarId;
          await db.serviceLogs.put(log);
        }
      }

      final notes = await db.notes.where().findAll();
      for (final note in notes) {
        final linkedCarId = await _linkedCarId(note.car);
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

      // Neighbours are found in Dart: Isar 3 string range filters
      // (`lessThan`, `between`) return no records, so a reading lower than
      // the previous one used to be accepted.
      final carLogs =
          await db.odometerLogs.filter().carIdEqualTo(carId).findAll();
      OdometerLog? previous;
      OdometerLog? next;
      for (final log in carLogs) {
        final order = log.dateString.compareTo(dateString);
        if (order < 0 &&
            (previous == null ||
                log.dateString.compareTo(previous.dateString) > 0)) {
          previous = log;
        } else if (order > 0 &&
            (next == null || log.dateString.compareTo(next.dateString) < 0)) {
          next = log;
        }
      }
      if (previous != null && odometer < previous.odometer) {
        throw DataValidationException(
          ValidationCode.odometerBelowPrevious,
          'Odometer cannot be lower than the previous reading '
          '(${previous.odometer}).',
          reading: previous.odometer,
          readingDate: previous.dateString,
        );
      }

      if (next != null && odometer > next.odometer) {
        throw DataValidationException(
          ValidationCode.odometerAboveNext,
          'Odometer cannot be higher than the next reading (${next.odometer}).',
          reading: next.odometer,
          readingDate: next.dateString,
        );
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
      throw const DataValidationException(
          ValidationCode.fuelTypeEmpty, 'Fuel type cannot be empty.');
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

  /// Updates the type, litres, date and time of an existing refuel.
  Future<void> updateFuelLog(FuelLog log) async {
    final db = await isar;
    final carId = log.carId;
    if (carId == null) {
      throw const DataValidationException(
          ValidationCode.recordWithoutCar, 'Refuel must have a car.');
    }
    await _requireCar(db, carId);
    validateDateString(log.dateString);
    validateTimeString(log.timeString);
    validateNonNegativeNumber(log.liters, 'Liters');
    log.fuelType = log.fuelType.trim();
    if (log.fuelType.isEmpty) {
      throw const DataValidationException(
          ValidationCode.fuelTypeEmpty, 'Fuel type cannot be empty.');
    }
    final existing = await db.fuelLogs.get(log.id);
    if (existing == null) {
      throw const DataValidationException(
          ValidationCode.recordMissing, 'Refuel no longer exists.');
    }
    await db.writeTxn(() => db.fuelLogs.put(log));
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
      throw const DataValidationException(
          ValidationCode.carMissing, 'Car no longer exists.');
    }
    return car;
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
      throw const DataValidationException(
          ValidationCode.recordWithoutCar, 'Reminder must have a car.');
    }
    await _requireCar(db, carId);
    _validateReminder(reminder);

    await db.writeTxn(() => db.reminders.put(reminder));
  }

  Future<void> updateReminder(Reminder reminder) async {
    final db = await isar;
    final carId = reminder.carId;
    if (carId == null) {
      throw const DataValidationException(
          ValidationCode.recordWithoutCar, 'Reminder must have a car.');
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

  /// Active and completed reminders of every car (for notifications).
  Future<List<Reminder>> getAllReminders() async {
    final db = await isar;
    return db.reminders.where().findAll();
  }

  /// Marks [reminder] done. A repeating reminder gets its next occurrence;
  /// its id is returned so the completion can be undone. [startKm] is the
  /// mileage of the work (from a service book entry); without it a mileage
  /// reminder restarts from the latest odometer reading.
  Future<int?> completeReminder(Reminder reminder, {int? startKm}) async {
    final db = await isar;
    final carId = reminder.carId;
    if (carId == null) {
      throw const DataValidationException(
          ValidationCode.recordWithoutCar, 'Reminder must have a car.');
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
      return null;
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
      newReminder.startKm = startKm ?? currentKm;
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
    return newReminder.id;
  }

  /// Reverts [completeReminder]: removes the next occurrence it created and
  /// makes [reminder] active again.
  Future<void> undoCompleteReminder(Reminder reminder, int? nextId) async {
    final db = await isar;
    await db.writeTxn(() async {
      if (nextId != null) await db.reminders.delete(nextId);
      reminder.isCompleted = false;
      await db.reminders.put(reminder);
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
      throw const DataValidationException(
          ValidationCode.recordMissing, 'Service entry no longer exists.');
    }
    await db.writeTxn(() => db.serviceLogs.put(log));
  }

  Future<void> _validateServiceLog(Isar db, ServiceLog log) async {
    final carId = log.carId;
    if (carId == null) {
      throw const DataValidationException(
          ValidationCode.recordWithoutCar, 'Service entry must have a car.');
    }
    await _requireCar(db, carId);
    validateNonNegativeNumber(log.odometer, 'Service odometer');
    log.description = log.description.trim();
    if (meaningfulText(log.description).isEmpty) {
      throw const DataValidationException(ValidationCode.descriptionEmpty,
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
      throw const DataValidationException(
          ValidationCode.recordWithoutCar, 'Note must have a car.');
    }
    await _requireCar(db, carId);
    _validateNote(note);

    await db.writeTxn(() => db.notes.put(note));
  }

  Future<void> updateNote(Note note) async {
    final db = await isar;
    final carId = note.carId;
    if (carId == null) {
      throw const DataValidationException(
          ValidationCode.recordWithoutCar, 'Note must have a car.');
    }
    await _requireCar(db, carId);
    _validateNote(note);
    await db.writeTxn(() => db.notes.put(note));
  }

  void _validateNote(Note note) {
    note.description = note.description.trim();
    if (note.description.isEmpty) {
      throw const DataValidationException(
          ValidationCode.descriptionEmpty, 'Note cannot be empty.');
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
              ValidationCode.periodEndsBeforeStart,
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

  /// Summary of the active database, compared with the cloud copy before
  /// either of them is replaced.
  Future<DatabaseSummary> summarizeLocal() => runExclusive(_summarize);

  /// Opens a downloaded snapshot with the current schemas and summarizes it.
  /// Returns `null` when the file is missing, empty or not a valid database.
  Future<DatabaseSummary?> summarizeSnapshot(String filePath) async {
    final file = File(filePath);
    if (!await file.exists() || await file.length() == 0) return null;

    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    if (!fileName.endsWith('.isar')) return null;
    final databaseName =
        fileName.substring(0, fileName.length - '.isar'.length);
    Isar? checkDb;
    try {
      checkDb = await Isar.open(
        _schemas,
        directory: file.parent.path,
        name: databaseName,
      );
      final summary = await _summarize(checkDb);
      debugPrint('[Database] Snapshot verified: $summary');
      return summary;
    } catch (error) {
      debugPrint('[Database] Snapshot validation failed: $error');
      return null;
    } finally {
      await checkDb?.close();
      final lockFile = File('$filePath.lock');
      if (await lockFile.exists()) await lockFile.delete();
    }
  }

  Future<DatabaseSummary> _summarize(Isar db) async {
    final odometerDates =
        await db.odometerLogs.where().dateStringProperty().findAll();
    final fuelDates = await db.fuelLogs.where().dateStringProperty().findAll();
    String? lastEntryDate;
    for (final date in [...odometerDates, ...fuelDates]) {
      if (lastEntryDate == null || date.compareTo(lastEntryDate) > 0) {
        lastEntryDate = date;
      }
    }
    return DatabaseSummary(
      cars: await db.cars.count(),
      odometerLogs: odometerDates.length,
      fuelLogs: fuelDates.length,
      reminders: await db.reminders.count(),
      serviceLogs: await db.serviceLogs.count(),
      notes: await db.notes.count(),
      lastEntryDate: lastEntryDate,
    );
  }

  /// Replaces the active database with a verified snapshot.
  ///
  /// The current file is first copied to the local backup folder, and the
  /// replacement happens while the database is closed, inside one lifecycle
  /// operation: no other request can read a half-written file. The snapshot
  /// itself must be downloaded and verified before this call, so the closed
  /// window lasts only for the file copy.
  Future<void> replaceWithSnapshot(String snapshotPath) async {
    await isar; // Makes sure the database path is known.
    final targetPath = _databaseFilePath!;
    await withClosedDatabase(() async {
      final target = File(targetPath);
      final previous = File('$targetPath.previous');
      if (await target.exists() && await target.length() > 0) {
        await _copyToBackupFolder(target, tag: 'before-restore');
      }
      if (await previous.exists()) await previous.delete();
      if (await target.exists()) await target.rename(previous.path);
      try {
        await File(snapshotPath).copy(targetPath);
        if (await previous.exists()) await previous.delete();
      } catch (_) {
        if (await target.exists()) await target.delete();
        if (await previous.exists()) await previous.rename(targetPath);
        rethrow;
      }
    });
  }

  /// Creates a compact snapshot for cloud upload without reading the live DB
  /// file while it may still be changing.
  Future<String> createDatabaseSnapshot() async {
    final directory = await _temporaryFolder();
    final snapshot = File(
      '${directory.path}/autoubc_sync_${DateTime.now().microsecondsSinceEpoch}.isar',
    );
    await runExclusive((db) => db.copyToFile(snapshot.path));
    return snapshot.path;
  }

  /// Local backups, newest first.
  Future<List<LocalBackup>> listLocalBackups() async {
    final dir = await _backupDirectory();
    final backups = <LocalBackup>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final parsed = parseLocalBackupName(entity.uri.pathSegments.last);
      if (parsed == null) continue;
      backups.add(LocalBackup(
        path: entity.path,
        time: parsed.time,
        tag: parsed.tag,
        size: await entity.length(),
      ));
    }
    backups.sort((a, b) => b.time.compareTo(a.time));
    return backups;
  }

  /// Copies a local backup to a temporary file, so opening it for a summary
  /// never changes the backup itself.
  Future<String> copyBackupToTemporary(String backupPath) async {
    final target = await temporarySnapshotPath();
    await File(backupPath).copy(target);
    return target;
  }

  /// Path for a temporary file that receives a downloaded cloud snapshot.
  Future<String> temporarySnapshotPath() async {
    final directory = await _temporaryFolder();
    return '${directory.path}/autoubc_cloud_${DateTime.now().microsecondsSinceEpoch}.isar';
  }

  /// Saves a local backup. A [tag] (for example `before-delete`) marks a copy
  /// made before a destructive action; tagged copies have their own quota in
  /// the rotation, so routine backups never push them out.
  Future<void> createAutoLocalBackup({String? tag}) {
    return runExclusive((db) => _createAutoLocalBackup(db, tag: tag));
  }

  Future<Directory> _backupDirectory() async {
    Directory directory;
    if (debugStorageRoot != null) {
      directory = await _storageFolder('documents', getTemporaryDirectory);
    } else if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    final backupDir = Directory('${directory.path}/AutoUBC_Backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  String _backupFileName(DateTime now, String? tag) {
    String two(int value) => value.toString().padLeft(2, '0');
    final suffix = tag == null ? '' : '_$tag';
    return 'autoubc_backup_${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}$suffix.isar';
  }

  Future<void> _createAutoLocalBackup(Isar db, {String? tag}) async {
    try {
      final backupDir = await _backupDirectory();
      final backupFile =
          File('${backupDir.path}/${_backupFileName(DateTime.now(), tag)}');
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

      await _cleanOldBackups(backupDir);
    } catch (e) {
      debugPrint('[Database] Local backup failed: $e');
    }
  }

  /// Copies a closed database file into the backup folder as is.
  Future<void> _copyToBackupFolder(File file, {required String tag}) async {
    try {
      final backupDir = await _backupDirectory();
      await file.copy('${backupDir.path}/${_backupFileName(DateTime.now(), tag)}');
      await _cleanOldBackups(backupDir);
    } catch (e) {
      debugPrint('[Database] Copy before replacement failed: $e');
    }
  }

  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().toList();
      final byName = <String, File>{
        for (final file in files.whereType<File>())
          file.uri.pathSegments.last: file,
      };
      for (final name in localBackupsToDelete(byName.keys)) {
        await byName[name]!.delete();
      }
    } catch (e) {
      debugPrint('[Database] Backup cleanup failed: $e');
    }
  }
}
