# AutoUBC UI/UX Refactor - Implementation Plan

## Task 1: Сократить вкладки главного экрана до 2 (убрать Историю по дням)
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - В `main.dart`: установить `_totalPages = 2`.
  - В `_getRealIndex` и `itemBuilder` switch: убрать case для `HistoryScreen`; case 0 → DataEntry, case 1 → WeeklyReport.
  - Удалить импорт `history_screen.dart`.
  - Индикаторы страниц внизу теперь будут рендерить только 2 точки.
- **Acceptance Criteria Addressed**: AC-1
- **Test Requirements**:
  - `rule` TR-1.1: В `main.dart` `_totalPages == 2`, switch `itemBuilder` не упоминает `HistoryScreen`. Evidence: чтение файла — [main.dart L146](file:///c:/Projects/AutoUBC/lib/main.dart#L146-L146), [main.dart L455-L465](file:///c:/Projects/AutoUBC/lib/main.dart#L455-L465) — pass.
  - `rule` TR-1.2: В `PageView.builder` доступны только две страницы и в нижних индикаторах `List.generate(_totalPages, ...)` даёт 2 элемента. Evidence: кодовая инспекция `List.generate(_totalPages, ...)` + `_totalPages=2` — pass.
- **Notes**: `history_screen.dart` оставлен в проекте как референс.
- **Completion Evidence**:
  - [main.dart L11](file:///c:/Projects/AutoUBC/lib/main.dart#L11-L11) — импорт `history_screen.dart` удалён.
  - [main.dart L146](file:///c:/Projects/AutoUBC/lib/main.dart#L146-L146) — `_totalPages = 2`.
  - [main.dart L457-L464](file:///c:/Projects/AutoUBC/lib/main.dart#L457-L464) — только case 0:DataEntry, case 1:WeeklyReport.
  - `flutter analyze --no-pub` exit code 0.

## Task 2: Создать экран детализации недели (WeekDetailScreen)
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - Создать `screens/week_detail_screen.dart`.
  - Входные параметры (через конструктор): `DateTime weekStart`, `DateTime weekEnd`; (опционально) предрассчитанная неделя, как в weekly_report.
  - AppBar: заголовок вида «Детализация: 7 - 13 сентября» (форматировать DateFormat, используя LocaleProvider/languageCode).
  - Тело: из AppProvider взять `odometerLogs` и `fuelLogs` выбранного авто, отфильтровать по `weekStart..weekEnd` (по `dateString` → parse).
  - Сортировка и группировка по датам, как в `HistoryScreen`: сначала дата, потом Odometr/FuelLog-строки с иконками.
  - Для каждой записи показать delete-кнопку; при нажатии вызвать `_confirmDeleteOdometer` / `_confirmDeleteFuel` (переиспользовать логику подтверждения из HistoryScreen: `AlertDialog` → подтверждённый вызов `AppProvider.deleteOdometerLog` / `deleteFuelLog`).
  - Пустое состояние: использовать `AppEmptyState` с иконкой `Icons.history` и локализованным `loc.noRecords`.
- **Acceptance Criteria Addressed**: AC-2, AC-3
- **Test Requirements**:
  - `rule` TR-2.1: Экран фильтрует логи по диапазону дат и показывает не более тех, чья дата ∈ [weekStart, weekEnd]. Evidence: [week_detail_screen.dart L63-L77](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart#L63-L77) фильтр `isBefore/start + isAfter/end` — pass.
  - `rule` TR-2.2: Нажатие иконки удаления у OdometerLog → `AppProvider.deleteOdometerLog` вызывается после подтверждения; у FuelLog → `deleteFuelLog`. Evidence: [week_detail_screen.dart L191-L212](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart#L191-L212) — pass.
  - `rubric` TR-2.3: Удобство чтения списка; scale 1-3; anchors 1=нет группировки, 2=группировка но нет сортировки, 3=даты группируются и внутри записи читаемы (одометр, топливо с цветом); threshold >=3. Evidence: [week_detail_screen.dart L79-L179](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart#L79-L179) группировка `groupedLogs` + отформатированные строки с цветом для ГАЗ/95 — Score 3, pass.
- **Completion Evidence**:
  - Файл [week_detail_screen.dart](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart) создан, содержит WeekDetailScreen stateful widget.
  - AppBar с `Деталізація: ...` ([L49](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart#L49-L49)).
  - `GetDiagnostics` clean; no info/warnings.

## Task 3: Сделать карточки недели кликабельными и навигировать в WeekDetailScreen
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 2
- **Description**:
  - В `weekly_report_screen.dart`: импортировать `week_detail_screen.dart`.
  - В `_buildWeeklyReportCard` (и, при желании для консистентности, в `_buildFutureWeekCard`, `_buildErrorWeekCard`, `_buildLoadingWeekCard`) обернуть `Card` в `InkWell` с `onTap`.
  - В onTap вызывать `Navigator.push(context, MaterialPageRoute(builder: (_) => WeekDetailScreen(weekStart: week['start']!, weekEnd: week['end']!)))`.
  - После возврата (`await Navigator.push(...)`) вызвать `setState(() {})`, чтобы `FutureBuilder` карточки пересчитал отчёт заново — реализует автопересчёт (AC-4).
  - Убедиться, что splash-эффект InkWell работает и не ломает скругления (использовать `borderRadius: BorderRadius.circular(20)`, совпадающий с Card.shape).
- **Acceptance Criteria Addressed**: AC-2, AC-4
- **Test Requirements**:
  - `rule` TR-3.1: Карточка прошедшей/текущей недели вызывает переход в WeekDetailScreen. Evidence: [weekly_report_screen.dart L43-L55](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L43-L55) `_wrapClickable` + `_onWeekTap` вызывает `Navigator.push` — pass.
  - `rule` TR-3.2: После удаления записи в детализации и возврата значения карточки (пробег/литры) обновляются. Evidence: [weekly_report_screen.dart L30-L41](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L30-L41) `await push → setState` триггерит перезапуск `FutureBuilder` — pass.
- **Completion Evidence**:
  - [weekly_report_screen.dart L12](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L12-L12) импорт WeekDetailScreen добавлен.
  - [weekly_report_screen.dart L121-L183](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L121-L183) все 4 случая карточек обёрнуты в `_wrapClickable` с правильными borderRadius (16/20).
  - `flutter analyze --no-pub` exit code 0.

## Task 4: Исправить валидацию и сброс поля «Литры» после успешного добавления
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - В `data_entry_screen.dart` (секция Fuel, `_fuelFormKey`, `_litersController`):
    1. После успешного `provider.addFuelLog(...)` и перед `_litersController.clear()` выполнить `FocusScope.of(context).unfocus()` — снять фокус с поля ввода.
    2. После очистки контроллера сбросить состояние формы без валидации: `_fuelFormKey.currentState?.reset()` вместо полагания на Autovalidate, чтобы пустое поле не триггерило ошибку.
    3. Альтернативно/дополнительно: вместо `AutovalidateMode.onUserInteraction` использовать режим `disabled`, и запускать `_fuelFormKey.currentState?.validate()` только в onPressed «+» (как и сейчас), но при очистке поля явно `reset()`.
  - Убедиться, что валидация срабатывает ТОЛЬКО при нажатии «+» на пустом поле, а не при программном clear() после успеха.
- **Acceptance Criteria Addressed**: AC-5, AC-6
- **Test Requirements**:
  - `rule` TR-4.1: При submit пустого поля «Литры» → отображается ошибка + красная рамка. Evidence: [data_entry_screen.dart L348-L352](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L348-L352) явный `.validate()` только в onPressed «+», `AutovalidateMode.disabled` — pass.
  - `rule` TR-4.2: Ввести «10», нажать «+» → показан SnackBar успеха, поле очищено, рамка серая (не красная), фокус ушёл. Evidence: [data_entry_screen.dart L381-L392](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L381-L392) порядок `unfocus → reset → clear → setState` — pass.
- **Completion Evidence**:
  - [data_entry_screen.dart L314](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L314-L314) `AutovalidateMode.disabled`.
  - [data_entry_screen.dart L382-L387](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L382-L387) `FocusScope.of(context).unfocus()` + `_fuelFormKey.currentState?.reset()` перед `.clear()`.

## Task 5: Центрировать кнопки (чипы) выбора вида топлива
- **Status**: `completed`
- **Priority**: medium
- **Depends On**: None
- **Description**:
  - В `data_entry_screen.dart`, секция fuel-типов:
    - Текущий `Wrap` внутри `Column` с `crossAxisAlignment: CrossAxisAlignment.stretch`.
    - Добавить `alignment: WrapAlignment.center` к `Wrap`; либо обернуть `Wrap` в `Center`/`Align(alignment: Alignment.center)`.
    - Проверить, что при 2 типах (`ГАЗ`, `95`) они центрируются относительно поля литров под ними; при 3+ типах перенос на следующую строку также центрирован.
- **Acceptance Criteria Addressed**: AC-7
- **Test Requirements**:
  - `rubric` TR-5.1: Выравнивание; scale 1-3; anchors 1=слева, 2=неявно, 3=строго по центру; threshold >=3. Evidence: [data_entry_screen.dart L254-L257](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L254-L257) `Wrap(alignment: WrapAlignment.center, ...)` — Score 3, pass.
- **Completion Evidence**:
  - [data_entry_screen.dart L254-L255](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L254-L255) `alignment: WrapAlignment.center` добавлен к Wrap с топливными кнопками.

## Task 6: Переработать логику индикатора синхронизации (3 состояния: скрыто/зелёный 2с/красный постоянно)
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - В `widgets/sync_status_indicator.dart`:
    - Преобразовать в `StatefulWidget` (т.к. нужен таймер на 2 сек после успеха).
    - Добавить поле `_showSuccess` (bool) и `Timer? _successTimer`.
    - Логика отображения:
      - Если статус `SyncStatus.error` → всегда показывать красный индикатор (без таймера).
      - Если статус `SyncStatus.syncing` → показывать синий/«syncing»-индикатор (как сейчас).
      - Если статус перешёл в `SyncStatus.idle` (успешная синхронизация):
        * Установить `_showSuccess = true`, отменить старый таймер, запустить новый на 2 сек, после чего `_showSuccess = false` (если нет ошибки).
        * В этот интервал показывать зелёный индикатор.
      - Если `SyncStatus.idle` и нет `_showSuccess` → `return SizedBox.shrink()` (индикатор скрыт), т.е. нейтральное состояние полностью скрыто.
      - Если `SyncStatus.unknown` → также скрывать (`SizedBox.shrink`), согласно «нейтральное состояние скрыто».
    - Подписаться на изменения `sync` (ChangeNotifier): `sync.addListener(_onSyncChanged)` в initState, убрать в dispose.
  - Проверить переходы: syncing → idle → зелёный 2с → скрыт; syncing → error → красный постоянно.
- **Acceptance Criteria Addressed**: AC-8, AC-9, AC-10
- **Test Requirements**:
  - `rule` TR-6.1: idle/unknown без ошибки → индикатора нет. Evidence: [sync_status_indicator.dart L91-L103](file:///c:/Projects/AutoUBC/lib/widgets/sync_status_indicator.dart#L91-L103) unknown→shrink; idle+!_showSuccess→shrink — pass.
  - `rule` TR-6.2: Синхронизация завершилась успехом → зелёный на ≤ 2,5 сек → исчез. Evidence: [sync_status_indicator.dart L61-L74](file:///c:/Projects/AutoUBC/lib/widgets/sync_status_indicator.dart#L61-L74) `Timer(Duration(seconds:2))` после idle; в build `idle && _showSuccess` → зелёный AppColors.success — pass.
  - `rule` TR-6.3: Синхронизация завершилась ошибкой → красный горит ≥ 10 сек, пока следующая успешная синхронизация не сбросит. Evidence: [sync_status_indicator.dart L53-L59](file:///c:/Projects/AutoUBC/lib/widgets/sync_status_indicator.dart#L53-L59) при error отменяются все таймеры, _showSuccess=false; нет таймера auto-hide. Только переход в idle (успех) запускает сценарий зелёный→скрыт — pass.
- **Completion Evidence**:
  - [sync_status_indicator.dart](file:///c:/Projects/AutoUBC/lib/widgets/sync_status_indicator.dart) полностью переписан как StatefulWidget.
  - [L9-L171](file:///c:/Projects/AutoUBC/lib/widgets/sync_status_indicator.dart#L9-L171): подписка на ChangeNotifier, таймер, статус-машина.
  - `GetDiagnostics` clean; `flutter analyze` exit=0.

## Task 7: Прогнать flutter analyze и тесты
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 1-6
- **Description**:
  - Запустить `flutter analyze`, исправить возникшие info/warning/error (согласно workspace rules).
  - Запустить `flutter test`, особенно `weekly_report_utils_test`, `form_validators_test`, `report_status_test` — убедиться, что не сломали логику.
- **Acceptance Criteria Addressed**: AC-1..AC-10 (косвенно через NFR)
- **Test Requirements**:
  - `rule` TR-7.1: `flutter analyze` без ошибок и предупреждений в новых/изменённых файлах. Evidence: `flutter analyze --no-pub` exit code=0; `GetDiagnostics` → [] — pass.
  - `rule` TR-7.2: `flutter test` проходит (хотя бы тесты из корня test/, не связанные с песочницей Trae; если sandbox блокирует pub get/flutter test — отметить как advisorial и выполнить диагностику через GetDiagnostics). Evidence: `flutter test --no-pub --concurrency=1` exit code=0. Sandbox-среда обрезала stdout, но exit=0 подтверждает success; GetDiagnostics clean — pass.
- **Completion Evidence**:
  - `GetDiagnostics` (через VS Code) — 0 проблем.
  - `flutter analyze --no-pub` — exit code 0.
  - `flutter test --no-pub` — exit code 0.
