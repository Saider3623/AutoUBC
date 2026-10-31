// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

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
  String get delete => 'Видалити';

  @override
  String get date => 'Дата';

  @override
  String get odometer => 'Одометр';

  @override
  String get km => 'км';

  @override
  String get fuel => 'Паливо';

  @override
  String get save => 'Зберегти';

  @override
  String get saveOdometerSuccess => 'Показання одометра збережено';

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
  String get retry => 'Повторити';

  @override
  String get english => 'Англійська';

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
  String get carName => 'Назва автомобіля';

  @override
  String get carAdded => 'Автомобіль успішно додано!';

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
  String get deleteNote => 'Видалити нотатку';

  @override
  String get deleteNoteConfirmation =>
      'Ви впевнені, що хочете видалити цю нотатку?';

  @override
  String get chooseDate => 'Вибрати дату';

  @override
  String get noteDateSelected => 'Дату встановлено';

  @override
  String get syncInProgress => 'Синхронізація…';

  @override
  String get syncIdle => 'Синхронізовано';

  @override
  String get syncError => 'Помилка синхронізації';

  @override
  String get workWeekSection => 'Режим робочого тижня';

  @override
  String get saturdayNotWorkingConfirm =>
      'За графіком на цю дату діє 5-денний тиждень, субота неробоча. Додати дані?';

  @override
  String get workWeekScheduleHint =>
      'За замовчуванням тиждень 6-денний (Пн–Сб). Від дати початку до дати кінця діє 5-денний (Пн–Пт). Неділя завжди неробоча.';

  @override
  String get fiveDayPeriodStart => 'Початок 5-денного тижня';

  @override
  String get fiveDayPeriodEnd => 'Кінець 5-денного тижня';

  @override
  String get fiveDayPeriodStartNotSet => 'Не вказано — завжди 6-денний';

  @override
  String get fiveDayPeriodEndHint =>
      'Якщо кінець ще невідомий, залиште порожнім і вкажіть пізніше, коли керівництво вирішить.';

  @override
  String get fiveDayPeriodOpenEnd => 'До рішення керівництва';

  @override
  String get fiveDayPeriodSaved => 'Графік робочого тижня збережено';

  @override
  String get clearDate => 'Очистити дату';

  @override
  String get cloudConflictTitle => 'У Google Drive інші дані';

  @override
  String get cloudConflictBody =>
      'На телефоні та в Google Drive різні дані. Оберіть, яку копію залишити. Інша копія збережеться як резервна й не зникне.';

  @override
  String get cloudRestoreTitle => 'Відновити з Google Drive?';

  @override
  String get cloudRestoreBody =>
      'Дані на телефоні буде замінено копією з Google Drive. Поточні дані телефону спершу збережуться в локальну резервну копію.';

  @override
  String get cloudColumnPhone => 'Телефон';

  @override
  String get cloudColumnDrive => 'Google Drive';

  @override
  String get cloudRowCars => 'Автомобілі';

  @override
  String get cloudRowOdometer => 'Записи пробігу';

  @override
  String get cloudRowFuel => 'Заправки';

  @override
  String get cloudRowOther => 'Інші записи';

  @override
  String get cloudRowLastEntry => 'Останній запис';

  @override
  String cloudModifiedAt(String date) {
    return 'Копію в Google Drive збережено $date';
  }

  @override
  String get cloudUseDrive => 'Взяти з Google Drive';

  @override
  String get cloudUsePhone => 'Залишити дані телефону';

  @override
  String get cloudDecideLater => 'Пізніше';

  @override
  String get cloudRestoreAction => 'Відновити';

  @override
  String get restoreFromDriveMenu => 'Відновити з Google Drive';

  @override
  String get cloudNoBackup => 'У Google Drive ще немає копії';

  @override
  String get cloudOperationFailed =>
      'Не вдалося зв\'язатися з Google Drive. Нічого не змінено. Перевірте підключення й спробуйте ще раз.';

  @override
  String get cloudRestored => 'Дані відновлено з Google Drive';

  @override
  String get cloudUploaded => 'Дані телефону збережено в Google Drive';

  @override
  String get cloudCheckingDrive => 'Перевіряємо Google Drive…';

  @override
  String get cloudRestoring => 'Відновлюємо дані…';

  @override
  String get syncNeedsDecision => 'Оберіть, які дані залишити';

  @override
  String get dataLoadErrorTitle => 'Не вдалося відкрити дані';

  @override
  String get dataLoadErrorBody =>
      'Ваші записи не видалено. Спробуйте ще раз; якщо повториться — перезапустіть застосунок.';

  @override
  String get errorCarNameEmpty => 'Введіть назву автомобіля.';

  @override
  String get errorCarMissing =>
      'Цього автомобіля вже немає. Відкрийте екран заново й спробуйте ще раз.';

  @override
  String get errorRecordMissing => 'Цього запису вже немає.';

  @override
  String get errorFuelTypeEmpty => 'Оберіть вид пального.';

  @override
  String errorOdometerBelowPrevious(int reading, String date) {
    return 'Показання менше за попереднє: $reading км від $date.';
  }

  @override
  String errorOdometerAboveNext(int reading, String date) {
    return 'Показання більше за наступне: $reading км від $date.';
  }

  @override
  String get errorInvalidDate => 'Неправильна дата.';

  @override
  String get errorInvalidTime => 'Неправильний час.';

  @override
  String get errorPeriodEndsBeforeStart =>
      'Дата завершення раніша за дату початку.';

  @override
  String get errorUnexpected => 'Щось пішло не так. Спробуйте ще раз.';

  @override
  String weekDetailTitle(String range) {
    return 'Деталізація: $range';
  }

  @override
  String get reminderStartKm => 'Відлік від пробігу';

  @override
  String get numberMustBePositive => 'Введіть число, більше за нуль';

  @override
  String weeklyReportDistanceText(String distance) {
    return 'Пробіг: $distance км';
  }

  @override
  String get monthSummaryTitle => 'ПІДСУМОК МІСЯЦЯ';

  @override
  String monthTotalDistance(String distance) {
    return 'Пробіг: $distance км';
  }

  @override
  String monthDaysWithoutReading(int days) {
    return 'Робочих днів без показань: $days';
  }

  @override
  String weekIncludesGap(String date) {
    return 'Пробіг включає дні без показань від $date';
  }

  @override
  String get editOdometerTitle => 'Змінити показання';

  @override
  String get editRefuelTitle => 'Змінити заправку';

  @override
  String get timeLabel => 'Час';

  @override
  String appVersion(String version, String build) {
    return 'Версія $version ($build)';
  }

  @override
  String get navEntry => 'Ввід';

  @override
  String get navReport => 'Звіт';

  @override
  String previousReading(String reading, String date) {
    return 'Попереднє: $reading км, $date';
  }

  @override
  String get readingBelowPrevious => 'Менше за попереднє показання';

  @override
  String readingAboveNext(String reading, String date) {
    return 'Більше за наступне показання: $reading км, $date';
  }

  @override
  String largeJumpConfirm(String distance, int days) {
    return '+$distance км за $days дн. Усе одно зберегти?';
  }

  @override
  String goToDate(String date) {
    return 'Перейти до $date';
  }

  @override
  String missingReadingBanner(String date) {
    return 'Немає показання одометра за $date';
  }

  @override
  String showAllNotes(int count) {
    return 'Усі нотатки ($count)';
  }

  @override
  String get showFewerNotes => 'Згорнути';

  @override
  String get storageExplanation =>
      'Дані зберігаються на телефоні, Google Drive зберігає резервну копію.';

  @override
  String get settingsCarSection => 'Автомобіль';

  @override
  String get settingsAppSection => 'Застосунок';

  @override
  String get plateNumber => 'Держномер';

  @override
  String get driverName => 'Водій';

  @override
  String get printedInReport => 'Друкується в PDF-звіті';

  @override
  String get renameFuelType => 'Перейменувати вид пального';

  @override
  String get renameFuelTypeHint =>
      'Наявні заправки цього автомобіля перейдуть на нову назву після збереження.';

  @override
  String fuelTypeExists(String name) {
    return 'Вид пального $name уже є';
  }

  @override
  String get discardChangesQuestion => 'Скасувати незбережені зміни?';

  @override
  String get discardChanges => 'Скасувати зміни';

  @override
  String deleteCarWillRemove(String carName) {
    return 'Буде видалено «$carName» і всі його записи:';
  }

  @override
  String get deleteCarTypeName => 'Введіть назву автомобіля для підтвердження:';

  @override
  String get backupsTitle => 'Резервні копії';

  @override
  String get backupsCloudSection => 'Google Drive';

  @override
  String get backupsLocalSection => 'На телефоні';

  @override
  String get backupsCloudSignedOut =>
      'Увійдіть у Google Drive, щоб побачити його копії';

  @override
  String get backupsLocalEmpty => 'Локальних копій поки немає';

  @override
  String get backupCurrentCloudCopy => 'Поточна копія';

  @override
  String backupDatedCopy(String date) {
    return 'Копія за $date';
  }

  @override
  String get backupAutomatic => 'Автоматична';

  @override
  String get backupBeforeRestore => 'Перед відновленням';

  @override
  String get backupBeforeDelete => 'Перед видаленням автомобіля';

  @override
  String get backupColumn => 'Копія';

  @override
  String get backupOpenFailed => 'Не вдалося відкрити цю копію';

  @override
  String get backupRestored => 'Дані відновлено з копії';

  @override
  String get backupsExplanation =>
      'Перед будь-яким відновленням поточні дані зберігаються окремою копією, тож відновлення можна скасувати з цього списку. Локальні копії видаляються разом із застосунком.';

  @override
  String get syncPanelSignedOut =>
      'Google Drive не підключено. Дані зберігаються лише на цьому телефоні.';

  @override
  String get syncPanelError =>
      'Остання синхронізація не вдалася. Перевірте підключення й спробуйте знову.';

  @override
  String get syncPendingChanges => 'Зміни чекають на відправлення';

  @override
  String syncLastSuccess(String date) {
    return 'Остання синхронізація $date';
  }

  @override
  String get syncChooseCopy => 'Обрати копію';

  @override
  String get syncNow => 'Синхронізувати зараз';

  @override
  String get notificationChannelDescription =>
      'Терміни страховки, техогляду та інших нагадувань';

  @override
  String notificationDueToday(String date) {
    return 'Термін сьогодні, $date';
  }

  @override
  String notificationDueTomorrow(String date) {
    return 'Термін завтра, $date';
  }

  @override
  String notificationDueInWeek(String date) {
    return 'Термін через тиждень, $date';
  }

  @override
  String get reminderDueToday => 'Термін сьогодні';

  @override
  String reminderDaysLeft(int days) {
    return 'Залишилось днів: $days';
  }

  @override
  String reminderDaysOverdue(int days) {
    return 'Прострочено днів: $days';
  }

  @override
  String reminderKmLeft(int km) {
    return 'Залишилось $km км';
  }

  @override
  String reminderKmOverdue(int km) {
    return 'Прострочено на $km км';
  }

  @override
  String reminderCompletedMessage(String title) {
    return 'Виконано: $title';
  }

  @override
  String get undo => 'Скасувати';

  @override
  String get serviceBookOfferTitle => 'Записати в сервісну книжку?';

  @override
  String get serviceBookOfferBody =>
      'Додайте пробіг і що було зроблено — історія обслуговування залишиться повною.';

  @override
  String get addRecord => 'Додати запис';

  @override
  String get notNow => 'Не зараз';

  @override
  String remindersDueMore(int count) {
    return 'ще $count';
  }

  @override
  String get notificationsDisabledHint =>
      'Сповіщення вимкнено — нагадування за датою не надійдуть.';

  @override
  String get enableNotifications => 'Увімкнути';

  @override
  String get syncProblemOffline =>
      'Немає зв\'язку з Google Drive. Копія вивантажиться, коли з\'явиться зв\'язок.';

  @override
  String get syncProblemAccessDenied =>
      'Google не дає доступу до Drive. Увійдіть знову й дозвольте доступ до Google Drive.';

  @override
  String get syncProblemStorageFull =>
      'У сховищі Google закінчилося місце, копія не вивантажується.';

  @override
  String get syncSignInAgain => 'Увійти знову';

  @override
  String get previewReport => 'Переглянути звіт';

  @override
  String get shareReport => 'Поділитися';

  @override
  String reminderDeletedMessage(String title) {
    return 'Видалено: $title';
  }

  @override
  String get maintenanceResetTitle => 'Відмітити ТО виконаним?';

  @override
  String maintenanceResetBody(int km) {
    return 'Нагадування про ТО буде відмічено виконаним, наступне — на $km км.';
  }

  @override
  String get maintenanceResetBodyOnce =>
      'Нагадування про ТО буде відмічено виконаним.';

  @override
  String get maintenanceResetAction => 'Відмітити';
}
