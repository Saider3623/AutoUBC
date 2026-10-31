import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:isar/isar.dart';

import 'package:autoubc/db/database_service.dart';

bool? _isarCoreReady;

/// Loads the native Isar library for `flutter test`. The plugin library is
/// not bundled with unit tests, so the core for the host is downloaded once
/// into a cache in the system temp folder. Returns `false` without network.
///
/// Test files run in parallel processes. Each process downloads into its own
/// file and only then renames it into the cache, so no process ever loads a
/// file that another one is still writing (on Windows that failed with
/// "being used by another process").
Future<bool> ensureIsarCore() async {
  final ready = _isarCoreReady;
  if (ready != null) return ready;
  _isarCoreReady = await _loadIsarCore();
  return _isarCoreReady!;
}

Future<bool> _loadIsarCore() async {
  final separator = Platform.pathSeparator;
  final name = Platform.isWindows
      ? 'isar.dll'
      : Platform.isMacOS
          ? 'libisar.dylib'
          : 'libisar.so';
  final cacheDir = Directory(
      '${Directory.systemTemp.path}${separator}autoubc_isar_core_${Isar.version}');
  final cached = File('${cacheDir.path}$separator$name');
  try {
    await cacheDir.create(recursive: true);
    if (await cached.exists()) {
      await Isar.initializeIsarCore(libraries: {Abi.current(): cached.path});
      return true;
    }
  } catch (_) {
    // A damaged cache file: download a fresh copy below.
  }
  final own = File('${cacheDir.path}$separator${pid}_$name');
  try {
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): own.path},
      download: true,
    ).timeout(const Duration(seconds: 60));
  } catch (error) {
    // ignore: avoid_print
    print('Isar core is unavailable, database tests are skipped: $error');
    return false;
  }
  try {
    if (!await cached.exists()) await own.rename(cached.path);
  } catch (_) {
    // Another process filled the cache first; this copy stays in use.
  }
  return true;
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
