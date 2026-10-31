import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:autoubc/db/database_service.dart';

import 'support/test_database.dart';

void main() {
  Directory? root;

  setUpAll(() async => root = await useTemporaryDatabase());
  tearDownAll(() => disposeTemporaryDatabase(root));

  test('database service reopens cleanly after close', () async {
    if (root == null) {
      markTestSkipped(
          'Isar native library is unavailable in this test runner.');
      return;
    }
    final database = DatabaseService();

    final opened = await Future.wait([database.isar, database.isar]);
    final first = opened.first;
    expect(identical(first, opened.last), isTrue);

    // Closing while another lifecycle request is queued must not race with
    // initialization or reopen the same Isar instance twice.
    await Future.wait([database.close(), database.reopen()]);
    final reopened = await database.isar;

    expect(reopened.isOpen, isTrue);
    expect(identical(first, reopened), isFalse);

    final concurrentReopens = await Future.wait([
      database.reopen(),
      database.reopen(),
    ]);
    expect(identical(concurrentReopens.first, concurrentReopens.last), isTrue);
  });
}
