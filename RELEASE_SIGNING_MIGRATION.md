# План: переход AutoUBC на постоянную release-подпись

## Понимание задачи

Сейчас Android release-сборка AutoUBC подписывается стандартным debug-ключом: `android/app/build.gradle` использует `signingConfigs.debug`. Нужно перейти на отдельный постоянный release-keystore, чтобы APK имел корректную подпись для прямой установки на телефоны, нормальных обновлений и предсказуемой работы системного установщика.

Выбранные ограничения:

- распространение — только прямой APK, без настройки Google Play;
- уже установленные debug-сборки можно удалить и установить заново;
- keystore и пароли хранятся локально на компьютере и в защищённой резервной копии;
- CI и автоматическое секретное хранилище пока не добавляются.

## Текущее состояние и риски

- `applicationId`: `com.driver.autoubc`;
- текущая release-подпись — debug certificate с SHA-1 `81:37:B0:...`;
- `android/.gitignore` уже исключает `key.properties`, `*.jks` и `*.keystore`;
- текущий Google Web Client ID в Dart-коде менять не нужно;
- новая release-подпись будет иметь другой SHA-1. Его нужно добавить в Android OAuth client в Google Cloud Console вместе с package name `com.driver.autoubc`;
- APK, подписанный новой release-подписью, нельзя установить поверх debug-версии. Перед удалением debug-версии пользовательские данные должны быть синхронизированы в Google Drive, иначе локальная база будет потеряна.

## Архитектура хранения подписи

```text
Локальный компьютер
├── android/key.properties              # не коммитить
└── android/app/autoubc-release.jks     # не коммитить

android/app/build.gradle
└── release -> autoubc-release.jks

build.ps1
└── проверка key.properties/keystore -> universal AutoUBC.apk
```

Keystore будет создан один раз через `keytool` с отдельным alias и сильными паролями. Пароли не будут записываться в репозиторий, командную документацию с реальными значениями или исходный код. Защищённая резервная копия keystore и паролей обязательна: потеря ключа лишит возможности обновлять уже распространённые release APK.

## Изменения

### 1. Создать локальный release-keystore

- Добавить безопасную процедуру создания `android/app/autoubc-release.jks`.
- Создать `android/key.properties` с путём `app/autoubc-release.jks`, alias и секретами.
- Добавить безопасный шаблон `android/key.properties.example` без реальных паролей.
- Сохранить keystore и секреты в защищённой резервной копии отдельно от Git.
- Получить SHA-1/SHA-256 release-сертификата через `keytool` и зафиксировать fingerprint в локальной документации или менеджере паролей.

### 2. Подключить подпись в Gradle

Изменить `android/app/build.gradle`:

- загрузить `android/key.properties` через `Properties`;
- настроить отдельный `signingConfigs.release` с `keyAlias`, `keyPassword`, `storeFile` и `storePassword`;
- разрешить путь к keystore относительно Android root через `rootProject.file(...)`;
- заменить `signingConfig signingConfigs.debug` в `buildTypes.release` на `signingConfigs.release`;
- не менять debug/profile-сборки, чтобы разработка и локальный запуск продолжали работать;
- не добавлять fallback на debug-подпись для release, чтобы случайно не выпустить снова debug APK;
- сохранить текущие `minifyEnabled`, `shrinkResources` и ProGuard-настройки.

### 3. Добавить preflight в сборочный процесс

Изменить `build.ps1`:

- перед release-сборкой проверять наличие `android/key.properties`;
- читать из него `storeFile` и проверять существование keystore;
- при отсутствии секрета или файла завершать сборку с понятным сообщением вместо создания неподходящего APK;
- сохранить универсальную сборку без `--split-per-abi`, чтобы один APK устанавливался на поддерживаемые ABI;
- копировать только успешно подписанный release APK в пользовательский артефакт `AutoUBC.apk`;
- не копировать и не логировать пароли.

При необходимости обновить `.gitignore`, чтобы локальный release APK также не попадал в Git и не было путаницы со старым debug APK.

### 4. Обновить Google OAuth

После создания keystore:

- добавить release SHA-1 в Android OAuth client для `com.driver.autoubc`;
- оставить текущий debug SHA-1 для debug-сборок, если разработка через Google Sign-In должна продолжать работать;
- Web Client ID и `serverClientId` в `lib/services/google_drive_sync_service.dart` не менять;
- проверить интерактивный вход, тихий вход и доступ к Google Drive именно из release APK.

### 5. Подготовить миграцию с debug APK

Перед удалением debug-версии:

1. Открыть текущую версию и дождаться завершения синхронизации.
2. Убедиться, что backup в Google Drive существует и отображается успешный статус синхронизации.
3. При необходимости сделать дополнительный экспорт отчёта.
4. Удалить debug-версию с телефона.
5. Установить release APK.
6. Войти в тот же Google-аккаунт.
7. Проверить восстановление базы, автомобили, записи, заметки и отчёты.

Если данные существуют только локально и ещё не попали в Google Drive, удалять debug-версию нельзя до создания резервной копии.

### 6. Обновить документацию и версионирование

Изменить `README.md`:

- описать создание и хранение release-keystore без реальных секретов;
- указать, что `android/key.properties` и `.jks` не коммитятся;
- добавить порядок получения и регистрации release SHA-1;
- явно предупредить о невозможности обновить debug APK поверх release APK;
- описать обязательное увеличение `versionCode` в `pubspec.yaml` для каждого следующего release APK;
- сохранить инструкцию универсальной сборки через `build.ps1`.

Перед первой распространённой release-сборкой увеличить build number относительно текущего debug APK, например с `1.0.0+1` на следующий согласованный номер.

## Проверка результата

- Проверить сертификат собранного APK командой `apksigner verify --verbose --print-certs` или эквивалентной проверкой.
- Сверить fingerprint APK с fingerprint, добавленным в Google Cloud Console.
- Собрать `flutter build apk --release` через обновлённый скрипт.
- Установить release APK после удаления debug-версии на тестовом Android-телефоне.
- Проверить Google Sign-In, восстановление Drive backup и основные экраны приложения.
- Собрать второй APK с увеличенным `versionCode` и проверить обновление поверх предыдущей release-версии.
- Запустить `flutter analyze` и релевантные `flutter test`.
- Проверить `git diff --check` и убедиться, что keystore, `key.properties`, пароли и локальные APK не отслеживаются Git.

## Не входит в этот этап

- Google Play App Signing и публикация в Play Console;
- CI/CD и хранение секрета в CI;
- сохранение локальной базы при удалении debug-приложения без предварительной синхронизации;
- изменение Dart-кода Google Drive авторизации, если тест release SHA-1 проходит.

## Definition of Done

- [ ] Release-сборка больше не использует `signingConfigs.debug`.
- [ ] Keystore, `key.properties` и пароли исключены из Git и имеют защищённую резервную копию.
- [ ] Release SHA-1 добавлен в Android OAuth client, а Google Sign-In и Google Drive работают в release APK.
- [ ] Обновлённый `build.ps1` проверяет signing-конфигурацию и создаёт универсальный подписанный `AutoUBC.apk`.
- [ ] Выполнена миграция тестового телефона с debug APK на release APK с проверкой восстановления данных.
- [ ] Следующая release-сборка обновляет `versionCode` и устанавливается поверх предыдущей release-версии.
- [ ] `flutter analyze`, релевантные тесты и проверка подписи APK проходят успешно.
