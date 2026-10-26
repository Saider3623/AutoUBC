import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autoubc/main.dart';
import 'package:autoubc/models/car.dart';
import 'package:autoubc/providers/app_provider.dart';
import 'package:autoubc/providers/locale_provider.dart';
import 'package:autoubc/services/google_drive_sync_service.dart';
import 'package:autoubc/l10n/app_localizations.dart';

class _EmptyAppProvider extends AppProvider {
  @override
  Future<void> get initialization => Future<void>.value();

  @override
  List<Car> get cars => const <Car>[];

  @override
  bool get isLoading => false;
}

void main() {
  testWidgets('renders the first-run AutoUBC setup actions',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final appProvider = _EmptyAppProvider();
    final localeProvider = LocaleProvider();
    await localeProvider.setLocale(const Locale('uk'));
    addTearDown(appProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleProvider>.value(
            value: localeProvider,
          ),
          ChangeNotifierProvider<AppProvider>.value(value: appProvider),
          ChangeNotifierProvider<GoogleDriveSyncService>.value(
            value: GoogleDriveSyncService(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
            Locale('uk'),
          ],
          locale: const Locale('uk'),
          home: const MainScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MainScreen), findsOneWidget);
    expect(find.text('Вітаємо в AutoUBC'), findsOneWidget);
    expect(
      find.text('Увійти та відновити з Google Drive'),
      findsOneWidget,
    );
    expect(
      find.text('Створити автомобіль без авторизації'),
      findsOneWidget,
    );
    expect(find.text('Додайте автомобіль, щоб почати'), findsNothing);

    // The startup silent sign-in is bounded by a timeout. The platform channel
    // never answers in this test environment, so advance time until that
    // deadline fires instead of leaving a pending timer behind.
    await tester.pump(const Duration(seconds: 16));
  });
}
