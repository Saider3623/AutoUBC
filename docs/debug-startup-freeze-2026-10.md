# Debug Session: startup-freeze-google-auth
- **Status**: [FIX READY — ожидает проверки на устройстве]
- **Issue**: После установки приложения и авторизации через Google индикатор синхронизации возле названия авто крутится, после чего приложение зависает при каждом запуске. Статические правки (атомарное восстановление БД, мьютекс облачной инициализации, таймауты Drive API) проблему не устранили.
- **Debug Server**: http://127.0.0.1:<port>/event (будет заполнено после старта сервера)
- **Log File**: .dbg/trae-debug-log-startup-freeze-google-auth.ndjson

## Reproduction Steps
1. Установить приложение заново (чистая установка).
2. Запустить приложение, пройти авторизацию через Google.
3. Наблюдать: индикатор возле названия авто делает оборот и приложение зависает.
4. При последующих запусках зависание повторяется сразу после старта.

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | Дедлок очереди lifecycle БД: какой-то узел не завершает операцию (`withClosedDatabase`/`_init`), и все последующие `await isar` блокируются навсегда | High | Low | Pending |
| B | `Isar.open` внутри `verifyDatabaseSnapshot`/`_init` на устройстве виснет или падает (нативный уровень), блокируя UI-изолят | Medium | Low | Pending |
| C | `_beginOperation()` без парного `_endOperation()` — индикатор остаётся в состоянии `syncing` навсегда, UI «замирает» из-за постоянных notifyListeners | Medium | Low | Pending |
| D | Сетевой вызов (sign-in / Drive) не укладывается в таймаут, но очередь `_operationQueue`/`_syncQueue` остаётся занятой и блокирует запуск | Medium | Low | Pending |
| E | Блокировка платформенного (UI) потока вне Dart: ANR от нативного кода, зависание event loop не видно в логах Dart | Low | High | Pending |
| F | Re-entrancy на экране ввода данных: `didChangeDependencies` -> `_checkMissedOdometerForYesterday`/`_loadCurrentOdometer` повторно вызываются без ограничения после каждого `notifyListeners` | Medium | Low | Pending |
| G | UI-изолят реально заблокирован: глобальный heartbeat (`main.dart`) прекращается, хотя процесс жив | Medium | Low | Pending |
| H | Бесконечный цикл разбиения месяца на недели: шаг `add(Duration(days: 1))` не покидает день перевода часов (25.10.2026, 25 часов), `weeks` растёт бесконечно | High | Low | **Confirmed** |

## Log Evidence
Лог `pre-fix` (23.10.2026):
- Скачивание, замена файла и переоткрытие БД завершаются успешно (`finished seq=3`, статус `syncing -> idle`) — A, B, C, D опровергнуты.
- До скачивания (0 машин) heartbeat идёт каждую секунду; зависание начинается только после `cars loaded (1)`, т.е. при первом построении `PageView` с данными.
- Все 12 запросов к БД после загрузки (seq 4–15) объясняются `loadLogsForCar` и экраном ввода — очередь не блокирована.

Причина (H): `WeeklyReportScreen._getWeeksInMonth` (и `ReportService._buildWeeks`). Для октября: Вс 25.10 00:00 + 24 ч = Вс 25.10 23:00 → `workingWeekEnd` снова даёт Вс 25.10 00:00 → цикл без выхода, список растёт, UI-изолят заблокирован. Зависает любой октябрь с переводом часов внутри месяца (2024, 2025, 2026, 2028) в режимах 5 и 6 дней.

## Instrumentation Points (pre-fix)
Только логи, бизнес-логика не изменена. Отчёты идут POST-ом на `http://192.168.31.107:7777/event`.

| Файл | Точки |
|------|-------|
| lib/main.dart | `main` старт; **UI-heartbeat кожну секунду (точка G)**; `initState` postFrame; результат `signInSilently`; `_initializeCloudSync` (begin / initialization done / action / download result) |
| lib/db/database_service.dart | `_enqueueLifecycle` (queued/running/finished/failed + seq + ms); `_init` (begin/isar opened/backup/done); `withClosedDatabase` (begin/closed/operation finished/reopening/reopened) |
| lib/services/google_drive_sync_service.dart | `_beginOperation`/`_endOperation` (active count + status); `signInSilently` (begin/done); `_downloadBackup` (begin/session/file/transfer/validated) |
| lib/providers/app_provider.dart | `_loadCarsInternal` (begin/cars loaded/end); `loadCars` (dedupe hit); `loadLogsForCar` (begin/end); `refreshAll` (begin/end) |
| lib/screens/data_entry_screen.dart | `initState`; `didChangeDependencies` (#N, carId, loadedCarId); `_checkMissedOdometerForYesterday` (begin/end + #N); `_loadCurrentOdometer` (begin/end/aborted + #N) |
| lib/widgets/sync_status_indicator.dart | `initState`; «пульс» UI кожну секунду (builds count + status + connected); кожне змінення статусу; `dispose` |

Ключі для читання:
- Є `running seq=N`, немає `finished seq=N` → зависання всередині операції черги БД (A).
- `_init`: `begin` без `isar opened` → нативний `Isar.open` не завершується (B).
- Точка G (`ui alive elapsed=Ns`) зупиняється, а події ще надходять → UI-потік заблоковано (G/E). Якщо G іде безупинно — UI живий, шукайте залиплий статус (C/D).
- Точки F: якщо `check #N`/`deps #N` зростають безмежно — re-entrancy на екрані вводу (F).

## Verification Conclusion
Fix: календарная арифметика `addCalendarDays()` (`DateTime(y, m, d + n)`) в `weekly_report_utils.dart`; разбиение недель вынесено в `buildReportWeeks()`; исправлены `report_service.dart` и вычисление «вчера» в `data_entry_screen.dart`. Регрессионные тесты — `test/weekly_report_utils_test.dart` (запускать с `TZ=Europe/Kyiv`).
Post-fix: подтвердить на устройстве — heartbeat не прерывается, вкладка «Еженедельный отчёт» за октябрь открывается.
