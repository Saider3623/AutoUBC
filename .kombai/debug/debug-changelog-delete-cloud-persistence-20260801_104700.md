## Symptom

A test car was removed after restoring the cloud database. After signing out, uninstalling, reinstalling, and signing in again, the test car returned.

## Root Cause

`AppProvider.deleteCar()` only scheduled Google Drive upload through a three-second debounce timer. If the app was closed or removed before the timer completed, the local deletion remained local and Google Drive still contained the old car. The next restore correctly downloaded that older cloud database.

## Changes Made

- Added `AppProvider.flushPendingSync()`.
- `deleteCar()` now performs an immediate snapshot and upload attempt instead of waiting for the debounce timer.
- Google sign-out flushes pending changes before clearing the account session.
- App shutdown performs a forced final sync attempt when a debounce timer is active.
- Sync failures set `_needsSync` and include a stack trace in debug output instead of being silently discarded.
- Documented immediate deletion sync in `README.md`.

## Verification

- `flutter analyze`: no issues.
- `flutter test`: all available tests passed; native Isar tests remain skipped in the isolated desktop runner.
- `flutter build apk --debug`: successful.

## Remaining Risk

An Android process can still be terminated before any asynchronous network request completes. The immediate flush removes the normal debounce window, but it cannot guarantee delivery after an OS-level force-stop or abrupt power loss. A follow-up retry is still possible through `_needsSync` while the same app installation remains available.
