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
