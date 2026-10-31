import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/data_entry_screen.dart';
import 'screens/weekly_report_screen.dart';
import 'screens/export_report_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/service_book_screen.dart';
import 'screens/manage_cars_screen.dart';
import 'models/reminder.dart';
import 'services/cloud_sync_controller.dart';
import 'services/google_drive_sync_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_empty_state.dart';
import 'widgets/cloud_comparison_dialog.dart';
import 'widgets/sync_status_indicator.dart';

Future<void> main() async {
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
        ChangeNotifierProvider(
          create: (context) => CloudSyncController(
            app: context.read<AppProvider>(),
            drive: context.read<GoogleDriveSyncService>(),
          ),
        ),
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
  AppProvider? _appProvider;
  CloudSyncController? _cloud;
  final int _totalPages = 2;
  static const int _initialPage = 1000; // A large index for circular paging.
  int _currentDisplayPage = 0;
  bool _isInteractiveSignIn = false;
  bool _isLifecycleSyncInProgress = false;
  bool _isDecisionDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController =
        PageController(initialPage: _initialPage + _currentDisplayPage);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cloud = context.read<CloudSyncController>();
      _appProvider = context.read<AppProvider>();
      _cloud = cloud;
      cloud.addListener(_onCloudChanged);
      final result = await cloud.start();
      await _promptForFirstCarIfNeeded(result);
    });
  }

  /// Opens the decision dialog as soon as the copies are found to differ.
  void _onCloudChanged() {
    final cloud = _cloud;
    if (cloud == null || !mounted) return;
    if (cloud.needsDecision && !_isDecisionDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDecision());
    }
  }

  Future<void> _showDecision() async {
    final cloud = _cloud;
    final comparison = cloud?.comparison;
    if (cloud == null ||
        comparison == null ||
        !cloud.needsDecision ||
        _isDecisionDialogOpen ||
        !mounted) {
      return;
    }
    _isDecisionDialogOpen = true;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final choice = await showCloudConflictDialog(context, comparison);
      if (choice == null) return;
      final resolved = await cloud.resolveConflict(choice);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(resolved
            ? (choice == ConflictChoice.useCloud
                ? loc.cloudRestored
                : loc.cloudUploaded)
            : loc.cloudOperationFailed),
      ));
      if (resolved) await _promptForFirstCarIfNeeded(CloudFlowResult.restored);
    } finally {
      _isDecisionDialogOpen = false;
    }
  }

  Future<void> _promptForFirstCarIfNeeded(CloudFlowResult result) async {
    final cloud = _cloud;
    final appProvider = _appProvider;
    if (!mounted || cloud == null || appProvider == null) return;
    final settled = result == CloudFlowResult.inSync ||
        result == CloudFlowResult.restored ||
        result == CloudFlowResult.uploaded;
    if (!cloud.isConnected ||
        !settled ||
        appProvider.loadError != null ||
        appProvider.cars.isNotEmpty) {
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
    if (_cloud?.isConnected == true &&
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
    _cloud?.removeListener(_onCloudChanged);
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
        title: Consumer2<AppProvider, CloudSyncController>(
          builder: (context, provider, cloud, child) {
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
                SyncStatusIndicator(
                  cloud: cloud,
                  onTap: cloud.needsDecision ? _showDecision : null,
                ),
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
                      // Google Drive section.
                      if (!context.read<CloudSyncController>().isConnected)
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
                          value: 'restore_from_drive',
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_download_outlined,
                                  size: 20, color: Colors.blue),
                              const SizedBox(width: 12),
                              Text(loc.restoreFromDriveMenu),
                            ],
                          ),
                        ),
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
          if (provider.loadError != null && provider.cars.isEmpty) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: loc.dataLoadErrorTitle,
              message: loc.dataLoadErrorBody,
              action: FilledButton(
                onPressed: provider.loadCars,
                child: Text(loc.retry),
              ),
            );
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
    final sync = context.watch<CloudSyncController>();

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
    final cloud = context.read<CloudSyncController>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await cloud.signIn();
      if (!mounted) return;
      if (result == CloudFlowResult.failed) {
        messenger.showSnackBar(
          SnackBar(content: Text(loc.cloudOperationFailed)),
        );
      } else if (result == CloudFlowResult.restored) {
        messenger.showSnackBar(SnackBar(content: Text(loc.cloudRestored)));
      }
      await _promptForFirstCarIfNeeded(result);
    } finally {
      if (mounted) {
        setState(() => _isInteractiveSignIn = false);
      }
    }
  }

  /// Restores the Google Drive copy after the user has compared both copies.
  Future<void> _restoreFromDrive() async {
    final cloud = context.read<CloudSyncController>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    CloudComparison? comparison;
    try {
      comparison = await runWithProgress(
        context,
        loc.cloudCheckingDrive,
        cloud.prepareRestore,
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(loc.cloudOperationFailed)));
      return;
    }
    if (!mounted) return;
    if (comparison == null) {
      messenger.showSnackBar(SnackBar(content: Text(loc.cloudNoBackup)));
      return;
    }

    final confirmed = await showCloudRestoreDialog(context, comparison);
    if (!mounted) return;
    if (!confirmed) {
      cloud.cancelRestore();
      return;
    }
    final restored = await runWithProgress(
      context,
      loc.cloudRestoring,
      cloud.confirmRestore,
    );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(restored ? loc.cloudRestored : loc.cloudOperationFailed),
    ));
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
    final cloud = context.read<CloudSyncController>();

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
      case 'restore_from_drive':
        await _restoreFromDrive();
        break;
      case 'google_sign_out':
        // The controller uploads pending local changes before disconnecting,
        // so recent edits do not remain only on this phone.
        await cloud.signOut();
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
