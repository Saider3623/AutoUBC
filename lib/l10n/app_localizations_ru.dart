// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get addCar => 'Добавить автомобиль';

  @override
  String get selectCar => 'Выбрать автомобиль';

  @override
  String get deleteCar => 'Удалить текущий автомобиль';

  @override
  String get carSettings => 'Настройки';

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
  String get delete => 'Удалить';

  @override
  String get date => 'Дата';

  @override
  String get odometer => 'Одометр';

  @override
  String get km => 'км';

  @override
  String get fuel => 'Топливо';

  @override
  String get save => 'Сохранить';

  @override
  String get saveOdometerSuccess => 'Показания одометра сохранены';

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
  String get reminderType => 'Тип';

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
  String get fieldRequired => 'Заполните поле';

  @override
  String get invalidWholeNumber => 'Введите целое число';

  @override
  String get invalidNumber => 'Введите корректное число';

  @override
  String get numberMustBeNonNegative => 'Число не может быть отрицательным';

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
  String get carName => 'Название автомобиля';

  @override
  String get carAdded => 'Автомобиль успешно добавлен!';

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
  String get deleteNote => 'Удалить заметку';

  @override
  String get deleteNoteConfirmation =>
      'Вы уверены, что хотите удалить эту заметку?';

  @override
  String get chooseDate => 'Выбрать дату';

  @override
  String get noteDateSelected => 'Дата установлена';

  @override
  String get syncInProgress => 'Синхронизация…';

  @override
  String get syncIdle => 'Синхронизировано';

  @override
  String get syncError => 'Ошибка синхронизации';

  @override
  String get workWeekSection => 'Режим рабочей недели';

  @override
  String get saturdayNotWorkingConfirm =>
      'По графику на эту дату действует 5-дневная неделя, суббота нерабочая. Добавить данные?';

  @override
  String get workWeekScheduleHint =>
      'По умолчанию неделя 6-дневная (Пн–Сб). С даты начала до даты конца действует 5-дневная (Пн–Пт). Воскресенье всегда нерабочее.';

  @override
  String get fiveDayPeriodStart => 'Начало 5-дневной недели';

  @override
  String get fiveDayPeriodEnd => 'Конец 5-дневной недели';

  @override
  String get fiveDayPeriodStartNotSet => 'Не указано — всегда 6-дневная';

  @override
  String get fiveDayPeriodEndHint =>
      'Если конец ещё неизвестен, оставьте пустым и укажите позже, когда руководство решит.';

  @override
  String get fiveDayPeriodOpenEnd => 'До решения руководства';

  @override
  String get fiveDayPeriodSaved => 'График рабочей недели сохранён';

  @override
  String get clearDate => 'Очистить дату';

  @override
  String get cloudConflictTitle => 'В Google Drive другие данные';

  @override
  String get cloudConflictBody =>
      'На телефоне и в Google Drive разные данные. Выберите, какую копию оставить. Вторая копия сохранится как резервная и не пропадёт.';

  @override
  String get cloudRestoreTitle => 'Восстановить из Google Drive?';

  @override
  String get cloudRestoreBody =>
      'Данные на телефоне будут заменены копией из Google Drive. Текущие данные телефона сначала сохранятся в локальную резервную копию.';

  @override
  String get cloudColumnPhone => 'Телефон';

  @override
  String get cloudColumnDrive => 'Google Drive';

  @override
  String get cloudRowCars => 'Автомобили';

  @override
  String get cloudRowOdometer => 'Записи пробега';

  @override
  String get cloudRowFuel => 'Заправки';

  @override
  String get cloudRowOther => 'Другие записи';

  @override
  String get cloudRowLastEntry => 'Последняя запись';

  @override
  String cloudModifiedAt(String date) {
    return 'Копия в Google Drive сохранена $date';
  }

  @override
  String get cloudUseDrive => 'Взять из Google Drive';

  @override
  String get cloudUsePhone => 'Оставить данные телефона';

  @override
  String get cloudDecideLater => 'Позже';

  @override
  String get cloudRestoreAction => 'Восстановить';

  @override
  String get restoreFromDriveMenu => 'Восстановить из Google Drive';

  @override
  String get cloudNoBackup => 'В Google Drive ещё нет копии';

  @override
  String get cloudOperationFailed =>
      'Не удалось связаться с Google Drive. Ничего не изменено. Проверьте подключение и попробуйте ещё раз.';

  @override
  String get cloudRestored => 'Данные восстановлены из Google Drive';

  @override
  String get cloudUploaded => 'Данные телефона сохранены в Google Drive';

  @override
  String get cloudCheckingDrive => 'Проверяем Google Drive…';

  @override
  String get cloudRestoring => 'Восстанавливаем данные…';

  @override
  String get syncNeedsDecision => 'Выберите, какие данные оставить';

  @override
  String get dataLoadErrorTitle => 'Не удалось открыть данные';

  @override
  String get dataLoadErrorBody =>
      'Ваши записи не удалены. Попробуйте ещё раз; если повторится — перезапустите приложение.';

  @override
  String get errorCarNameEmpty => 'Введите название автомобиля.';

  @override
  String get errorCarMissing =>
      'Этого автомобиля больше нет. Откройте экран заново и попробуйте ещё раз.';

  @override
  String get errorRecordMissing => 'Этой записи больше нет.';

  @override
  String get errorFuelTypeEmpty => 'Выберите вид топлива.';

  @override
  String errorOdometerBelowPrevious(int reading, String date) {
    return 'Показание меньше предыдущего: $reading км от $date.';
  }

  @override
  String errorOdometerAboveNext(int reading, String date) {
    return 'Показание больше следующего: $reading км от $date.';
  }

  @override
  String get errorInvalidDate => 'Неверная дата.';

  @override
  String get errorInvalidTime => 'Неверное время.';

  @override
  String get errorPeriodEndsBeforeStart => 'Дата окончания раньше даты начала.';

  @override
  String get errorUnexpected => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String weekDetailTitle(String range) {
    return 'Детализация: $range';
  }

  @override
  String get reminderStartKm => 'Отсчёт от пробега';

  @override
  String get deleteReminderConfirmation => 'Удалить это напоминание?';

  @override
  String get numberMustBePositive => 'Введите число больше нуля';

  @override
  String weeklyReportDistanceText(String distance) {
    return 'Пробег: $distance км';
  }

  @override
  String get monthSummaryTitle => 'ИТОГ МЕСЯЦА';

  @override
  String monthTotalDistance(String distance) {
    return 'Пробег: $distance км';
  }

  @override
  String monthDaysWithoutReading(int days) {
    return 'Рабочих дней без показаний: $days';
  }

  @override
  String weekIncludesGap(String date) {
    return 'Пробег включает дни без показаний с $date';
  }

  @override
  String get editOdometerTitle => 'Изменить показание';

  @override
  String get editRefuelTitle => 'Изменить заправку';

  @override
  String get timeLabel => 'Время';

  @override
  String appVersion(String version, String build) {
    return 'Версия $version ($build)';
  }

  @override
  String get navEntry => 'Ввод';

  @override
  String get navReport => 'Отчёт';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get yesterdayLabel => 'Вчера';

  @override
  String previousReading(String reading, String date) {
    return 'Предыдущее: $reading км, $date';
  }

  @override
  String get readingBelowPrevious => 'Меньше предыдущего показания';

  @override
  String readingAboveNext(String reading, String date) {
    return 'Больше следующего показания: $reading км, $date';
  }

  @override
  String largeJumpConfirm(String distance, int days) {
    return '+$distance км за $days дн. Всё равно сохранить?';
  }

  @override
  String goToDate(String date) {
    return 'Перейти к $date';
  }

  @override
  String missingReadingBanner(String date) {
    return 'Нет показания одометра за $date';
  }

  @override
  String showAllNotes(int count) {
    return 'Все заметки ($count)';
  }

  @override
  String get showFewerNotes => 'Свернуть';

  @override
  String get storageExplanation =>
      'Данные хранятся на телефоне, Google Drive хранит резервную копию.';

  @override
  String get settingsCarSection => 'Автомобиль';

  @override
  String get settingsAppSection => 'Приложение';

  @override
  String get plateNumber => 'Госномер';

  @override
  String get driverName => 'Водитель';

  @override
  String get printedInReport => 'Печатается в PDF-отчёте';

  @override
  String get renameFuelType => 'Переименовать вид топлива';

  @override
  String get renameFuelTypeHint =>
      'Существующие заправки этого автомобиля перейдут на новое название после сохранения.';

  @override
  String fuelTypeExists(String name) {
    return 'Вид топлива $name уже есть';
  }

  @override
  String get discardChangesQuestion => 'Отменить несохранённые изменения?';

  @override
  String get discardChanges => 'Отменить';

  @override
  String deleteCarWillRemove(String carName) {
    return 'Будут удалены «$carName» и все его записи:';
  }

  @override
  String get deleteCarTypeName =>
      'Введите название автомобиля для подтверждения:';

  @override
  String get backupsTitle => 'Резервные копии';

  @override
  String get backupsCloudSection => 'Google Drive';

  @override
  String get backupsLocalSection => 'На телефоне';

  @override
  String get backupsCloudSignedOut =>
      'Войдите в Google Drive, чтобы увидеть его копии';

  @override
  String get backupsLocalEmpty => 'Локальных копий пока нет';

  @override
  String get backupCurrentCloudCopy => 'Текущая копия';

  @override
  String backupDatedCopy(String date) {
    return 'Копия за $date';
  }

  @override
  String get backupAutomatic => 'Автоматическая';

  @override
  String get backupBeforeRestore => 'Перед восстановлением';

  @override
  String get backupBeforeDelete => 'Перед удалением автомобиля';

  @override
  String get backupColumn => 'Копия';

  @override
  String get backupOpenFailed => 'Не удалось открыть эту копию';

  @override
  String get backupRestored => 'Данные восстановлены из копии';

  @override
  String get backupsExplanation =>
      'Перед любым восстановлением текущие данные сохраняются отдельной копией, поэтому восстановление можно отменить из этого списка. Локальные копии удаляются вместе с приложением.';

  @override
  String get syncPanelSignedOut =>
      'Google Drive не подключён. Данные хранятся только на этом телефоне.';

  @override
  String get syncPanelError =>
      'Последняя синхронизация не удалась. Проверьте подключение и попробуйте снова.';

  @override
  String get syncPendingChanges => 'Изменения ждут отправки';

  @override
  String syncLastSuccess(String date) {
    return 'Последняя синхронизация $date';
  }

  @override
  String get syncChooseCopy => 'Выбрать копию';

  @override
  String get syncNow => 'Синхронизировать сейчас';

  @override
  String get notificationChannelDescription =>
      'Сроки страховки, техосмотра и других напоминаний';

  @override
  String notificationDueToday(String date) {
    return 'Срок сегодня, $date';
  }

  @override
  String notificationDueTomorrow(String date) {
    return 'Срок завтра, $date';
  }

  @override
  String notificationDueInWeek(String date) {
    return 'Срок через неделю, $date';
  }

  @override
  String get reminderDueToday => 'Срок сегодня';

  @override
  String reminderDaysLeft(int days) {
    return 'Осталось дней: $days';
  }

  @override
  String reminderDaysOverdue(int days) {
    return 'Просрочено дней: $days';
  }

  @override
  String reminderKmLeft(int km) {
    return 'Осталось $km км';
  }

  @override
  String reminderKmOverdue(int km) {
    return 'Просрочено на $km км';
  }

  @override
  String reminderCompletedMessage(String title) {
    return 'Выполнено: $title';
  }

  @override
  String get undo => 'Отменить';

  @override
  String get serviceBookOfferTitle => 'Записать в сервисную книжку?';

  @override
  String get serviceBookOfferBody =>
      'Добавьте пробег и что было сделано — история обслуживания останется полной.';

  @override
  String get addRecord => 'Добавить запись';

  @override
  String get notNow => 'Не сейчас';

  @override
  String remindersDueMore(int count) {
    return 'ещё $count';
  }

  @override
  String get notificationsDisabledHint =>
      'Уведомления выключены — напоминания по дате не придут.';

  @override
  String get enableNotifications => 'Включить';

  @override
  String get syncProblemOffline =>
      'Нет связи с Google Drive. Копия выгрузится, когда связь появится.';

  @override
  String get syncProblemAccessDenied =>
      'Google не даёт доступа к Drive. Войдите снова и разрешите доступ к Google Drive.';

  @override
  String get syncProblemStorageFull =>
      'В хранилище Google закончилось место, копия не выгружается.';

  @override
  String get syncSignInAgain => 'Войти снова';
}
