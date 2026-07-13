import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/data_entry_screen.dart';
import 'screens/history_screen.dart';
import 'screens/weekly_report_screen.dart';
import 'screens/export_report_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/service_book_screen.dart';
import 'screens/manage_cars_screen.dart';
import 'db/database_service.dart';
import 'models/reminder.dart';
import 'services/google_drive_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'uk';
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();
  runApp(MyApp(localeProvider: localeProvider));
}

class MyApp extends StatelessWidget {
  final LocaleProvider? localeProvider;

  const MyApp({super.key, this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (localeProvider != null)
          ChangeNotifierProvider.value(value: localeProvider!)
        else
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => GoogleDriveSyncService()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'AutoUBC',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0D47A1), // Deep corporate blue
                primary: const Color(0xFF1565C0),
                surface: const Color(
                    0xFFF8FAFC), // Light greyish blue for app background
              ),
              scaffoldBackgroundColor:
                  const Color(0xFFF8FAFC), // background color
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
              cardTheme: CardTheme(
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            localizationsDelegates: const [
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
            locale: localeProvider.locale,
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  final DatabaseService _db = DatabaseService();
  final int _totalPages = 3;
  static const int _initialPage = 1000; // Велике число для кругової прокрутки
  int _currentDisplayPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: _initialPage + _currentDisplayPage);

    // Тихий вхід у Google при старті
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sync = Provider.of<GoogleDriveSyncService>(context, listen: false);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final dbService = DatabaseService();
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final loc = AppLocalizations.of(context)!;

      // Налаштовуємо авто-синхронізацію при кожному збереженні даних
      appProvider.onDataSaved = () async {
        if (sync.isConnected) {
          final dbPath = await dbService.getDatabasePath();
          return await sync.uploadBackup(dbPath);
        }
        return false; // Не подключено к Google Drive — синхронізація не удалася
      };

      await sync.signInSilently();
      if (sync.isConnected) {
        await appProvider.loadCars();
        if (appProvider.cars.isEmpty) {
          final dbPath = await dbService.getDatabasePath();
          await dbService.close();
          final downloaded = await sync.downloadBackup(dbPath);
          if (downloaded && mounted) {
            await appProvider.refreshAll();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(loc.dataRestoredFromGoogleDrive),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          final dbPath = await dbService.getDatabasePath();
          unawaited(sync.uploadBackup(dbPath));
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Отримати реальний індекс сторінки для відображення
  int _getRealIndex(int index) {
    return (index - _initialPage) % _totalPages;
  }

  // Перевірка статусу нагадувань
  (bool, bool) _checkReminders(AppProvider provider) {
    if (provider.selectedCar == null) return (false, false);

    bool hasUpcoming = false;
    bool hasOverdue = false;
    final now = DateTime.now();

    for (final reminder in provider.reminders) {
      if (reminder.isCompleted) continue;

      if (reminder.type == ReminderType.maintenance ||
          (reminder.type == ReminderType.custom && reminder.repeatKm != null)) {
        final odometerLogs = provider.odometerLogs;
        final currentKm =
            odometerLogs.isNotEmpty ? odometerLogs.first.odometer : 0;
        final dueKm = (reminder.startKm ?? 0) + (reminder.repeatKm ?? 0);
        if (currentKm >= dueKm - 1000 && currentKm < dueKm) hasUpcoming = true;
        if (currentKm >= dueKm) hasOverdue = true;
      } else {
        if (reminder.dueDate.isBefore(now.add(const Duration(days: 7))) &&
            !reminder.dueDate.isBefore(now)) hasUpcoming = true;
        if (reminder.dueDate.isBefore(now)) hasOverdue = true;
      }
    }
    return (hasOverdue, hasUpcoming);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, provider, child) {
            return Text(provider.selectedCar?.name ?? 'AutoUBC');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: loc.exportReports,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExportReportScreen()),
              );
            },
          ),
          Consumer2<AppProvider, LocaleProvider>(
            builder: (context, provider, localeProvider, child) {
              final (hasOverdue, hasUpcoming) = _checkReminders(provider);
              return Stack(
                children: [
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'manage_cars',
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car,
                                size: 20, color: Colors.blue),
                            const SizedBox(width: 12),
                            Text(loc.carSettings),
                          ],
                        ),
                      ),
                      if (provider.cars.isNotEmpty) ...[
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'reminders',
                          child: Row(
                            children: [
                              Icon(
                                hasOverdue
                                    ? Icons.warning
                                    : (hasUpcoming
                                        ? Icons.warning_amber
                                        : Icons.notifications_none),
                                size: 20,
                                color: hasOverdue
                                    ? Colors.red
                                    : (hasUpcoming
                                        ? Colors.orange
                                        : Colors.blue),
                              ),
                              const SizedBox(width: 12),
                              Text(loc.reminders),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'service_book',
                          child: Row(
                            children: [
                              const Icon(Icons.book,
                                  size: 20, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(loc.serviceBook),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuDivider(),
                      // Секція мови
                      PopupMenuItem(
                        value: 'language',
                        child: Row(
                          children: [
                            const Icon(Icons.language,
                                size: 20, color: Colors.blue),
                            const SizedBox(width: 12),
                            Text(loc.language),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      // Google Drive секція
                      if (!Provider.of<GoogleDriveSyncService>(context,
                              listen: false)
                          .isConnected)
                        PopupMenuItem(
                          value: 'google_sign_in',
                          child: Row(
                            children: [
                              const Icon(Icons.login,
                                  size: 20, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(loc.signInToGoogleDrive),
                            ],
                          ),
                        )
                      else ...[
                        PopupMenuItem(
                          value: 'google_sign_out',
                          child: Row(
                            children: [
                              const Icon(Icons.logout,
                                  size: 20, color: Colors.grey),
                              const SizedBox(width: 12),
                              Text(loc.signOutFromGoogle),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasOverdue || hasUpcoming)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: hasOverdue ? Colors.red : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.cars.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  loc.addACarToGetStarted,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentDisplayPage = _getRealIndex(index);
                    });
                  },
                  itemBuilder: (context, index) {
                    final realIndex = _getRealIndex(index);
                    switch (realIndex) {
                      case 0:
                        return const DataEntryScreen();
                      case 1:
                        return const HistoryScreen();
                      case 2:
                        return const WeeklyReportScreen();
                      default:
                        return const DataEntryScreen();
                    }
                  },
                ),
              ),
              // Індикатори
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalPages, (index) {
                    final isSelected = _currentDisplayPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: isSelected ? 24.0 : 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    final sync = Provider.of<GoogleDriveSyncService>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;

    switch (action) {
      case 'manage_cars':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageCarsScreen()),
        );
        break;
      case 'reminders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RemindersScreen()),
        );
        break;
      case 'service_book':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServiceBookScreen()),
        );
        break;
      case 'language':
        _showLanguageDialog();
        break;
      case 'google_sign_in':
        final success = await sync.signIn();
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(
                success ? loc.connectedToGoogleDrive : loc.connectionFailed),
          ));
        }
        if (success) {
          await appProvider.loadCars();
          if (appProvider.cars.isEmpty) {
            final dbPath = await _db.getDatabasePath();
            await _db.close();
            final downloaded = await sync.downloadBackup(dbPath);
            if (downloaded && mounted) {
              await appProvider.refreshAll();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(loc.dataRestoredFromGoogleDrive),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            final dbPath = await _db.getDatabasePath();
            unawaited(sync.uploadBackup(dbPath));
          }
        }
        break;
      case 'google_sign_out':
        await sync.signOut();
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(loc.signedOutFromGoogleDrive)),
          );
        }
        break;
    }
  }

  void _showLanguageDialog() {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.selectLanguage),
        content: Consumer<LocaleProvider>(
          builder: (context, lp, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(loc.english),
                trailing: lp.locale?.languageCode == 'en'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  lp.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(loc.russian),
                trailing: lp.locale?.languageCode == 'ru'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  lp.setLocale(const Locale('ru'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(loc.ukrainian),
                trailing: lp.locale?.languageCode == 'uk'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  lp.setLocale(const Locale('uk'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
        ],
      ),
    );
  }
}
