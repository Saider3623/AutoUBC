## Changes Made

### 1. Made compatibility repair non-blocking
- **File:** `lib/db/database_service.dart`
- **Change:** Wrapped legacy `carId`/`IsarLink` repair in a guarded `try/catch` so a malformed or duplicate child record cannot prevent the valid `Car` collection from opening.
- **Why:** The observed behavior is consistent with a database opening while the initial provider read fails, then becoming usable after a later write/read triggered by adding a car.
- **Revert:** Restore the direct `_repairCarIdsFromLinks(_isar!)` call.

### 2. Reopened Isar after replacing the database file
- **Files:** `lib/db/database_service.dart`, `lib/main.dart`
- **Change:** Added `DatabaseService.reopen()` and call it after a successful cloud download, before `AppProvider.refreshAll()`.
- **Why:** Download replaces `autoubc.isar` while Isar is closed. The next provider refresh must explicitly open the new file and must not rely on a previously cached instance.
- **Revert:** Remove `reopen()` and the explicit calls after download.

### 3. Serialized AppProvider car loading
- **File:** `lib/providers/app_provider.dart`
- **Change:** Added `_loadCarsFuture`; concurrent `loadCars()` calls now share one operation, and errors include stack traces.
- **Why:** Prevents a startup refresh and a post-restore refresh from racing and leaving the visible state empty.
- **Revert:** Restore the original `loadCars() async` method.

### 4. Strengthened snapshot validation
- **File:** `lib/db/database_service.dart`
- **Change:** Snapshot validation now reads the restored `Car` collection and logs the verified car count instead of only opening the file.
- **Why:** A schema-compatible but empty or wrong file must be distinguishable from a backup containing vehicle data.
- **Revert:** Restore validation to open-and-return-true behavior.

### 5. Extended lifecycle regression test
- **File:** `test/database_service_lifecycle_test.dart`
- **Change:** Verifies concurrent `isar` access shares one instance and that close/reopen returns a fresh open instance.
- **Revert:** Remove the concurrent-open assertion or delete the test file.

## Verification

- `flutter analyze`: `No issues found!`
- `flutter test`: all tests passed; native Isar and application-storage checks were skipped by the isolated desktop runner.
- `flutter build apk --debug`: successful.

## Current Diagnostic Conclusion

The user report that adding a second car makes the restored car appear indicates that the cloud file is likely downloaded, but the first provider refresh is not reliably reading the newly replaced file. The permanent fix now explicitly reopens Isar, serializes provider reads, and prevents legacy repair errors from hiding valid cars.

A real Android retest is still required because the current environment has no connected Android device and cannot execute native Isar storage behavior.

## Revert Status

- [ ] Change 1
- [ ] Change 2
- [ ] Change 3
- [ ] Change 4
- [ ] Change 5
