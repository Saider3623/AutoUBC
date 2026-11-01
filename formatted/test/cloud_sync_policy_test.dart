import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/services/cloud_sync_policy.dart';

DatabaseSummary _summary({
  int cars = 1,
  int odometer = 0,
  int fuel = 0,
  int reminders = 0,
  int service = 0,
  int notes = 0,
  String? last,
}) {
  return DatabaseSummary(
    cars: cars,
    odometerLogs: odometer,
    fuelLogs: fuel,
    reminders: reminders,
    serviceLogs: service,
    notes: notes,
    lastEntryDate: last,
  );
}

void main() {
  group('resolveBaseline', () {
    final history = _summary(
      cars: 2,
      odometer: 180,
      fuel: 40,
      last: '2026-10-20',
    );

    test('first sign-in on a new phone restores the cloud history', () {
      expect(
        resolveBaseline(
          local: DatabaseSummary.empty,
          cloud: history,
          interactive: true,
        ),
        BaselineAction.restoreCloud,
      );
    });

    test('a car created before sign-in never overwrites the cloud history', () {
      // Audit scenario 1.1: a local car with two days of data, then sign-in.
      final fresh = _summary(odometer: 2, fuel: 1, last: '2026-10-29');
      expect(
        resolveBaseline(local: fresh, cloud: history, interactive: true),
        BaselineAction.ask,
      );
      expect(
        resolveBaseline(local: fresh, cloud: history, interactive: false),
        BaselineAction.ask,
      );
    });

    test(
      'a newer local copy of the same history is uploaded after an update',
      () {
        final newer = _summary(
          cars: 2,
          odometer: 182,
          fuel: 41,
          last: '2026-10-22',
        );
        expect(
          resolveBaseline(local: newer, cloud: history, interactive: false),
          BaselineAction.uploadLocal,
        );
        expect(
          resolveBaseline(local: newer, cloud: history, interactive: true),
          BaselineAction.ask,
        );
      },
    );

    test('a local copy with fewer records is never treated as newer', () {
      final shorter = _summary(
        cars: 2,
        odometer: 170,
        fuel: 45,
        last: '2026-10-25',
      );
      expect(
        resolveBaseline(local: shorter, cloud: history, interactive: false),
        BaselineAction.ask,
      );
    });

    test('identical copies need no transfer', () {
      expect(
        resolveBaseline(local: history, cloud: history, interactive: true),
        BaselineAction.alreadyInSync,
      );
    });

    test('without a cloud backup local data becomes the first copy', () {
      expect(
        resolveBaseline(local: history, cloud: null, interactive: true),
        BaselineAction.uploadLocal,
      );
      expect(
        resolveBaseline(
          local: DatabaseSummary.empty,
          cloud: null,
          interactive: false,
        ),
        BaselineAction.alreadyInSync,
      );
    });

    test('an empty cloud backup can be replaced', () {
      expect(
        resolveBaseline(
          local: history,
          cloud: DatabaseSummary.empty,
          interactive: true,
        ),
        BaselineAction.uploadLocal,
      );
    });
  });

  group('dated cloud copies', () {
    test('names carry the date and, for explicit replacements, the time', () {
      final now = DateTime(2026, 10, 29, 8, 5, 9);
      expect(datedCloudCopyName(now), 'autoubc_backup_2026-10-29.isar');
      expect(
        datedCloudCopyName(now, unique: true),
        'autoubc_backup_2026-10-29_080509.isar',
      );
    });

    test('keeps the 14 newest copies and one copy per month for 6 months', () {
      final names = <String>[
        for (var day = 1; day <= 31; day++)
          'autoubc_backup_2026-10-${day.toString().padLeft(2, '0')}.isar',
        for (var month = 1; month <= 9; month++)
          'autoubc_backup_2026-0$month-15.isar',
        'autoubc_backup.isar',
        'unrelated.txt',
      ];

      final deleted = datedCopiesToDelete(names).toSet();
      final kept = names.toSet().difference(deleted);

      for (var day = 18; day <= 31; day++) {
        expect(kept, contains('autoubc_backup_2026-10-$day.isar'));
      }
      // One copy per month: October (newest) plus May–September.
      for (final month in ['05', '06', '07', '08', '09']) {
        expect(kept, contains('autoubc_backup_2026-$month-15.isar'));
      }
      expect(deleted, contains('autoubc_backup_2026-04-15.isar'));
      expect(deleted, contains('autoubc_backup_2026-10-10.isar'));
      expect(kept, contains('autoubc_backup.isar'));
      expect(kept, contains('unrelated.txt'));
    });
  });

  group('local backup rotation', () {
    test('keeps recent, daily, weekly and tagged copies', () {
      final names = <String>[
        // Five backups on the same busy day.
        for (final time in ['0800', '0805', '0810', '0815', '0820'])
          'autoubc_backup_20261029_$time.isar',
        // One backup per day for the previous 20 days.
        for (var day = 9; day <= 28; day++)
          'autoubc_backup_202610${day.toString().padLeft(2, '0')}_1200.isar',
        'autoubc_backup_20261001_0900_before-delete.isar',
        'autoubc_backup_20260901_0900_before-restore.isar',
      ];

      final deleted = localBackupsToDelete(names).toSet();
      final kept = names.toSet().difference(deleted);

      // Three newest backups of the busy day.
      expect(kept, contains('autoubc_backup_20261029_0820.isar'));
      expect(kept, contains('autoubc_backup_20261029_0815.isar'));
      expect(kept, contains('autoubc_backup_20261029_0810.isar'));
      expect(deleted, contains('autoubc_backup_20261029_0800.isar'));
      // The newest backup of each of the previous six days.
      for (var day = 23; day <= 28; day++) {
        expect(kept, contains('autoubc_backup_202610${day}_1200.isar'));
      }
      // Tagged copies are kept even when they are old.
      expect(kept, contains('autoubc_backup_20261001_0900_before-delete.isar'));
      expect(
        kept,
        contains('autoubc_backup_20260901_0900_before-restore.isar'),
      );
      // Weekly copies reach back four weeks, older daily ones are removed.
      expect(deleted, contains('autoubc_backup_20261010_1200.isar'));
    });
  });
}
