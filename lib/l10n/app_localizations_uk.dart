// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'AutoUBC';

  @override
  String get addCar => 'Додати автомобіль';

  @override
  String get selectCar => 'Вибрати автомобіль';

  @override
  String get deleteCar => 'Видалити поточний автомобіль';

  @override
  String get carSettings => 'Налаштування';

  @override
  String get reminders => 'Нагадування';

  @override
  String get serviceBook => 'Сервісна книжка';

  @override
  String get exportReports => 'Експорт звітів';

  @override
  String get enterCarName => 'Назва автомобіля';

  @override
  String get cancel => 'Скасувати';

  @override
  String get add => 'Додати';

  @override
  String deleteConfirmation(String carName) {
    return 'Ви впевнені, що хочете видалити автомобіль \"$carName\"? Усі пов\'язані записи пробігу та заправок також будуть видалені.';
  }

  @override
  String get delete => 'Видалити';

  @override
  String get confirm => 'Підтвердити';

  @override
  String get enterData => 'Введення даних';

  @override
  String get historyAndReports => 'Історія та звіти';

  @override
  String get date => 'Дата';

  @override
  String get odometer => 'Одометр';

  @override
  String get km => 'км';

  @override
  String get liters => 'л';

  @override
  String get save => 'Зберегти';

  @override
  String get saveOdometerSuccess => 'Показання одометра збережено';

  @override
  String saveError(String error) {
    return 'Помилка збереження: $error';
  }

  @override
  String get refuelingAdded => 'Заправку додано';

  @override
  String get addRefueling => 'Додати заправку';

  @override
  String get customReminder => 'Інше';

  @override
  String get insuranceReminder => 'Страхування';

  @override
  String get maintenanceReminder => 'ТО';

  @override
  String get inspectionReminder => 'Техогляд';

  @override
  String get reminderTitle => 'Назва нагадування';

  @override
  String get reminderCondition => 'Умова';

  @override
  String get reminderType => 'Тип';

  @override
  String get byDate => 'По даті';

  @override
  String get byMileage => 'По пробігу';

  @override
  String get repeatEvery => 'Повторювати кожні';

  @override
  String get months => 'міс';

  @override
  String currentMileage(int mileage) {
    return 'Поточний пробіг: $mileage км';
  }

  @override
  String mileage(int current, int due) {
    return 'Пробіг: $current / $due км';
  }

  @override
  String get upcoming => 'Незабаром';

  @override
  String get overdue => 'Протерміновано';

  @override
  String get signInToGoogleDrive => 'Увійти в Google Drive';

  @override
  String get signOutFromGoogle => 'Вийти з Google';

  @override
  String get addCarFirst => 'Спочатку додайте автомобіль';

  @override
  String get noReminders => 'Немає нагадувань';

  @override
  String get edit => 'Редагувати';

  @override
  String get addReminder => 'Додати нагадування';

  @override
  String get addACarToGetStarted => 'Додайте автомобіль, щоб почати';

  @override
  String get welcomeToAutoUbc => 'Вітаємо в AutoUBC';

  @override
  String get firstLaunchDescription =>
      'Відновіть дані з Google Drive або почніть локально без авторизації.';

  @override
  String get restoreFromGoogleDrive => 'Увійти та відновити з Google Drive';

  @override
  String get createCarLocally => 'Створити автомобіль без авторизації';

  @override
  String get connectingToGoogleDrive => 'Підключення до Google Drive…';

  @override
  String get active => 'Активні';

  @override
  String get completed => 'Завершені';

  @override
  String get language => 'Мова';

  @override
  String get selectLanguage => 'Виберіть мову';

  @override
  String get selectMonthForReport => 'Оберіть місяць для звіту';

  @override
  String get exportToPDF => 'Експорт в PDF';

  @override
  String exportError(String error) {
    return 'Помилка при експорті: $error';
  }

  @override
  String get loading => 'Завантаження…';

  @override
  String get fieldRequired => 'Заповніть поле';

  @override
  String get invalidWholeNumber => 'Введіть ціле число';

  @override
  String get invalidNumber => 'Введіть коректне число';

  @override
  String get numberMustBeNonNegative => 'Число не може бути від’ємним';

  @override
  String get reportLoadError => 'Не вдалося завантажити звіт';

  @override
  String get retry => 'Повторити';

  @override
  String get english => 'Англійська';

  @override
  String get russian => 'Російська';

  @override
  String get ukrainian => 'Українська';

  @override
  String get selectACar => 'Оберіть автомобіль';

  @override
  String get noServiceLogs => 'Немає записів у сервісній книжці';

  @override
  String get addServiceLog => 'Додати запис ТО';

  @override
  String get editServiceLog => 'Редагувати запис ТО';

  @override
  String get mileageKm => 'Пробіг (км)';

  @override
  String get whatWasDone => 'Що зроблено';

  @override
  String get whatWasDoneHint => 'Новий рядок — новий пункт';

  @override
  String get confirmDelete => 'Підтвердіть видалення';

  @override
  String get deleteServiceLogConfirmation =>
      'Ви впевнені, що хочете видалити цей запис?';

  @override
  String get history => 'Історія';

  @override
  String get weeklyReport => 'Тижневий звіт';

  @override
  String get selectCarGeneric => 'Виберіть автомобіль';

  @override
  String get noRecords => 'Немає записів';

  @override
  String get deleteOdometerLogConfirmation =>
      'Ви впевнені, що хочете видалити цей запис пробігу?';

  @override
  String get deleteFuelLogConfirmation =>
      'Ви впевнені, що хочете видалити цей запис заправки?';

  @override
  String get odometerLabel => 'Одометр';

  @override
  String get kilometers => 'км';

  @override
  String get litersShort => 'л';

  @override
  String get saveTooltip => 'Зберегти';

  @override
  String fuelTypesForCar(String carName) {
    return 'Типи пального для $carName';
  }

  @override
  String get fuelTypesHint =>
      'Додайте або видаліть типи пального, які використовує цей автомобіль.';

  @override
  String get atLeastOneFuelType => 'Залиште хоча б один тип пального.';

  @override
  String get newFuelTypeHint => 'Новий тип (напр., Дизель, 98, Електрика)';

  @override
  String weeklyReportDistance(int distance) {
    return 'Пробіг: $distance км';
  }

  @override
  String get weeklyReportNoMileage => 'Без пробігу';

  @override
  String get weeklyReportNoActivity => 'Пробіг за цей період не зафіксований';

  @override
  String get odometerSection => 'ОДОМЕТР';

  @override
  String get startLabel => 'Початок';

  @override
  String get endLabel => 'Кінець';

  @override
  String get fuelSection => 'ПАЛИВО';

  @override
  String get noRefuels => 'Немає заправок';

  @override
  String get averageFuelConsumption =>
      'Середня витрата пального (останні 30 днів)';

  @override
  String averageFuelConsumptionFor(String fuelType, String consumption) {
    return '$fuelType: $consumption л/100км';
  }

  @override
  String get primaryFuelType => 'Основной вид пального';

  @override
  String get selectPrimaryFuelType => 'Виберіть основний вид пального';

  @override
  String get carName => 'Назва автомобіля';

  @override
  String get editCar => 'Редагувати автомобіль';

  @override
  String get carAdded => 'Автомобіль успішно додано!';

  @override
  String get carUpdated => 'Автомобіль успішно оновлено!';

  @override
  String get search => 'Пошук';

  @override
  String get notes => 'Нотатки';

  @override
  String get addNote => 'Додати нотатку';

  @override
  String get editNote => 'Редагувати нотатку';

  @override
  String get noteDescription => 'Опис';

  @override
  String get noteDateTime => 'Дата та час';

  @override
  String get deleteNote => 'Видалити нотатку';

  @override
  String get deleteNoteConfirmation =>
      'Ви впевнені, що хочете видалити цю нотатку?';

  @override
  String get noNotes => 'Нотаток ще немає';

  @override
  String get chooseDate => 'Вибрати дату';

  @override
  String get noteDateSelected => 'Дату встановлено';

  @override
  String get syncInProgress => 'Синхронізація…';

  @override
  String get syncUnknown => 'Синхронізацію ще не виконано';

  @override
  String get syncIdle => 'Синхронізовано';

  @override
  String get syncError => 'Помилка синхронізації';

  @override
  String get syncOk => 'Синхронізовано';

  @override
  String get workWeekSection => 'Режим робочого тижня';

  @override
  String get saturdayNotWorkingConfirm =>
      'За графіком на цю дату діє 5-денний тиждень, субота неробоча. Додати дані?';

  @override
  String get workWeekScheduleHint =>
      'За замовчуванням тиждень 6-денний (Пн–Сб). У вказані періоди діє 5-денний (Пн–Пт). Неділя завжди неробоча.';

  @override
  String get fiveDayPeriodsEmpty =>
      'Періодів 5-денного тижня немає — весь час діє 6-денний.';

  @override
  String get addFiveDayPeriod => 'Додати період 5-денного тижня';

  @override
  String get editFiveDayPeriod => 'Період 5-денного тижня';

  @override
  String get fiveDayPeriodStart => 'Початок';

  @override
  String get fiveDayPeriodEnd => 'Кінець';

  @override
  String get fiveDayPeriodEndNotSet => 'Не вказано';

  @override
  String get fiveDayPeriodEndHint =>
      'Якщо кінець ще невідомий, залиште порожнім і вкажіть пізніше, коли керівництво вирішить.';

  @override
  String get fiveDayPeriodOpenEnd => 'до рішення керівництва';

  @override
  String get fiveDayPeriodActive => 'Діє зараз';

  @override
  String get fiveDayPeriodEndBeforeStart =>
      'Кінець не може бути раніше за початок.';

  @override
  String fiveDayPeriodOverlap(String period) {
    return 'Період перетинається з іншим: $period.';
  }

  @override
  String deleteFiveDayPeriodConfirm(String period) {
    return 'Видалити період $period? Тижні цих дат у звітах рахуватимуться як 6-денні.';
  }

  @override
  String get fiveDayPeriodSaved => 'Графік робочого тижня збережено';

  @override
  String get clearDate => 'Очистити дату';
}
