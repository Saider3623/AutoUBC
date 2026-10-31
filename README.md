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

The phone database is the working copy; Google Drive (`appDataFolder`) keeps a
backup per Google account.

- Before its first upload for an account, a device compares the local and the
  cloud copies (cars, records, last entry date). An empty phone restores the
  cloud copy; a missing or empty cloud copy is replaced; identical copies need
  nothing. When the copies differ, nothing is uploaded until the user chooses
  which copy to keep (`lib/services/cloud_sync_policy.dart`).
- Before the cloud backup is replaced, Drive keeps a dated copy
  (`autoubc_backup_YYYY-MM-DD.isar`: the 14 newest plus one per month for six
  months). Before the local database is replaced, the current file is copied
  to the local backup folder.
- Downloads go to a temporary file and are opened with the current schemas
  before the short, exclusive file swap.
- Local backups (`AutoUBC_Backups`): the 3 newest, one per day for 7 days, one
  per week for 4 weeks, and 5 copies made before a restore or a car deletion.
- Uploads run 30 seconds after the last change and when the app goes to the
  background.

Android system backup explicitly excludes `files/autoubc`, the active Isar
database directory, so a reinstall restores data only through the in-app
Google Drive flow.

## Continuous integration

`.github/workflows/ci.yml` runs on every push and pull request: it checks that
generated code (`build_runner`, `gen-l10n`, `pubspec.lock`) is committed and up
to date, runs `dart analyze` and `flutter test` (with `TZ=Europe/Kyiv`, so the
daylight-saving tests are meaningful) and builds a debug APK. Results appear as
annotations on the commit; for branches other than `main` the raw output is
also pushed to `ci-output/<branch>`.

## Release signing

Release APKs must be signed with the project's own key, not the debug key:

1. Create the keystore once and fill in `android/key.properties` as described
   in `android/key.properties.example`. Never commit either file; keep both in
   a password manager or another safe place. Without them no update can be
   installed over a released APK.
2. Add the SHA-1 of the release certificate to the Android OAuth client of
   `com.driver.autoubc` in Google Cloud Console, otherwise Google sign-in fails
   in release builds.
3. Increase `version` in `pubspec.yaml` (for example `1.5.1+2026` → `1.5.2+2027`;
   the build number must always grow, it is the Android versionCode)
   for every APK that is handed out.

`build.ps1` refuses to build without `android/key.properties`;
`build.ps1 -AllowDebugSigning` builds a test APK with the debug key. An APK
signed with another key cannot be installed over the existing app: the old app
has to be removed first, so make sure its data is in Google Drive (the sync
dot shows green) before switching.

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
