import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/data_entry_screen.dart';
import 'screens/weekly_report_screen.dart';
import 'screens/export_report_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/service_book_screen.dart';
import 'screens/manage_cars_screen.dart';
import 'db/database_service.dart';
import 'models/reminder.dart';
import 'services/google_drive_sync_service.dart';
import 'theme/app_theme.dart';
import 'widgets/sync_status_indicator.dart';
import 'services/remote_log_service.dart';

Future<void> _deleteFileIfExists(String path) async {
  try {
    await File(path).delete();
  } catch (_) {}
}

// #region debug-point D6:reporter
void _dbgMain(String h, String loc, String msg,
    [Map<String, Object?> data = const {}]) {
  RemoteLog.add('[DEBUG][$h] $loc: $msg${data.isEmpty ? '' : ' $data'}');
  http
      .post(
        Uri.parse('http://192.168.31.107:7777/event'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': 'startup-freeze-google-auth',
          'runId': 'pre-fix',
          'hypothesisId': h,
          'location': loc,
          'msg': '[DEBUG] $msg',
          'data': data,
        }),
      )
      .catchError((_) => http.Response('', 0));
}
// #endregion

Future<SyncStartupAction> _initializeCloudSync({
  required GoogleDriveSyncService sync,
  required AppProvider appProvider,
  required DatabaseService dbService,
  required bool restoreIfEmpty,
}) async {
  if (!sync.isConnected) return SyncStartupAction.none;

  // AppProvider starts loading immediately in its constructor. Await that
  // exact operation before deciding whether the local database is usable.
  // #region debug-point A:cloudinit
  _dbgMain(
      'A', 'main.dart:_initializeCloudSync', 'begin, await initialization');
  // #endregion
  await appProvider.initialization;
  // #region debug-point A:cloudinit
  _dbgMain('A', 'main.dart:_initializeCloudSync',
      'initialization done, cars=${appProvider.cars.length}');
  // #endregion
  final action = await sync.decideStartupAction(
    hasLocalData: appProvider.cars.isNotEmpty,
    hasPendingLocalChanges: appProvider.hasPendingSync,
    restoreIfEmpty: restoreIfEmpty,
  );
  // #region debug-point A:cloudinit
  _dbgMain('A', 'main.dart:_initializeCloudSync', 'action=$action');
  // #endregion

  switch (action) {
    case SyncStartupAction.download:
      final dbPath = await dbService.getDatabasePath();
      // The database stays closed for the whole download and is reopened before
      // any other queued request can run. Keeping the replacement inside a
      // single lifecycle operation stops the UI from reopening the database
      // while its file is being swapped, which deadlocks Isar and freezes the
      // app right after the first authorization.
      final downloaded = await dbService.withClosedDatabase(
        () => sync.downloadBackup(
          dbPath,
          validateFile: dbService.verifyDatabaseSnapshot,
        ),
      );
      // #region debug-point A:download
      _dbgMain('A', 'main.dart:_initializeCloudSync', 'download=$downloaded');
      // #endregion
      if (downloaded) {
        await appProvider.refreshAll();
        await appProvider.markSyncCompleted();
      }
      break;
    case SyncStartupAction.upload:
      final snapshotPath = await dbService.createDatabaseSnapshot();
      try {
        final uploaded = await sync.uploadBackup(snapshotPath);
        if (uploaded) await appProvider.markSyncCompleted();
      } finally {
        await _deleteFileIfExists(snapshotPath);
      }
      break;
    case SyncStartupAction.error:
    case SyncStartupAction.none:
      // Sync errors remain silent. Pending state is durable and will retry on
      // the next local mutation, lifecycle flush, or application launch.
      break;
  }

  return action;
}

void main() {
  // Captures all logs and uploads them when the build provides a log token;
  // otherwise it just runs the app.
  RemoteLog.run(_runApp);
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // #region debug-point A:startup
  _dbgMain('A', 'main.dart:main', 'app main started');
  // #endregion
  // #region debug-point G:heartbeat
  // UI-isolate liveness probe. Runs for the whole process lifetime, so if these
  // events stop while the process is still alive the UI thread is blocked.
  var hbTick = 0;
  Timer.periodic(const Duration(seconds: 1), (_) {
    hbTick++;
    _dbgMain('G', 'main.dart:heartbeat', 'ui alive elapsed=${hbTick}s');
  });
  // #endregion
  Intl.defaultLocale = 'uk';
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSavedSettings();
  runApp(MyApp(
    localeProvider: localeProvider,
    settingsProvider: settingsProvider,
  ));
}

class MyApp extends StatelessWidget {
  final LocaleProvider? localeProvider;
  final SettingsProvider? settingsProvider;

  const MyApp({super.key, this.localeProvider, this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (localeProvider != null)
          ChangeNotifierProvider.value(value: localeProvider!)
        else
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        if (settingsProvider != null)
          ChangeNotifierProvider.value(value: settingsProvider!)
        else
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => GoogleDriveSyncService()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'AutoUBC',
            theme: AppTheme.light(),
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  final DatabaseService _db = DatabaseService();
  AppProvider? _appProvider;
  GoogleDriveSyncService? _syncService;
  final int _totalPages = 2;
  static const int _initialPage = 1000; // Велике число для кругової прокрутки
  int _currentDisplayPage = 0;
  bool _isInteractiveSignIn = false;
  bool _isLifecycleSyncInProgress = false;
  // Serializes cloud initialization so two overlapping flows (automatic
  // startup sync and the manual "restore from Drive" action) can never close
  // and reopen the database at the same time. Concurrent close/reopen calls
  // deadlock Isar and freeze the UI thread (ANR).
  Future<void> _cloudInitQueue = Future<void>.value();

  /// Runs [operation] after any in-flight cloud initialization has finished.
  Future<T> _runGuardedCloudInit<T>(Future<T> Function() operation) {
    final result = _cloudInitQueue.then((_) => operation());
    _cloudInitQueue = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController =
        PageController(initialPage: _initialPage + _currentDisplayPage);

    // Тихий вхід у Google при старті
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // #region debug-point A:startup
      _dbgMain('A', 'main.dart:initState', 'postFrame begin');
      // #endregion
      final sync = Provider.of<GoogleDriveSyncService>(context, listen: false);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      _syncService = sync;
      _appProvider = appProvider;
      final dbService = DatabaseService();

      // Налаштовуємо авто-синхронізацію при кожному збереженні даних
      appProvider.onDataSaved = () async {
        if (!sync.isConnected) return false;
        final snapshotPath = await dbService.createDatabaseSnapshot();
        try {
          return await sync.uploadBackup(snapshotPath);
        } finally {
          await _deleteFileIfExists(snapshotPath);
        }
      };

      await sync.signInSilently();
      // #region debug-point A:startup
      _dbgMain('A', 'main.dart:initState',
          'signInSilently done, connected=${sync.isConnected}');
      // #endregion
      if (mounted) {
        final syncAction = await _runGuardedCloudInit(
          () => _initializeCloudSync(
            sync: sync,
            appProvider: appProvider,
            dbService: dbService,
            restoreIfEmpty: !dbService.hadDatabaseAtStartup,
          ),
        );
        // #region debug-point A:startup
        _dbgMain('A', 'main.dart:initState', 'cloud init finished=$syncAction');
        // #endregion
        await _promptForFirstCarIfNeeded(
          sync: sync,
          appProvider: appProvider,
          syncAction: syncAction,
        );
      }
    });
  }

  Future<void> _promptForFirstCarIfNeeded({
    required GoogleDriveSyncService sync,
    required AppProvider appProvider,
    required SyncStartupAction syncAction,
  }) async {
    if (!mounted ||
        !shouldPromptForFirstCarSetup(
          isConnected: sync.isConnected,
          hasCars: appProvider.cars.isNotEmpty,
          syncAction: syncAction,
        )) {
      return;
    }

    await _openManageCars(autoOpenAddCar: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached) {
      return;
    }

    final appProvider = _appProvider;
    if (_syncService?.isConnected == true &&
        appProvider != null &&
        appProvider.hasPendingSync &&
        !_isLifecycleSyncInProgress) {
      unawaited(_flushPendingSyncOnLifecycle(appProvider));
    }
  }

  Future<void> _flushPendingSyncOnLifecycle(AppProvider appProvider) async {
    _isLifecycleSyncInProgress = true;
    try {
      await appProvider.flushPendingSync();
    } finally {
      _isLifecycleSyncInProgress = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
            !reminder.dueDate.isBefore(now)) {
          hasUpcoming = true;
        }
        if (reminder.dueDate.isBefore(now)) {
          hasOverdue = true;
        }
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
        title: Consumer2<AppProvider, GoogleDriveSyncService>(
          builder: (context, provider, sync, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    provider.selectedCar?.name ?? 'AutoUBC',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // The indicator slot keeps a fixed width so its appearance or
                // disappearance never shifts the car name.
                const SizedBox(width: 10),
                SyncStatusIndicator(sync: sync),
              ],
            );
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
          if (provider.isLoading && provider.cars.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.cars.isEmpty) {
            return _buildEmptyState(loc);
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
                            : colorScheme.primary.withValues(alpha: 0.3),
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

  Widget _buildEmptyState(AppLocalizations loc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sync = Provider.of<GoogleDriveSyncService>(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.directions_car_filled,
                          size: 34,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      loc.welcomeToAutoUbc,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sync.isConnected
                          ? loc.addACarToGetStarted
                          : loc.firstLaunchDescription,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (sync.isConnected)
                      FilledButton.icon(
                        onPressed: _isInteractiveSignIn
                            ? null
                            : () => _openManageCars(autoOpenAddCar: true),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(loc.addCar),
                      )
                    else ...[
                      FilledButton.icon(
                        onPressed:
                            _isInteractiveSignIn ? null : _signInToGoogle,
                        icon: _isInteractiveSignIn
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.cloud_download_outlined),
                        label: Text(_isInteractiveSignIn
                            ? loc.connectingToGoogleDrive
                            : loc.restoreFromGoogleDrive),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _isInteractiveSignIn ? null : _openManageCars,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(loc.createCarLocally),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInToGoogle() async {
    if (_isInteractiveSignIn) return;

    setState(() => _isInteractiveSignIn = true);
    final sync = Provider.of<GoogleDriveSyncService>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    try {
      final success = await sync.signIn();
      if (!mounted) return;

      if (success) {
        final syncAction = await _runGuardedCloudInit(
          () => _initializeCloudSync(
            sync: sync,
            appProvider: appProvider,
            dbService: _db,
            restoreIfEmpty: true,
          ),
        );
        await _promptForFirstCarIfNeeded(
          sync: sync,
          appProvider: appProvider,
          syncAction: syncAction,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInteractiveSignIn = false);
      }
    }
  }

  Future<void> _openManageCars({bool autoOpenAddCar = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageCarsScreen(autoOpenAddCar: autoOpenAddCar),
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    final sync = Provider.of<GoogleDriveSyncService>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    switch (action) {
      case 'manage_cars':
        await _openManageCars();
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
        await _signInToGoogle();
        break;
      case 'google_sign_out':
        // Flush the latest local state before disconnecting the account. This
        // keeps deletions and other recent edits from remaining only locally.
        await appProvider.flushPendingSync();
        await sync.signOut();
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
