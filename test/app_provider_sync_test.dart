import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autoubc/providers/app_provider.dart';

class _TestAppProvider extends AppProvider {
  @override
  Future<void> loadCars() async {}
}

void main() {
  test('sync completion does not notify the widget tree', () async {
    SharedPreferences.setMockInitialValues({
      'autoubc_pending_sync': true,
    });
    final provider = _TestAppProvider();
    addTearDown(provider.dispose);

    var notifications = 0;
    provider.addListener(() => notifications++);
    await provider.initialization;
    await provider.markSyncCompleted();

    expect(provider.hasPendingSync, isFalse);
    expect(notifications, 0);
  });

  test('lifecycle flush skips uploads when there are no pending changes', () async {
    SharedPreferences.setMockInitialValues({
      'autoubc_pending_sync': false,
    });
    final provider = _TestAppProvider();
    addTearDown(provider.dispose);

    var uploadCalls = 0;
    provider.onDataSaved = () async {
      uploadCalls++;
      return true;
    };
    await provider.initialization;

    final synced = await provider.flushPendingSync();

    expect(synced, isTrue);
    expect(uploadCalls, 0);
    expect(provider.hasPendingSync, isFalse);
  });
}
