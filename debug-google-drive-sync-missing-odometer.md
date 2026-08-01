[OPEN] Debug Session: google-drive-sync-missing-odometer

## Симптом
- После авторизации в Google Drive не появляется “вчерашнее” показание одометра (данные не подтягиваются из облака).

## Ожидаемое поведение
- После входа в Google Drive приложение должно либо:
  - скачать бекап с Google Drive и показать сохранённые записи, либо
  - корректно показать, что используется локальная база, и выполнить загрузку (upload) только если это безопасно.

## Фактическое поведение
- Авторизация проходит, но вчерашняя запись одометра не отображается.

## Гипотезы (falsifiable)
- A: После входа запускается upload локальной базы вместо download, и облако перезаписывается “пустой/неполной” базой.
- B: Download запускается, но Drive API возвращает ошибку/нет файла/нет прав (scope), поэтому база не восстанавливается.
- C: Backup-файл на Google Drive находится, но выбирается неправильный файл (например, дубликаты/не тот modifiedTime).
- D: Download успешен, но база не переоткрывается/данные не перезагружаются в AppProvider, поэтому UI остаётся на старых данных.
- E: В облаке реально нет вчерашней записи (предыдущая синхронизация не сделала upload), поэтому после входа данных нет.

## План сбора доказательств (Instrumentation)
- Добавить отправку событий в Debug Server из:
  - GoogleDriveSyncService.signIn / signInSilently
  - GoogleDriveSyncService._findBackupFileId (кол-во файлов, modifiedTime)
  - GoogleDriveSyncService.uploadBackup / downloadBackup (старт/успех/ошибка)
- Собрать логи для сценария:
  1) Запуск приложения → вход в Google Drive
  2) Открыть Историю/Недельный отчет и проверить наличие записи

## Артефакты
- Debug server env: .dbg/google-drive-sync-missing-odometer.env
- Logs: .dbg/trae-debug-log-google-drive-sync-missing-odometer.ndjson

