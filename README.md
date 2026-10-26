# AutoUBC

AutoUBC is a local driver workbook for tracking vehicle mileage, refueling,
service entries, reminders, notes, and reports.

## Architecture

- Flutter / Dart 3.x
- Provider for application state
- Isar 3 for local persistence
- Google Drive `appDataFolder` for optional backup synchronization

Child records use their indexed `carId` as the canonical vehicle relationship.
The legacy Isar links remain in the schema for backwards-compatible reads and
are repaired into `carId` during database initialization. Existing database
files are not cleared during upgrades.

## Development

```text
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --debug
```

The Isar integration test is skipped by desktop `flutter test` when the native
Isar DLL is unavailable. Run it in an environment where the Isar native library
is packaged, such as an integration/device test target.

## Remote logs (optional)

Builds can upload every app log (`print`, `debugPrint`, Flutter errors,
uncaught exceptions, debug points) to a private GitHub repository, one file per
launch: `logs/<date>/<time>_<os>_<id>.log`. Logs are written to a local file
first and uploaded every 30 seconds and when the app goes to the background; a
session that ended with a crash is uploaded on the next launch.

Logging is disabled unless the build gets a token, so regular builds are
unaffected:

1. Create a private repository for logs (default `fesh-biz/autoubc-logs`) with
   an initial commit.
2. Create a fine-grained GitHub token limited to **that repository only** with
   `Contents: Read and write`. The token is embedded in the APK, so never give
   it access to the source repository.
3. Copy `.secrets/remote_log.example.json` to `.secrets/remote_log.json`
   (git-ignored) and put the token there.
4. `build.ps1` picks the file up automatically. For `flutter run`, add
   `--dart-define-from-file=.secrets/remote_log.json`.

## Data safety

Before local backups, Isar creates a compact snapshot with `copyToFile()`. Cloud
downloads are written to a temporary file, schema-checked, and atomically
swapped into place. The app uses a local-first policy: an existing local
database is never replaced by a remote copy during a normal launch.

Android system backup explicitly excludes `files/autoubc`, the active Isar
database directory. If the local database file is missing, the first authorized
startup silently restores the latest copy from Google Drive when one exists. If
there is no cloud copy, the app continues with an empty local database.

After interactive authorization, local data is preserved and uploaded rather
than overwritten. Every local mutation persists a pending-sync marker before the
write and uploads the newest snapshot silently; failed uploads remain pending
for a later retry.

The Windows `build.ps1` script builds separate release APKs for each Android
ABI and copies them directly into the root `release` directory:

- `release/AutoUBC-arm64-v8a.apk` — primary APK for Armor X8i and Xiaomi 12;
- `release/AutoUBC-armeabi-v7a.apk` — 32-bit fallback for compatible phones;
- `release/AutoUBC-x86_64.apk` — x86_64 emulator/phone variant.

The ABI is included in each filename so the correct APK can be selected without
confusing it with an older universal `AutoUBC.apk` from the Downloads folder.

If the build fails, it can be retried after running `flutter clean`, stopping
Gradle daemons, clearing the project `.gradle` directory and only the global
`transforms-*` caches, then regenerating Isar code. This handles stale
intermediate resources such as `fragment_fast_out_extra_slow_in` without
changing application runtime behavior.

Both requested phones are expected to use ARM ABIs. Start with
`release/AutoUBC-arm64-v8a.apk`. If the Armor X8i rejects it, try
`release/AutoUBC-armeabi-v7a.apk`. When USB debugging is available, the device
ABI can be checked with:

```text
adb shell getprop ro.product.cpu.abilist
```

## Code conventions

- Write code comments and documentation comments in Ukrainian or English only.
- Do not add comments in Russian. This applies to inline comments, `///` docs,
  TODO/FIXME notes, and block comments; localized product text and domain data
  are not comments and should remain in their intended language.
- See [AGENTS.md](AGENTS.md) for instructions intended for AI coding agents.
