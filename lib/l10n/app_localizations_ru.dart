// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AutoUBC';

  @override
  String get addCar => 'Добавить автомобиль';

  @override
  String get selectCar => 'Выбрать автомобиль';

  @override
  String get deleteCar => 'Удалить текущий автомобиль';

  @override
  String get carSettings => 'Настройки автомобиля';

  @override
  String get reminders => 'Напоминания';

  @override
  String get serviceBook => 'Сервисная книжка';

  @override
  String get exportReports => 'Экспорт отчетов';

  @override
  String get enterCarName => 'Введите название автомобиля';

  @override
  String get cancel => 'Отмена';

  @override
  String get add => 'Добавить';

  @override
  String deleteConfirmation(String carName) {
    return 'Вы уверены, что хотите удалить автомобиль \"$carName\"? Все связанные записи пробега и заправок также будут удалены.';
  }

  @override
  String get delete => 'Удалить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get enterData => 'Ввод данных';

  @override
  String get historyAndReports => 'История и отчеты';

  @override
  String get date => 'Дата';

  @override
  String get odometer => 'Одометр';

  @override
  String get km => 'км';

  @override
  String get liters => 'л';

  @override
  String get save => 'Сохранить';

  @override
  String get saveOdometerSuccess => 'Показания одометра сохранены';

  @override
  String saveError(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String get refuelingAdded => 'Заправка добавлена';

  @override
  String get addRefueling => 'Добавить заправку';

  @override
  String get customReminder => 'Другое';

  @override
  String get insuranceReminder => 'Страховка';

  @override
  String get maintenanceReminder => 'ТО';

  @override
  String get inspectionReminder => 'Техосмотр';

  @override
  String get reminderTitle => 'Название напоминания';

  @override
  String get reminderCondition => 'Условие';

  @override
  String get byDate => 'По дате';

  @override
  String get byMileage => 'По пробегу';

  @override
  String get repeatEvery => 'Повторять каждые';

  @override
  String get months => 'месяцев';

  @override
  String currentMileage(int mileage) {
    return 'Текущий пробег: $mileage км';
  }

  @override
  String mileage(int current, int due) {
    return 'Пробег: $current / $due км';
  }

  @override
  String get upcoming => 'Скоро';

  @override
  String get overdue => 'Просрочено';

  @override
  String get signInToGoogleDrive => 'Войти в Google Drive';

  @override
  String get signOutFromGoogle => 'Выйти из Google';

  @override
  String get addCarFirst => 'Сначала добавьте автомобиль';

  @override
  String get noReminders => 'Нет напоминаний';

  @override
  String get edit => 'Редактировать';

  @override
  String get addReminder => 'Добавить напоминание';

  @override
  String get addACarToGetStarted => 'Добавьте автомобиль, чтобы начать';

  @override
  String get welcomeToAutoUbc => 'Добро пожаловать в AutoUBC';

  @override
  String get firstLaunchDescription =>
      'Восстановите данные из Google Drive или начните локально без авторизации.';

  @override
  String get restoreFromGoogleDrive => 'Войти и восстановить из Google Drive';

  @override
  String get createCarLocally => 'Создать автомобиль без авторизации';

  @override
  String get connectingToGoogleDrive => 'Подключение к Google Drive…';

  @override
  String get active => 'Активные';

  @override
  String get completed => 'Завершенные';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get selectMonthForReport => 'Выберите месяц для отчета';

  @override
  String get exportToPDF => 'Экспорт в PDF';

  @override
  String exportError(String error) {
    return 'Ошибка при экспорте: $error';
  }

  @override
  String get loading => 'Загрузка…';

  @override
  String get reportLoadError => 'Не удалось загрузить отчет';

  @override
  String get retry => 'Повторить';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get ukrainian => 'Украинский';

  @override
  String get selectACar => 'Выберите автомобиль';

  @override
  String get noServiceLogs => 'Нет записей в сервисной книжке';

  @override
  String get addServiceLog => 'Добавить запись ТО';

  @override
  String get editServiceLog => 'Редактировать запись ТО';

  @override
  String get mileageKm => 'Пробег (км)';

  @override
  String get whatWasDone => 'Что сделано';

  @override
  String get whatWasDoneHint => 'Новая строка — новый пункт';

  @override
  String get confirmDelete => 'Подтвердить удаление';

  @override
  String get deleteServiceLogConfirmation =>
      'Вы уверены, что хотите удалить эту запись?';

  @override
  String get history => 'История';

  @override
  String get weeklyReport => 'Еженедельный отчет';

  @override
  String get selectCarGeneric => 'Выберите автомобиль';

  @override
  String get noRecords => 'Нет записей';

  @override
  String get deleteOdometerLogConfirmation =>
      'Вы уверены, что хотите удалить эту запись пробега?';

  @override
  String get deleteFuelLogConfirmation =>
      'Вы уверены, что хотите удалить эту запись заправки?';

  @override
  String get odometerLabel => 'Одометр';

  @override
  String get kilometers => 'км';

  @override
  String get litersShort => 'л';

  @override
  String get saveTooltip => 'Сохранить';

  @override
  String fuelTypesForCar(String carName) {
    return 'Типы топлива для $carName';
  }

  @override
  String get fuelTypesHint =>
      'Добавьте или удалите типы топлива, используемые этим автомобилем.';

  @override
  String get atLeastOneFuelType => 'Оставьте хотя бы один вид топлива.';

  @override
  String get newFuelTypeHint => 'Новый тип (например, Дизель, 98, Электрика)';

  @override
  String weeklyReportDistance(int distance) {
    return 'Пробег: $distance км';
  }

  @override
  String get weeklyReportNoMileage => 'Без пробега';

  @override
  String get weeklyReportNoActivity => 'Пробег за этот период не зафиксирован';

  @override
  String get odometerSection => 'ОДОМЕТР';

  @override
  String get startLabel => 'Начало';

  @override
  String get endLabel => 'Конец';

  @override
  String get fuelSection => 'ТОПЛИВО';

  @override
  String get noRefuels => 'Нет заправок';

  @override
  String get averageFuelConsumption =>
      'Средний расход топлива (последние 30 дней)';

  @override
  String averageFuelConsumptionFor(String fuelType, String consumption) {
    return '$fuelType: $consumption л/100км';
  }

  @override
  String get primaryFuelType => 'Основной вид топлива';

  @override
  String get selectPrimaryFuelType => 'Выберите основной вид топлива';

  @override
  String get carName => 'Название автомобиля';

  @override
  String get editCar => 'Изменить автомобиль';

  @override
  String get carAdded => 'Автомобиль успешно добавлен!';

  @override
  String get carUpdated => 'Автомобиль успешно обновлен!';

  @override
  String get search => 'Поиск';

  @override
  String get notes => 'Заметки';

  @override
  String get addNote => 'Добавить заметку';

  @override
  String get editNote => 'Редактировать заметку';

  @override
  String get noteDescription => 'Описание';

  @override
  String get noteDateTime => 'Дата и время';

  @override
  String get deleteNote => 'Удалить заметку';

  @override
  String get deleteNoteConfirmation =>
      'Вы уверены, что хотите удалить эту заметку?';

  @override
  String get noNotes => 'Заметок пока нет';

  @override
  String get chooseDate => 'Выбрать дату';

  @override
  String get noteDateSelected => 'Дата установлена';

  @override
  String get syncInProgress => 'Синхронизация…';

  @override
  String get syncError => 'Ошибка синхронизации';

  @override
  String get syncOk => 'Синхронизировано';
}
