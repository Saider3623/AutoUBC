import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'package:autoubc/services/google_drive_sync_service.dart';

void main() {
  group('sync startup decisions', () {
    test('downloads when only the remote backup exists', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: false,
          remoteExists: true,
        ),
        SyncStartupAction.download,
      );
    });

    test('uploads when only local data exists', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: true,
          remoteExists: false,
        ),
        SyncStartupAction.upload,
      );
    });

    test('keeps an empty first install idle after checking an empty cloud', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: false,
          remoteExists: false,
        ),
        SyncStartupAction.none,
      );
    });

    test('keeps matching local and remote baselines idle', () {
      final baseline = DateTime.utc(2026, 8, 2, 4, 0);
      expect(
        resolveSyncStartupAction(
          hasLocalData: true,
          remoteExists: true,
          lastKnownRemoteModified: baseline.toLocal(),
          remoteModified: baseline,
        ),
        SyncStartupAction.none,
      );
    });

    test('requires confirmation for two data sets without a matching baseline', () {
      expect(
        resolveSyncStartupAction(
          hasLocalData: true,
          remoteExists: true,
          lastKnownRemoteModified: DateTime.utc(2026, 8, 1),
          remoteModified: DateTime.utc(2026, 8, 2),
        ),
        SyncStartupAction.conflict,
      );
    });

    test('does not hide pending local edits behind a matching baseline', () {
      final baseline = DateTime.utc(2026, 8, 2);
      expect(
        resolveSyncStartupAction(
          hasLocalData: true,
          remoteExists: true,
          hasPendingLocalChanges: true,
          lastKnownRemoteModified: baseline,
          remoteModified: baseline,
        ),
        SyncStartupAction.conflict,
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
