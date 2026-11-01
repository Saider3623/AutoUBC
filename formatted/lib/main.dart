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
import 'services/cloud_sync_controller.dart';
import 'services/google_drive_sync_service.dart';
import 'services/reminder_notifications.dart';
import 'theme/app_theme.dart';
import 'widgets/app_empty_state.dart';
import 'widgets/cloud_comparison_dialog.dart';
import 'widgets/sync_panel.dart';
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
            supportedLocales: const [Locale('en'), Locale('uk')],
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
  final PageController _pageController = PageController();
  AppProvider? _appProvider;
  CloudSyncController? _cloud;
  int _currentPage = 0;
  bool _isInteractiveSignIn = false;
  bool _isLifecycleSyncInProgress = false;
  bool _isDecisionDialogOpen = false;
  int? _notifiedRevision;
  Locale? _notifiedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cloud = context.read<CloudSyncController>();
      final app = context.read<AppProvider>();
      _appProvider = app;
      _cloud = cloud;
      cloud.addListener(_onCloudChanged);
      app.addListener(_onAppChanged);
      _onAppChanged();
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            resolved
                ? (choice == ConflictChoice.useCloud
                      ? loc.cloudRestored
                      : loc.cloudUploaded)
                : loc.cloudOperationFailed,
          ),
        ),
      );
      if (resolved) await _promptForFirstCarIfNeeded(CloudFlowResult.restored);
    } finally {
      _isDecisionDialogOpen = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Notification texts follow the app language.
    if (_appProvider != null) _onAppChanged();
  }

  /// Reschedules reminder notifications after reminders, cars or the app
  /// language changed.
  void _onAppChanged() {
    final app = _appProvider;
    if (app == null || !mounted || app.isLoading || app.loadError != null) {
      return;
    }
    final locale = Localizations.localeOf(context);
    if (app.remindersRevision == _notifiedRevision &&
        locale == _notifiedLocale) {
      return;
    }
    _notifiedRevision = app.remindersRevision;
    _notifiedLocale = locale;
    unawaited(_rescheduleNotifications(app, locale));
  }

  Future<void> _rescheduleNotifications(AppProvider app, Locale locale) async {
    if (!ReminderNotifications.instance.isSupported) return;
    try {
      final reminders = await app.allReminders();
      await ReminderNotifications.instance.reschedule(
        reminders: reminders,
        cars: app.cars,
        locale: locale,
      );
    } catch (error) {
      debugPrint('[Notifications] Reading reminders failed: $error');
    }
  }

  Future<void> _promptForFirstCarIfNeeded(CloudFlowResult result) async {
    final cloud = _cloud;
    final appProvider = _appProvider;
    if (!mounted || cloud == null || appProvider == null) return;
    final settled =
        result == CloudFlowResult.inSync ||
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
    _appProvider?.removeListener(_onAppChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.cars.isEmpty) return const SizedBox.shrink();
          return NavigationBar(
            selectedIndex: _currentPage,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              setState(() => _currentPage = index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.edit_outlined),
                selectedIcon: const Icon(Icons.edit),
                label: loc.navEntry,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: loc.navReport,
              ),
            ],
          );
        },
      ),
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
                  onTap: cloud.isConnected ? _openSyncPanel : null,
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
                  builder: (context) => const ExportReportScreen(),
                ),
              );
            },
          ),
          Consumer2<AppProvider, LocaleProvider>(
            builder: (context, provider, localeProvider, child) {
              return PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'manage_cars',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 20,
                          color: AppColors.primary,
                        ),
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
                          const Icon(
                            Icons.notifications_none,
                            size: 20,
                            color: AppColors.primary,
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
                          const Icon(
                            Icons.book,
                            size: 20,
                            color: AppColors.primary,
                          ),
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
                        const Icon(
                          Icons.language,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(loc.language),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  // Google Drive: account, sync state and all actions.
                  PopupMenuItem(
                    value: 'google_drive',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.read<CloudSyncController>().isConnected
                              ? 'Google Drive'
                              : loc.signInToGoogleDrive,
                        ),
                      ],
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
          // Swiping still switches pages; the bottom bar names them.
          return PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: const [DataEntryScreen(), WeeklyReportScreen()],
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
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
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
                    const SizedBox(height: 8),
                    Text(
                      loc.storageExplanation,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                        onPressed: _isInteractiveSignIn
                            ? null
                            : _signInToGoogle,
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
                        label: Text(
                          _isInteractiveSignIn
                              ? loc.connectingToGoogleDrive
                              : loc.restoreFromGoogleDrive,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isInteractiveSignIn
                            ? null
                            : _openManageCars,
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

  Future<void> _openSyncPanel() {
    return showSyncPanel(
      context,
      onSignIn: _signInToGoogle,
      onRestore: _restoreFromDrive,
      onDecision: _showDecision,
    );
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
    messenger.showSnackBar(
      SnackBar(
        content: Text(restored ? loc.cloudRestored : loc.cloudOperationFailed),
      ),
    );
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
      case 'google_drive':
        if (cloud.isConnected) {
          await _openSyncPanel();
        } else {
          await _signInToGoogle();
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
