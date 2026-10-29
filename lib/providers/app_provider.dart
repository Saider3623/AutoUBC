import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_service.dart';
import '../models/car.dart';
import '../models/odometer_log.dart';
import '../models/fuel_log.dart';
import '../models/reminder.dart';
import '../models/service_log.dart';
import '../models/note.dart';
import '../models/five_day_period.dart';
import '../utils/work_schedule.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Car> _cars = [];
  Car? _selectedCar;
  List<OdometerLog> _odometerLogs = [];
  List<FuelLog> _fuelLogs = [];
  List<Reminder> _reminders = [];
  List<ServiceLog> _serviceLogs = [];
  List<Note> _notes = [];
  List<FiveDayPeriod> _fiveDayPeriods = [];
  WorkSchedule _workSchedule = const WorkSchedule();
  bool _isLoading = false;
  Object? _loadError;

  /// Uploads the local database; set by `CloudSyncController`. Returns whether
  /// the cloud copy now matches the local data.
  Future<bool> Function()? onDataSaved;

  /// Delay between the last local change and the upload, so a burst of edits
  /// produces one upload instead of one per edit.
  static Duration syncDelay = const Duration(seconds: 30);
  Timer? _syncTimer;
  DateTime? _lastBackupTime;
  bool _needsSync = false;
  int _pendingRevision = 0;
  static const _pendingSyncKey = 'autoubc_pending_sync';
  bool _disposed = false;
  Future<void> _syncQueue = Future<void>.value();
  Future<void> _persistenceQueue = Future<void>.value();
  late final Future<void> _initialization;
  Future<void>? _loadCarsFuture;

  Future<void> get initialization => _initialization;

  List<Car> get cars => _cars;
  Car? get selectedCar => _selectedCar;
  List<OdometerLog> get odometerLogs => _odometerLogs;
  List<FuelLog> get fuelLogs => _fuelLogs;
  List<Reminder> get reminders => _reminders;
  List<ServiceLog> get serviceLogs => _serviceLogs;
  List<Note> get notes => _notes;

  /// The app-wide five-day period, or `null` when every week has six days.
  FiveDayPeriod? get fiveDayPeriod =>
      _fiveDayPeriods.isEmpty ? null : _fiveDayPeriods.first;

  /// Working-week schedule used by the weekly report, PDF and data entry.
  WorkSchedule get workSchedule => _workSchedule;
  bool get isLoading => _isLoading;

  /// The error of the last failed attempt to open the local database. While
  /// it is set, the empty car list does not mean that there is no data.
  Object? get loadError => _loadError;
  bool get hasPendingSync => _needsSync;

  /// Counter of local changes; lets a sync that started earlier know whether
  /// newer changes arrived while it was running.
  int get pendingRevision => _pendingRevision;

  void _setPendingSync(bool pending) {
    if (_needsSync == pending) return;
    // Pending state is durable sync bookkeeping, not display state. Do not
    // notify the widget tree when a background upload starts or finishes.
    _needsSync = pending;
  }

  AppProvider() {
    _initialization = _loadPendingSync().then((_) => loadCars());
  }

  Future<void> _loadPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    _needsSync = prefs.getBool(_pendingSyncKey) ?? false;
  }

  Future<void> _persistPendingSync() {
    final pending = _needsSync;
    final operation = _persistenceQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pendingSyncKey, pending);
    });
    _persistenceQueue = operation.then<void>((_) {}, onError: (_, __) {});
    return operation;
  }

  /// Clears the pending marker. With [revision], the marker is kept when
  /// local changes were made after that revision was read.
  Future<void> markSyncCompleted({int? revision}) async {
    if (revision != null && revision != _pendingRevision) return;
    _syncTimer?.cancel();
    _setPendingSync(false);
    await _persistPendingSync();
  }

  /// Persists the durable marker before a local mutation starts. If the
  /// process is killed during the database transaction, the next launch still
  /// knows that the local database must be considered for upload.
  Future<void> _markLocalMutationPending() async {
    _pendingRevision++;
    _setPendingSync(true);
    await _persistPendingSync();
  }

  /// Schedules the local backup and the upload after a local write. Every new
  /// write restarts the delay; leaving the app flushes at once.
  Future<void> _scheduleBackupAndSync() async {
    // The marker is normally written before the mutation. Keep this fallback
    // for any future mutation path that only schedules a sync.
    if (!_needsSync) {
      await _markLocalMutationPending();
    }
    if (_disposed) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(syncDelay, () => unawaited(_performBackupAndSync()));
  }

  @override
  void dispose() {
    // `dispose` cannot reliably await a network request. An async flush here
    // could also access an already disposed notifier.
    _disposed = true;
    _syncTimer?.cancel();
    onDataSaved = null;
    super.dispose();
  }

  /// Immediately flushes pending local changes to Google Drive when possible.
  /// Used when the app goes to the background and before signing out.
  Future<bool> flushPendingSync() async {
    // A lifecycle transition is not itself a data change. Avoid creating and
    // uploading a snapshot when the local state is already synchronized.
    if (!_needsSync) return true;

    _syncTimer?.cancel();
    _pendingRevision++;
    await _persistPendingSync();
    await _performBackupAndSync(force: true);
    return !_needsSync;
  }

  // Main entry point for backup and synchronization.
  Future<void> _performBackupAndSync({bool force = false}) {
    final operation = _syncQueue.then(
      (_) => _performBackupAndSyncInternal(force: force),
    );
    _syncQueue = operation.then<void>((_) {}, onError: (_, __) {});
    return operation;
  }

  Future<void> _performBackupAndSyncInternal({bool force = false}) async {
    if (_disposed) return;
    final now = DateTime.now();
    bool shouldBackup = force;
    bool shouldSync = force;

    // Check whether a local backup should run.
    if (_lastBackupTime == null ||
        now.difference(_lastBackupTime!).inMinutes >= 5) {
      shouldBackup = true;
    }

    // Upload only when there is something new to upload.
    if (_needsSync) shouldSync = true;

    if (shouldBackup) {
      // Local backup.
      await _db.createAutoLocalBackup();
      _lastBackupTime = DateTime.now();
    }

    if (shouldSync) {
      // Synchronization with Google Drive.
      final revisionAtStart = _pendingRevision;
      if (onDataSaved != null) {
        try {
          final syncSuccess = await onDataSaved!();
          final hasNewerLocalChanges = revisionAtStart != _pendingRevision;
          _setPendingSync(!syncSuccess || hasNewerLocalChanges);
          await _persistPendingSync();
        } catch (error, stackTrace) {
          _setPendingSync(true);
          await _persistPendingSync();
          debugPrint('[Sync] Upload after a local change failed: $error');
          debugPrint('$stackTrace');
        }
      } else {
        _setPendingSync(true);
        await _persistPendingSync();
      }
    }
  }

  Future<void> loadCars() {
    final current = _loadCarsFuture;
    if (current != null) {
      return current;
    }

    final future = _loadCarsInternal();
    _loadCarsFuture = future;
    return future.whenComplete(() {
      if (identical(_loadCarsFuture, future)) _loadCarsFuture = null;
    });
  }

  Future<void> _loadCarsInternal() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _loadFiveDayPeriods();
      _cars = await _db.getAllCars();
      _loadError = null;
      if (_cars.isEmpty) {
        _selectedCar = null;
        _odometerLogs = [];
        _fuelLogs = [];
        _reminders = [];
        _serviceLogs = [];
        _notes = [];
      } else {
        final selectedId = _selectedCar?.id;
        final selectedStillExists =
            selectedId != null && _cars.any((car) => car.id == selectedId);
        if (!selectedStillExists) {
          final prefs = await SharedPreferences.getInstance();
          final savedCarId = prefs.getInt('lastSelectedCarId');
          _selectedCar = _cars.firstWhere(
            (car) => car.id == savedCarId,
            orElse: () => _cars.first,
          );
        } else {
          _selectedCar = _cars.firstWhere((car) => car.id == selectedId);
        }
        await loadLogsForCar(_selectedCar!.id);
      }
    } catch (e, stackTrace) {
      _loadError = e;
      debugPrint('[Data] Loading cars failed: $e');
      debugPrint('$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads the working-week schedule. Failures keep the previous schedule
  /// so the reports still open with the last known periods.
  Future<void> _loadFiveDayPeriods() async {
    try {
      _fiveDayPeriods = await _db.getFiveDayPeriods();
      // Only one period is used; older builds could store several.
      _workSchedule = WorkSchedule.fromPeriods(_fiveDayPeriods.take(1));
    } catch (e, stackTrace) {
      debugPrint('Помилка завантаження графіка робочого тижня: $e');
      debugPrint('$stackTrace');
    }
  }

  int _logsRequest = 0;

  Future<void> loadLogsForCar(int carId) async {
    // Only the newest request may publish its lists: switching cars quickly
    // must never show the readings of one car next to the notes of another.
    final request = ++_logsRequest;
    try {
      _isLoading = true;
      notifyListeners();
      final odometerLogs = await _db.getOdometerLogsForCar(carId);
      final fuelLogs = await _db.getFuelLogsForCar(carId);
      final reminders = await _db.getRemindersForCar(carId);
      final serviceLogs = await _db.getServiceLogsForCar(carId);
      final notes = await _db.getNotesForCar(carId);
      if (request != _logsRequest) return;
      _odometerLogs = odometerLogs;
      _fuelLogs = fuelLogs;
      _reminders = reminders;
      _serviceLogs = serviceLogs;
      _notes = notes;
    } catch (e) {
      debugPrint('[Data] Loading records failed: $e');
    } finally {
      if (request == _logsRequest) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectCar(Car car) async {
    try {
      _selectedCar = car;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSelectedCarId', car.id);
      await loadLogsForCar(car.id);
    } catch (e) {
      debugPrint('Помилка вибору машини: $e');
    }
  }

  Future<void> addCar(String name) async {
    try {
      await _markLocalMutationPending();
      final car = Car()..name = name;
      final savedCar = await _db.addCar(car);
      await loadCars();
      // Select by the persisted Isar id, not by a non-unique name.
      final newCar =
          _cars.firstWhere((candidate) => candidate.id == savedCar.id);
      await selectCar(newCar);
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання машини: $e');
      rethrow;
    }
  }

  Future<void> deleteCar(Car car) async {
    try {
      // Keep a local copy of the car and all its records before deleting.
      await _db.createAutoLocalBackup(tag: 'before-delete');
      await _markLocalMutationPending();
      await _db.deleteCar(car);
      if (_selectedCar?.id == car.id) {
        _selectedCar = null;
      }
      await loadCars();
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка видалення машини: $e');
      rethrow;
    }
  }

  Future<void> saveOdometerLog(String dateString, int odometer) async {
    try {
      if (_selectedCar == null) return;
      await _markLocalMutationPending();
      await _db.saveOdometerLog(_selectedCar!.id, dateString, odometer);
      await loadLogsForCar(_selectedCar!.id);
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка збереження логу пробігу: $e');
      rethrow;
    }
  }

  Future<void> deleteOdometerLog(OdometerLog log) async {
    try {
      await _markLocalMutationPending();
      await _db.deleteOdometerLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        await _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка видалення логу пробігу: $e');
      rethrow;
    }
  }

  Future<void> addFuelLog(String dateString, String timeString, String fuelType,
      double liters) async {
    try {
      if (_selectedCar == null) return;
      await _markLocalMutationPending();
      await _db.addFuelLog(
          _selectedCar!.id, dateString, timeString, fuelType, liters);
      await loadLogsForCar(_selectedCar!.id);
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання логу заправки: $e');
      rethrow;
    }
  }

  Future<void> updateFuelLog(FuelLog log) async {
    try {
      await _markLocalMutationPending();
      await _db.updateFuelLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        await _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('[Data] Updating a refuel failed: $e');
      rethrow;
    }
  }

  Future<void> deleteFuelLog(FuelLog log) async {
    try {
      await _markLocalMutationPending();
      await _db.deleteFuelLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        await _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка видалення логу заправки: $e');
      rethrow;
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      if (_selectedCar == null) return;
      await _markLocalMutationPending();
      await _db.addReminder(reminder);
      await loadLogsForCar(_selectedCar!.id);
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання нагадування: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _markLocalMutationPending();
      await _db.updateReminder(reminder);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        await _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка оновлення нагадування: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(Reminder reminder) async {
    try {
      await _markLocalMutationPending();
      await _db.deleteReminder(reminder);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        await _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка видалення нагадування: $e');
      rethrow;
    }
  }

  Future<void> completeReminder(Reminder reminder) async {
    try {
      await _markLocalMutationPending();
      await _db.completeReminder(reminder);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        await _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка завершення нагадування: $e');
      rethrow;
    }
  }

  Future<void> updateCar(Car car) async {
    try {
      await _markLocalMutationPending();
      if (car.fuelTypes == null || car.fuelTypes!.isEmpty) {
        car.fuelTypes = ['ГАЗ', '95'];
      }
      await _db.updateCar(car);
      await loadCars();
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка оновлення машини: $e');
      rethrow;
    }
  }

  Future<void> addServiceLog(ServiceLog log) async {
    try {
      await _markLocalMutationPending();
      await _db.addServiceLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання логу обслуговування: $e');
      rethrow;
    }
  }

  Future<void> updateServiceLog(ServiceLog log) async {
    try {
      await _markLocalMutationPending();
      await _db.updateServiceLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка оновлення логу обслуговування: $e');
      rethrow;
    }
  }

  Future<void> deleteServiceLog(ServiceLog log) async {
    try {
      await _markLocalMutationPending();
      await _db.deleteServiceLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка видалення логу обслуговування: $e');
      rethrow;
    }
  }

  Future<void> addNote(Note note) async {
    try {
      if (_selectedCar == null) return;
      await _markLocalMutationPending();
      await _db.addNote(note);
      await loadLogsForCar(_selectedCar!.id);
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання нотатки: $e');
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _markLocalMutationPending();
      await _db.updateNote(note);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка оновлення нотатки: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      await _markLocalMutationPending();
      await _db.deleteNote(note);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка видалення нотатки: $e');
      rethrow;
    }
  }

  /// Sets the five-day period ([startDate]..[endDate], `YYYY-MM-DD`). A `null`
  /// [startDate] removes it; a `null` [endDate] keeps the period open-ended.
  Future<void> setFiveDayPeriod(String? startDate, String? endDate) async {
    try {
      await _markLocalMutationPending();
      await _db.setFiveDayPeriod(startDate, endDate);
      await _loadFiveDayPeriods();
      notifyListeners();
      await _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка збереження періоду 5-денного тижня: $e');
      rethrow;
    }
  }

  // Refresh all in-memory data after restoring a backup.
  Future<void> refreshAll() async {
    await loadCars();
  }
}
