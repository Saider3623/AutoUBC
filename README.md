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

## Data safety

Before local backups, Isar creates a compact snapshot with `copyToFile()`. Cloud
downloads are written to a temporary file, schema-checked, and atomically
swapped into place. If local and remote data both exist without a known sync
baseline, the app keeps local data and asks before either copy is overwritten.

Android system backup explicitly excludes `files/autoubc`, the active Isar
database directory. Reinstalling or transferring the app therefore starts with
an empty local database and restores the latest copy only through the in-app
Google Drive handshake, instead of resurrecting an older local snapshot.

Destructive car deletion is flushed to Google Drive immediately when an account
is connected; it does not wait for the normal debounce timer. Other edits
persist a pending-sync marker, so an interrupted debounce is reviewed on the
next startup instead of being hidden by an unchanged cloud timestamp.

The Windows `build.ps1` script retries a failed split-ABI APK build after
running `flutter clean`, stopping Gradle daemons, clearing the project
`.gradle` directory and only the global `transforms-*` caches, then regenerating
Isar code. This handles stale intermediate resources such as
`fragment_fast_out_extra_slow_in` without changing application runtime behavior.
