import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:autoubc/services/google_drive_sync_service.dart';

void main() {
  group('sync status presentation', () {
    test('keeps a connected session neutral before the first success', () {
      expect(
        effectiveSyncStatus(
          status: SyncStatus.unknown,
          activeOperations: 0,
        ),
        SyncStatus.unknown,
      );
    });

    test('active operations always present as syncing', () {
      expect(
        effectiveSyncStatus(
          status: SyncStatus.error,
          activeOperations: 1,
        ),
        SyncStatus.syncing,
      );
    });

    test('preserves idle and error after operations finish', () {
      expect(
        effectiveSyncStatus(
          status: SyncStatus.idle,
          activeOperations: 0,
        ),
        SyncStatus.idle,
      );
      expect(
        effectiveSyncStatus(
          status: SyncStatus.error,
          activeOperations: 0,
        ),
        SyncStatus.error,
      );
    });
  });

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

  group('first-car setup prompt', () {
    test('prompts after a connected empty startup with no sync action', () {
      expect(
        shouldPromptForFirstCarSetup(
          isConnected: true,
          hasCars: false,
          syncAction: SyncStartupAction.none,
        ),
        isTrue,
      );
    });

    test('does not prompt when a car already exists', () {
      expect(
        shouldPromptForFirstCarSetup(
          isConnected: true,
          hasCars: true,
          syncAction: SyncStartupAction.none,
        ),
        isFalse,
      );
    });

    test('prompts after restoring an empty cloud database', () {
      expect(
        shouldPromptForFirstCarSetup(
          isConnected: true,
          hasCars: false,
          syncAction: SyncStartupAction.download,
        ),
        isTrue,
      );
    });

    test('does not prompt when cloud synchronization fails', () {
      expect(
        shouldPromptForFirstCarSetup(
          isConnected: true,
          hasCars: false,
          syncAction: SyncStartupAction.error,
        ),
        isFalse,
      );
    });

    test('does not prompt when the account is disconnected', () {
      expect(
        shouldPromptForFirstCarSetup(
          isConnected: false,
          hasCars: false,
          syncAction: SyncStartupAction.none,
        ),
        isFalse,
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
