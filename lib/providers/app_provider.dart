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

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Car> _cars = [];
  Car? _selectedCar;
  List<OdometerLog> _odometerLogs = [];
  List<FuelLog> _fuelLogs = [];
  List<Reminder> _reminders = [];
  List<ServiceLog> _serviceLogs = [];
  List<Note> _notes = [];
  bool _isLoading = false;
  Future<bool> Function()?
      onDataSaved; // Изменено: теперь возвращает результат синхронизации
  Timer? _backupTimer;
  DateTime? _lastBackupTime;
  bool _needsSync =
      false; // Флаг: нужна ли синхронизация (если предыдущая не удалась)

  List<Car> get cars => _cars;
  Car? get selectedCar => _selectedCar;
  List<OdometerLog> get odometerLogs => _odometerLogs;
  List<FuelLog> get fuelLogs => _fuelLogs;
  List<Reminder> get reminders => _reminders;
  List<ServiceLog> get serviceLogs => _serviceLogs;
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  AppProvider() {
    loadCars();
  }

  // Метод с debounce для запуска бэкапа и синхронизации
  void _scheduleBackupAndSync() {
    // Отменяем предыдущий таймер, если он был
    _backupTimer?.cancel();
    // Запускаем новый таймер на 3 секунды (быстрый debounce)
    _backupTimer = Timer(const Duration(seconds: 3), () async {
      await _performBackupAndSync();
    });
  }

  @override
  void dispose() {
    // Если таймер запущен — запускаем бэкап сразу при закрытии
    if (_backupTimer != null && _backupTimer!.isActive) {
      _backupTimer!.cancel();
      // Запускаем бэкап синхронно при закрытии (без ожидания)
      _performBackupAndSync();
    }
    super.dispose();
  }

  // Основной метод для выполнения бэкапа и синхронизации
  Future<void> _performBackupAndSync() async {
    final now = DateTime.now();
    bool shouldBackup = false;
    bool shouldSync = false;

    // Проверка: нужно ли запускать локальный бэкап
    if (_lastBackupTime == null ||
        now.difference(_lastBackupTime!).inMinutes >= 5) {
      shouldBackup = true;
    }

    // Проверка: нужно ли запускать синхронизацию
    if (_needsSync) {
      shouldSync = true;
    } else if (shouldBackup) {
      shouldSync = true; // Если делаем бэкап, то и синхронизацию тоже
    }

    if (shouldBackup) {
      // Локальный бэкап
      await _db.createAutoLocalBackup();
      _lastBackupTime = DateTime.now();
    }

    if (shouldSync) {
      // Синхронизация с Google Drive
      if (onDataSaved != null) {
        final syncSuccess = await onDataSaved!();
        if (syncSuccess) {
          _needsSync = false; // Синхронизация удалась — сбрасываем флаг
        } else {
          _needsSync =
              true; // Синхронизация не удалась — установим флаг для следующего раза
        }
      }
    }
  }

  Future<void> loadCars() async {
    try {
      _isLoading = true;
      notifyListeners();
      _cars = await _db.getAllCars();
      if (_cars.isNotEmpty && _selectedCar == null) {
        final prefs = await SharedPreferences.getInstance();
        final savedCarId = prefs.getInt('lastSelectedCarId');
        if (savedCarId != null) {
          try {
            _selectedCar = _cars.firstWhere((car) => car.id == savedCarId);
          } catch (_) {
            _selectedCar = _cars.first;
          }
        } else {
          _selectedCar = _cars.first;
        }
        await loadLogsForCar(_selectedCar!.id);
      }
    } catch (e) {
      debugPrint('Помилка завантаження машин: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLogsForCar(int carId) async {
    try {
      _isLoading = true;
      notifyListeners();
      _odometerLogs = await _db.getOdometerLogsForCar(carId);
      _fuelLogs = await _db.getFuelLogsForCar(carId);
      _reminders = await _db.getRemindersForCar(carId);
      _serviceLogs = await _db.getServiceLogsForCar(carId);
      _notes = await _db.getNotesForCar(carId);
    } catch (e) {
      debugPrint('Помилка завантаження логів: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      final car = Car()..name = name;
      await _db.addCar(car);
      await loadCars();
      // После добавления сразу выбираем новый автомобиль
      final newCar = _cars.firstWhere((c) => c.name == name);
      await selectCar(newCar);
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання машини: $e');
      rethrow;
    }
  }

  Future<void> deleteCar(Car car) async {
    try {
      await _db.deleteCar(car);
      if (_selectedCar?.id == car.id) {
        _selectedCar = null;
      }
      await loadCars();
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка видалення машини: $e');
      rethrow;
    }
  }

  Future<void> saveOdometerLog(String dateString, int odometer) async {
    try {
      if (_selectedCar == null) return;
      await _db.saveOdometerLog(_selectedCar!.id, dateString, odometer);
      await loadLogsForCar(_selectedCar!.id);
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка збереження логу пробігу: $e');
      rethrow;
    }
  }

  Future<void> deleteOdometerLog(OdometerLog log) async {
    try {
      await _db.deleteOdometerLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        _scheduleBackupAndSync();
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
      await _db.addFuelLog(
          _selectedCar!.id, dateString, timeString, fuelType, liters);
      await loadLogsForCar(_selectedCar!.id);
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання логу заправки: $e');
      rethrow;
    }
  }

  Future<void> deleteFuelLog(FuelLog log) async {
    try {
      await _db.deleteFuelLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка видалення логу заправки: $e');
      rethrow;
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      if (_selectedCar == null) return;
      await _db.addReminder(reminder);
      await loadLogsForCar(_selectedCar!.id);
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання нагадування: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      await _db.updateReminder(reminder);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка оновлення нагадування: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(Reminder reminder) async {
    try {
      await _db.deleteReminder(reminder);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка видалення нагадування: $e');
      rethrow;
    }
  }

  Future<void> completeReminder(Reminder reminder) async {
    try {
      await _db.completeReminder(reminder);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
        _scheduleBackupAndSync();
      }
    } catch (e) {
      debugPrint('Помилка завершення нагадування: $e');
      rethrow;
    }
  }

  Future<void> updateCar(Car car) async {
    try {
      await _db.updateCar(car);
      await loadCars();
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка оновлення машини: $e');
      rethrow;
    }
  }

  Future<void> addServiceLog(ServiceLog log) async {
    try {
      await _db.addServiceLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання логу обслуговування: $e');
      rethrow;
    }
  }

  Future<void> deleteServiceLog(ServiceLog log) async {
    try {
      await _db.deleteServiceLog(log);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка видалення логу обслуговування: $e');
      rethrow;
    }
  }

  Future<void> addNote(Note note) async {
    try {
      if (_selectedCar == null) return;
      await _db.addNote(note);
      await loadLogsForCar(_selectedCar!.id);
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка додавання нотатки: $e');
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _db.updateNote(note);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка оновлення нотатки: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(Note note) async {
    try {
      await _db.deleteNote(note);
      if (_selectedCar != null) {
        await loadLogsForCar(_selectedCar!.id);
      }
      _scheduleBackupAndSync();
    } catch (e) {
      debugPrint('Помилка видалення нотатки: $e');
      rethrow;
    }
  }

  // Методы для обновления данных при восстановлении из бэкапа
  Future<void> refreshAll() async {
    await loadCars();
  }
}
