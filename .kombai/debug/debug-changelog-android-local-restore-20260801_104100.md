## Symptom

After reinstalling AutoUBC, the app showed local data through 30.08 before Google sign-in. The Google Drive copy contained data through 31.08. Accepting the cloud copy restored 31.08, but uninstalling and reinstalling brought back the 30.08 state.

## Root Cause

The 30.08 file was not necessarily an old Google Drive backup. Android's automatic app backup could restore the previous local Isar directory (`files/autoubc`) during reinstall or device transfer. AutoUBC then displayed that restored local database before the Google Drive handshake ran.

The in-app Google Drive download already replaces the active Isar file atomically. The confusing behavior came from Android resurrecting the old local file on the next installation.

## Changes Made

- Added `android/app/src/main/res/xml/backup_rules.xml`.
- Added `android/app/src/main/res/xml/data_extraction_rules.xml`.
- Updated `android/app/src/main/AndroidManifest.xml` with:
  - `android:allowBackup="false"`;
  - `android:fullBackupContent="@xml/backup_rules"`;
  - `android:dataExtractionRules="@xml/data_extraction_rules"`.
- Excluded `file/autoubc` from cloud backup and device transfer rules as defense in depth.
- Documented that the active Isar database is restored only through the in-app Google Drive flow in `README.md`.

## Verification

- `flutter analyze`: no issues.
- `flutter test`: all available tests passed; native Isar tests remain skipped in the isolated desktop runner.
- `flutter build apk --debug`: successful.
- Generated platform files and the checked-in `AutoUBC.apk` were restored after verification.

## Android Retest

Install the new APK after fully uninstalling the previous app. The first launch should not show the old 30.08 local data. After Google sign-in, the startup handshake should download the 31.08 cloud database.

If Android still shows 30.08 after a normal uninstall, clear the app's backup data in the device/Google backup settings or use `adb shell bmgr wipe` for the package, because an already-created backup dataset may be retained independently of the new manifest.

## Revert Status

- [ ] Restore the previous Android manifest attributes.
- [ ] Delete `android/app/src/main/res/xml/backup_rules.xml`.
- [ ] Delete `android/app/src/main/res/xml/data_extraction_rules.xml`.
- [ ] Remove the README data-safety paragraph.
