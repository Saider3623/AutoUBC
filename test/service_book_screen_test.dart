import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autoubc/l10n/app_localizations.dart';
import 'package:autoubc/models/car.dart';
import 'package:autoubc/models/reminder.dart';
import 'package:autoubc/models/service_log.dart';
import 'package:autoubc/providers/app_provider.dart';
import 'package:autoubc/providers/locale_provider.dart';
import 'package:autoubc/screens/service_book_screen.dart';

class _ServiceBookProvider extends AppProvider {
  @override
  final selectedCar = Car()..id = 1;

  @override
  final reminders = [
    Reminder()
      ..carId = 1
      ..type = ReminderType.maintenance
      ..startKm = 10000
      ..repeatKm = 10000,
  ];

  @override
  final serviceLogs = <ServiceLog>[];

  @override
  Future<void> loadCars() async {}

  @override
  Future<void> addServiceLog(ServiceLog log) async {
    serviceLogs.add(log);
    notifyListeners();
  }
}

void main() {
  testWidgets('saves ordinary service work without a maintenance prompt',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appProvider = _ServiceBookProvider();
    final localeProvider = LocaleProvider();
    addTearDown(appProvider.dispose);
    addTearDown(localeProvider.dispose);
    await appProvider.initialization;

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppProvider>.value(value: appProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('uk'),
        home: ServiceBookScreen(),
      ),
    ));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    const work = 'Заміна лампи фари';
    await tester.enterText(find.byType(TextFormField).last, work);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text(work), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
