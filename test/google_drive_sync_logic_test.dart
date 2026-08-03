import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:autoubc/services/google_drive_sync_service.dart';

void main() {
  group('local-first startup decisions', () {
    test('downloads when the local database is empty and remote exists', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: false,
          remoteExists: true,
        ),
        SyncStartupAction.download,
      );
    });

    test('restores remote data even if a stale pending marker remains', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: false,
          remoteExists: true,
          hasPendingLocalChanges: true,
        ),
        SyncStartupAction.download,
      );
    });

    test('stays local when both local and remote databases exist', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: true,
          remoteExists: true,
        ),
        SyncStartupAction.none,
      );
    });

    test('keeps an empty first install idle when the cloud is empty', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: false,
          remoteExists: false,
        ),
        SyncStartupAction.none,
      );
    });

    test('uploads pending local changes without checking for a conflict', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: true,
          remoteExists: true,
          hasPendingLocalChanges: true,
        ),
        SyncStartupAction.upload,
      );
    });

    test('uploads pending local changes even when the remote is missing', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: true,
          remoteExists: false,
          hasPendingLocalChanges: true,
        ),
        SyncStartupAction.upload,
      );
    });
  });

  test('selects the newest valid backup when Drive returns duplicates', () {
    final older = drive.File()
      ..id = 'older'
      ..name = 'autoubc_backup.isar'
      ..modifiedTime = DateTime.utc(2026, 8, 1);
    final newer = drive.File()
      ..id = 'newer'
      ..name = 'autoubc_backup.isar'
      ..modifiedTime = DateTime.utc(2026, 8, 2);

    expect(selectNewestBackupFile([older, newer])?.id, 'newer');
  });
}
