import 'dart:io';

import 'package:isar/isar.dart';

import 'package:autoubc/db/database_service.dart';

bool? _isarCoreReady;

/// Loads the native Isar library for `flutter test`. The plugin library is
/// not bundled with unit tests, so Isar downloads the core for the host once
/// (next to the project; ignored by git). Returns `false` without network.
Future<bool> ensureIsarCore() async {
  final ready = _isarCoreReady;
  if (ready != null) return ready;
  try {
    await Isar.initializeIsarCore(download: true)
        .timeout(const Duration(seconds: 60));
    _isarCoreReady = true;
  } catch (error) {
    // ignore: avoid_print
    print('Isar core is unavailable, database tests are skipped: $error');
    _isarCoreReady = false;
  }
  return _isarCoreReady!;
}

/// Points [DatabaseService] at a fresh temporary folder. Returns `null` when
/// the native Isar library cannot be loaded.
Future<Directory?> useTemporaryDatabase() async {
  if (!await ensureIsarCore()) return null;
  final root = await Directory.systemTemp.createTemp('autoubc_db_test_');
  DatabaseService.debugStorageRoot = root;
  return root;
}

/// Closes the database and removes the temporary folder.
Future<void> disposeTemporaryDatabase(Directory? root) async {
  await DatabaseService().close();
  DatabaseService.debugStorageRoot = null;
  if (root != null && await root.exists()) {
    await root.delete(recursive: true);
  }
}

/// Removes every record, so each test starts from an empty database.
Future<void> clearDatabase() async {
  final db = await DatabaseService().isar;
  await db.writeTxn(() => db.clear());
}
