# AutoUBC — План доработок (15 предложений по оптимизации)

Контекст проекта (обязательно к прочтению перед выполнением):
- Flutter 3.47+, Dart 3.13+, compileSdk 35, AGP 8.11.1, Gradle 8.14.1, Kotlin 2.2.20.
- Зависимости: Provider, Isar, intl, Google Drive sync; не вводить новых зависимостей без явного разрешения.
- Локализация RU/UK/EN: новые строки добавлять в `.arb` и прогонять `flutter gen-l10n`.
- Правила (см. `AGENTS.md`): комментарии UA/EN, не ломать существующие тесты, после правок `flutter analyze` clean.
- Существующее состояние на момент написания плана: 2 вкладки (Ввод данных, Еженедельный отчёт), drill-down WeekDetailScreen реализован, 3-состояния индикатора синхронизации (скрыто/зелёный 2 сек/красный постоянно) работают, пустые/будущие недели некликабельны.

Выбор пользователем списка номеров через запятую: агент выполняет **только** пункты с указанными номерами; пункты без явного выбора — не трогать.

---

## 1. Убрать дублирующий `_loadCurrentOdometer` (3 вызова → 1)

**Проблема**: `_loadCurrentOdometer()` вызывается из `initState`, `didUpdateWidget` и `didChangeDependencies` с addPostFrameCallback. При первом запуске вкладки получаем 2–3 лишних `await _db.getOdometerLog`.

**Что делать**:
- Оставить только одну точку вызова. Рекомендуемый вариант: `didChangeDependencies` с гейтом `carId != _loadedCarId` + `if (mounted)` guard. `initState` и `didUpdateWidget` вызовы удалить.
- Перед удалением проверить, что смена `localeProvider` и rebuild `Consumer<AppProvider>` (которые триггерят `didChangeDependencies`) не вызовут повторной загрузки — для этого `_loadedCarId` уже есть, достаточно оставить проверку.
- Убедиться, что при смене выбранного автомобиля снаружи (`AppProvider.selectCar`) экран корректно подхватывает новый показатель.

**Кодовые якоря**:
- [data_entry_screen.dart L33-L78](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L33-L78)

---

## 2. Кэшировать `DateFormat` инстансы (уменьшить мусор на GC)

**Проблема**: На каждый `build` / каждое нажатие «+» создаются новые `DateFormat('yyyy-MM-dd')`, `DateFormat('HH:mm')`, `DateFormat.yMMMM(...)` и т.д. При активном пользовании это десятки/сотни новых объектов DateFormat в секунду.

**Что делать**:
- Для форматов с фиксированной маской (`yyyy-MM-dd`, `HH:mm`) завести `static const / static late final` (top-level или внутри класса) — они thread-safe в Dart, можно переиспользовать глобально.
- Для форматов, зависящих от `languageCode` (`DateFormat.yMMMM(locale)`, `.d(locale)`, `.MMMM(locale)`), сделать простой кэш `static final Map<String, DateFormat> _cache = {};` или класс-хелпер `DateFormats.forLocale(languageCode)` с lazy-инициализацией и переиспользованием.
- Не менять формат/вывод строк, только способ получения инстанса.

**Кодовые якоря**:
- Создать, например, `lib/utils/date_formats.dart` и использовать во всех `lib/screens/*`.
- Места использования:
  - [data_entry_screen.dart L63, L181, L365-L368](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L63-L63)
  - [weekly_report_screen.dart L98, L165, L315-L316, L743-L744](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L98-L98)
  - [week_detail_screen.dart L21-L24, L89-L92](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart#L21-L24)

---

## 3. Сортировать логи в `AppProvider` ОДИН раз; поддерживать инкрементально

**Проблема**: В `_calculateWeeklyReport` каждую не-пустую неделю выполняется `odometerLogs.sort(...)`. К тому же `_weekHasLogsCached` обходит все логи линейно.

**Что делать**:
- В `loadLogsForCar(int carId)` сразу после получения `_odometerLogs` и `_fuelLogs` выполнить `.sort()` по `dateString` ASC (один раз на переключение машины / refreshAll).
- В `addOdometerLog` / `deleteOdometerLog` (аналогично fuel) **поддерживать** отсортированность: либо использовать бинарный вставку, либо после каждой операции делать sort на 1000+ элементах — неважно, важно что к моменту использования списки всегда отсортированы.
- Опционально (если хочется ещё ускорить `_weekHasLogsCached`): заменить обход на бинарный поиск по границам `[startStr, endStr]`, т.к. `dateString` уже в лексикографически сортируемом формате `yyyy-MM-dd`.
- Удалить дублирующий sort из `_calculateWeeklyReport`.

**Кодовые якоря**:
- [app_provider.dart L16-L38](file:///c:/Projects/AutoUBC/lib/providers/app_provider.dart#L16-L38) (поля и геттеры логов)
- [app_provider.dart L222-L237](file:///c:/Projects/AutoUBC/lib/providers/app_provider.dart#L222-L237) (loadLogsForCar — вставить sort)
- [weekly_report_screen.dart L760](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L760-L760) (удалить отсюда sort)

---

## 4. Вынести `_getWeeksInMonth` и `_calculateWeeklyReport` в утилиты (тестируемость)

**Проблема**: Сейчас это приватные методы `_WeeklyReportScreenState` — их нельзя unit-протестировать напрямую через `flutter test`, только через WidgetTester.

**Что делать**:
- Переместить `_getWeeksInMonth(DateTime month)` → в `utils/weekly_report_utils.dart` как top-level `List<Map<String, DateTime>> getWeeksInMonth(DateTime month)`.
- Переместить `_calculateWeeklyReport(carId, start, end)` → либо в `utils/weekly_report_utils.dart` (принимая `DatabaseService` параметром), либо в `services/report_service.dart` как метод `Future<WeeklyReportData> calculateWeeklyReport(int carId, DateTime startDate, DateTime endDate)`. Класс `WeeklyReportData` тоже вынести из `weekly_report_screen.dart` в этот же файл / в `models/weekly_report_data.dart`, чтобы не импортировать screen-файл из utils.
- В WeeklyReportScreen заменить вызовы на импортированную функцию/метод; проверить, что Provider/DB всё так же достаются.
- Опционально: сразу написать 2–3 unit-теста в `test/weekly_report_utils_test.dart`: пустой месяц, месяц с 1 неделей, декабрь (проверка перехода через год).

**Кодовые якоря**:
- [weekly_report_screen.dart L716-L777](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L716-L777)
- [weekly_report_utils.dart](file:///c:/Projects/AutoUBC/lib/utils/weekly_report_utils.dart) — сюда складывать

---

## 5. Мемоизация: недели месяца + кэш weekly report per week key

**Проблема**: Каждый `notifyListeners()` из `AppProvider` триггерит rebuild Consumer внутри `WeeklyReportScreen` → перевычисляется `_getWeeksInMonth`, `prioritizeCurrentReportWeek`, и **все** `FutureBuilder` карточек запускают `_calculateWeeklyReport` заново (даже если данные не поменялись — например, при удалении заметки `_notes`).

**Что делать**:
- В `_WeeklyReportScreenState` завести кэш-ключ, например `_MonthCacheKey(Object.hash(carId, year, month))` и поле `List<Map<String, DateTime>>? _cachedWeeks`; перевычислять `_getWeeksInMonth` только при смене ключа.
- Для `_calculateWeeklyReport` завести `final _weekReportCache = <String, WeeklyReportData>{}`, ключ = `'$carId:$startStr:$endStr'`. Перед `FutureBuilder` проверять ключ → есть → `Future.value(...)` или синхронная ветка; нет → запустить `_calculateWeeklyReport` и сохранить в кэш.
- Инвалидация кэша:
  - В `_onWeekTap(...)` после возврата с `WeekDetailScreen` → `_weekReportCache.clear()` (или удалить только запись за эту неделю).
  - При переходе между месяцами / машинами → тоже чистить.
- Опционально: слушать `AppProvider` через `listen: true` снаружи и сравнивать длины `odometerLogs.length`/`fuelLogs.length` — если не изменились, не инвалидировать.

**Кодовые якоря**:
- [weekly_report_screen.dart L95-L189](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L95-L189)

---

## 6. Добавить `ValueKey` на карточки недель (правильный reuse в ListView)

**Проблема**: У `ListView.builder` itemBuilder сейчас возвращает Widget без `key` — после возврата из детализации + `setState((){})` Flutter может пересоздавать Element деревья для не-первых карточек, теряя локальное состояние (например, splash-эффект InkWell, или состояние FutureBuilder если мы делаем кэш).

**Что делать**:
- На корневой Widget каждого item (это сейчас `_wrapClickable(...)`) навесить параметр `key: ValueKey('week_${startStr}_${endStr}_$isCurrentWeek_$isFutureWeek')` (уникальный по диапазону и состоянию).
- Компоновать: обернуть `_wrapClickable` в снаружи `KeyedSubtree` или добавить `key` в Card/Material. Лучше — добавить именованный параметр `Key? key` в `_wrapClickable` и прокидывать его сразу в Material.

**Кодовые якоря**:
- [weekly_report_screen.dart L115-L191](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L115-L191)

---

## 7. Разобраться с двойными `notifyListeners()` в GoogleDriveSyncService

**Проблема**: Видно 5 вызовов `notifyListeners()` в сервисе синхронизации. Часто на один пользовательский экшен (uploadBackup) идёт 2–3 уведомления подряд (статус unknown→syncing, syncing→idle/error). При быстрых переходах может случиться гонка: syncing→idle→error за 1 кадр; индикатор успеха мигает, а потом сразу загорается красным навсегда, хотя пользователь ожидал стабильный UI.

**Что делать**:
- Инспектировать все вызовы `notifyListeners`: убедиться, что после установки статуса `_syncStatus = ...` уведомление вызывается **ровно один раз** на переход, и «промежуточный idle» (если он внутри асинхронного шага за которым сразу error) не оставляет мусорного «зелёного 2 сек» состояния.
- Добавить guard: если новое состояние равно старому (`_syncStatus == newStatus`) — notifyListeners **не вызывать**.
- Проверить case «синхронизация завершилась успехом, но сразу же следующий ручной вызов sync дал network error»: убедиться, что `_showSuccess` таймер в `SyncStatusIndicator` отменяется при приходе error, а зелёный кружок не горит «остаток 2 сек» поверх ошибки.

**Кодовые якоря**:
- [google_drive_sync_service.dart L95-L197](file:///c:/Projects/AutoUBC/lib/services/google_drive_sync_service.dart#L95-L197)
- [sync_status_indicator.dart L53-L75](file:///c:/Projects/AutoUBC/lib/widgets/sync_status_indicator.dart#L53-L75) (уже есть cancel-логика, проверить на 100% покрытие)

---

## 8. Утилитный хелпер «дата в диапазоне недели» — единый для всех экранов

**Проблема**: Сейчас фильтрация «в пределах недели» реализована в 3 местах НЕ идентично:
  - `isDateInReportWeek(week, date)` → `_dateOnly + !day.isBefore && !isAfter`
  - `_weekHasLogsCached(provider, week)` → `DateTime.parse + !d.isBefore && !d.isAfter` (start, end с 23:59:59 отдельно)
  - `WeekDetailScreen` filter → `DateTime.parse(dateString)` + `DateTime(year,month,day, 23,59,59)`.
У недели, переходящей через границу месяца, возможны пропуски (30 сен — 6 окт: в отчёте сентября конец срезается первым днём октября, в детализации неделя берётся как оригинальный диапазон и может включать 6 окт).

**Что делать**:
- В `utils/weekly_report_utils.dart` (или в новом `utils/date_ranges.dart`) создать:
  - top-level `DateTime dateOnly(DateTime d)` → публичный (не private).
  - top-level `bool isDateWithinWeek(DateTime date, DateTime start, DateTime end)` → использует `dateOnly` и делает единый алгоритм «границы включительно».
  - `bool logsAreWithinWeek(String isoDateString, DateTime weekStart, DateTime weekEnd)` → внутри переиспользует `DateTime.parse + isDateWithinWeek`.
- Заменить ВСЕ 3 места на вызовы нового хелпера.
- Написать 1 unit-тест: неделя `30.09.2026 – 06.10.2026` → даты `29.09` (false), `30.09` (true), `06.10` (true), `07.10` (false).

**Кодовые якоря**:
- [weekly_report_utils.dart L1-L26](file:///c:/Projects/AutoUBC/lib/utils/weekly_report_utils.dart#L1-L26)
- [weekly_report_screen.dart L43-L61](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L43-L61)
- [week_detail_screen.dart L63-L77](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart#L63-L77)

---

## 9. Блокировать поля ввода во время сохранения (`_isSavingFuel / _isSavingOdometer`)

**Проблема**: Пока выполняется `await provider.addFuelLog/addOdometerLog`, пользователь может успеть стереть/дописать что-то в поле. После `reset()/clear()` пользовательский ввод затирается; или наоборот — `reset()` сработает, пока курсор стоит в поле, и пользователь увидит мигание курсора/очистку неожиданную.

**Что делать**:
- В секции одометра (Card → Form) добавить `absorbing: _isSavingOdometer` через обёртку `AbsorbPointer`.
- В секции топлива аналогично `AbsorbPointer(absorbing: _isSavingFuel, child: ...)` или `IgnorePointer`.
- Либо проставить `readOnly: _isSavingOdometer` у `TextFormField` одометра и `readOnly: _isSavingFuel` у литров (меньше слоёв, AbsorbPointer предпочтительнее для блокировки выбора чипа топлива тоже).
- IconButton «+» уже блокируется через `onPressed: null` — оставить как есть.

**Кодовые якоря**:
- [data_entry_screen.dart L130-L410](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L130-L410) — обе Card (одометр и fuel)

---

## 10. Debounce-сохранение одометра при onChanged (400 ms)

**Проблема**: Пользователь набирал 12345 в одометре, случайно свайпнул вкладку PageView → `didChangeDependencies` сработал и перечитал `_loadCurrentOdometer`, вернув старое значение. Ввод пропал.

**Что делать**:
- Добавить `Timer? _odoDebounce` в `_DataEntryScreenState`; dispose таймера в `dispose()`.
- В `onChanged` поля одометра:
  - `_odoDebounce?.cancel()`;
  - `_odoDebounce = Timer(const Duration(milliseconds: 400), () => _saveOdometerDebounced())`.
- Метод `_saveOdometerDebounced()`: выполняет ту же логику что и кнопка «+» (validate, if ok → `provider.addOdometerLog`, SnackBar). При этом НЕ очищает поле — только обновляет `_loadedCarId` guards, чтобы `_loadCurrentOdometer` при релоге ничего не перезатирал.
- Дополнительно: если уже идёт явное сохранение через кнопку «+» (`_isSavingOdometer=true`), debounce-callback должен `return`.

**Кодовые якоря**:
- [data_entry_screen.dart L140-L220](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L140-L220) — одометр Form
- [data_entry_screen.dart L19-L31](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L19-L31) — сюда добавить Timer поле

---

## 11. Закрыть `use_build_context_synchronously` во всех async onPressed

**Проблема**: Уже исправлен fuel, но ещё 2 места используют `ScaffoldMessenger.of(context)` ПОСЛЕ `await ...`: одометр (L177) и заметки (L613). При включении strict-analyzer это info-warning. Если пользователь закроет экран во время await → `context` invalid, приложение упадёт с ошибкой.

**Что делать**:
- В одометр-секции onPressed «+»: ДО try/catch сохранить
  - `final messenger = ScaffoldMessenger.of(context);`
  - `final navigator = Navigator.of(context);`
  - `final loc = AppLocalizations.of(context)!;` (если используется после await)
  - Аналогично `final focusScope = FocusScope.of(context);`
  - `final formState = _odometerFormKey.currentState;`
- После каждого `await provider.xxx()` сначала проверять `if (!mounted) return;`, а затем использовать сохранённые локальные переменные, а не `context` напрямую.
- То же самое повторить в `Note` onPressed/сохранение (область L613).
- Прогнать `flutter analyze --no-pub` — сообщений `use_build_context_synchronously` в data_entry_screen не должно быть.

**Кодовые якоря**:
- [data_entry_screen.dart L155-L200](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L155-L200) (одометр save)
- [data_entry_screen.dart L600-L660](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L600-L660) (notes)

---

## 12. Заменить `Consumer<AppProvider>` на `Selector2<List<Odo>, List<Fuel>>` в WeekDetailScreen

**Проблема**: В WeekDetailScreen `Consumer<AppProvider>` внутри builder перестраивает ВСЁ дерево ListView.builder при **любом** `notifyListeners()` — например при изменении `_notes`, `_serviceLogs`, `_reminders`, или при смене `_isLoading`. Эти данные экрану не нужны — он рисует только одометр и заправки.

**Что делать**:
- Заменить:
  ```dart
  Consumer<AppProvider>(
    builder: (context, provider, child) {
  ```
  на:
  ```dart
  Selector2<AppProvider, List<OdometerLog>, List<FuelLog>>(
    selector: (context, provider) => (provider.odometerLogs, provider.fuelLogs),
    shouldRebuild: (prev, next) => prev.$1 != next.$1 || prev.$2 != next.$2,
    builder: (context, odoLogs, fuelLogs, child) {
  ```
- Внутри builder использовать `odoLogs`/`fuelLogs` вместо `provider.odometerLogs`/`provider.fuelLogs`.
- `provider.selectedCar` можно достать через `Provider.of<AppProvider>(context, listen: false).selectedCar` (или добавить Selector3, но selectedCar меняется редко — лучше listen:false + сравнить с `_lastCarId` локально, если нужно).

**Кодовые якоря**:
- [week_detail_screen.dart L50-L180](file:///c:/Projects/AutoUBC/lib/screens/week_detail_screen.dart#L50-L180)

---

## 13. Именованная константа FAB overlap-паддинга

**Проблема**: В project_memory записано правило: «FAB overlap требует 88 px bottom padding в data_entry_screen». В коде это магическое число `EdgeInsets.fromLTRB(12, 12, 12, 88)`, если появится вторая FAB-кнопка или изменится высота `BottomNavigationBarPageIndicator` (L477-L500 в main.dart) — искать и править приходится вручную.

**Что делать**:
- Внутри `_DataEntryScreenState` (или top-level в файле) добавить:
  ```dart
  const double _kFabOverlapPaddingBottom = 88.0;
  const double _kHorizontalPadding = 12.0;
  const double _kTopPadding = 12.0;
  ```
  и использовать
  ```dart
  padding: const EdgeInsets.fromLTRB(_kHorizontalPadding, _kTopPadding, _kHorizontalPadding, _kFabOverlapPaddingBottom),
  ```
- Опционально: проверить другие экраны, нет ли там копипасты `88.0` — если есть, вынести константу в `widgets/spacing.dart` или `utils/layout_constants.dart`.

**Кодовые якоря**:
- [data_entry_screen.dart L89-L91](file:///c:/Projects/AutoUBC/lib/screens/data_entry_screen.dart#L89-L91)

---

## 14. Конфигурируемый первый день недели (Monday/Sunday)

**Проблема**: В `_getWeeksInMonth` есть магическая формула `daysToSunday = 7 - currentStart.weekday`. Это работает только при ISO-представлении, где Monday=1..Sunday=7 и неделя начинается с понедельника. Если пользователь в будущем захочет неделю как Sunday-Saturday (США, Израиль, Пользовательские настройки) — вычисления сломаются.

**Что делать**:
- В `utils/weekly_report_utils.dart` добавить константу/переменную:
  ```dart
  /// Change to DateTime.sunday to enable Sunday-first weeks.
  const int kDefaultWeekStartDay = DateTime.monday;
  ```
- Создать top-level `DateTime weekStartDate(DateTime d, int startWeekday)` и `DateTime weekEndDate(DateTime start, int startWeekday)`:
  - weekStartDate: отматывает d назад до ближайшего `startWeekday` (аналогично `daysToSunday`, но обобщённо).
  - weekEndDate: `start.add(const Duration(days: 6))`.
- Заменить в `_getWeeksInMonth / getWeeksInMonth` (см. пункт 4) старую формулу на вызов этих функций.
- Оставить дефолт `DateTime.monday` (чтобы текущий пользователь ничего не заметил), но сделать возможным простое изменение одной строкой.

**Кодовые якоря**:
- [weekly_report_screen.dart L724](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L724-L724)
- [weekly_report_utils.dart](file:///c:/Projects/AutoUBC/lib/utils/weekly_report_utils.dart) — складывать константы/хелперы сюда.

---

## 15. Кэш «последнее успешно вычисленное» вместо shimmer на каждую неделю при возврате из детализации

**Проблема**: Сейчас при возврате из `WeekDetailScreen` выполняется `setState((){})` в `_onWeekTap` → все `FutureBuilder` карточек пересоздаются и показывают `_buildLoadingWeekCard` (shimmer с прямоугольниками из `OutlineVariant`) на время ~100–500мс. Для пользователя это «экран замигал карточками».

**Что делать**:
- Реализовать хранилище `final _weekCache = <String, WeeklyReportData>{}` в State (см. пункт 5, с которым этот пункт объединяют при выполнении обоих).
- Внутри `builder: (context, snapshot)` FutureBuilder: **прежде чем** показывать `connectionState.waiting`, проверить, есть ли в кэше значение для ключа недели — есть → сразу показывать `_buildWeeklyReportCard` с кэшированным значением, **а** shimmer показывать только при **первом** построении (т.е. когда кэш пуст).
- Альтернатива без FutureBuilder: хранить в List<AsyncSnapshot> / List<WeeklyReportData?> параллельно `weeks`.
- В идеале после возврата из детализации пользователь видит только 1 changed-frame (изменение цифр в удалённой карточке), а не N скелетонов.

**Кодовые якоря**:
- [weekly_report_screen.dart L180-L189](file:///c:/Projects/AutoUBC/lib/screens/weekly_report_screen.dart#L180-L189) (FutureBuilder с loading)

---

## Порядок и рекомендации для агента-исполнителя

1. **Сначала пункты 1, 9, 11** (маленькие, 0 риска регрессов — стабильность > красота).
2. **Потом 8 + 4** (единая логика фильтрации и выносимость в utils → потом проще тестировать).
3. **3 и 2** производительность кэша/сортировки.
4. **5 и 15** — взаимосвязаны, делать вместе.
5. **6, 7, 10, 12, 13, 14** — в любом порядке.

Правило `don't break what works`: если пункт затрагивает 3+ файла и можно сделать в несколько мелких коммитов с прогоном `flutter analyze` после каждого — так и делать. После каждого выполненного пункта запускать:
- `flutter analyze --no-pub`
- `flutter test --no-pub`

Если в каком-то пункте появляется несовместимость с существующим кодом или возникает вопрос пользователя — остановиться и явно задать вопрос перед продолжением (не гадать!).
