import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../screens/backups_screen.dart';
import '../services/cloud_sync_controller.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet with the Google Drive state and every sync action in one
/// place: account, last successful sync, last problem, sync now, restore,
/// backups and sign-out.
Future<void> showSyncPanel(
  BuildContext context, {
  required Future<void> Function() onSignIn,
  required Future<void> Function() onRestore,
  required Future<void> Function() onDecision,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: _SyncPanel(
        onSignIn: onSignIn,
        onRestore: onRestore,
        onDecision: onDecision,
        outerContext: context,
      ),
    ),
  );
}

class _SyncPanel extends StatefulWidget {
  final Future<void> Function() onSignIn;
  final Future<void> Function() onRestore;
  final Future<void> Function() onDecision;
  final BuildContext outerContext;

  const _SyncPanel({
    required this.onSignIn,
    required this.onRestore,
    required this.onDecision,
    required this.outerContext,
  });

  @override
  State<_SyncPanel> createState() => _SyncPanelState();
}

class _SyncPanelState extends State<_SyncPanel> {
  bool _isSyncing = false;

  /// Closes the sheet, then runs [action] on the screen below it.
  void _closeThen(Future<void> Function() action) {
    Navigator.pop(context);
    action();
  }

  Future<void> _syncNow() async {
    final cloud = context.read<CloudSyncController>();
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(widget.outerContext);
    setState(() => _isSyncing = true);
    final synced = await cloud.syncNow();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    messenger.showSnackBar(
      SnackBar(content: Text(synced ? loc.syncIdle : loc.cloudOperationFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cloud = context.watch<CloudSyncController>();
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    if (!cloud.isConnected) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Google Drive', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(loc.syncPanelSignedOut),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _closeThen(widget.onSignIn),
              icon: const Icon(Icons.login),
              label: Text(loc.signInToGoogleDrive),
            ),
          ],
        ),
      );
    }

    final status = cloud.status;
    final lastSynced = cloud.lastSyncedAt;
    final problem = status == SyncStatus.error ? cloud.lastProblem : null;
    final problemText = switch (problem) {
      SyncProblem.offline => loc.syncProblemOffline,
      SyncProblem.accessDenied => loc.syncProblemAccessDenied,
      SyncProblem.storageFull => loc.syncProblemStorageFull,
      _ => null,
    };
    final (IconData icon, Color color, String text) = switch (status) {
      SyncStatus.syncing => (
        Icons.sync,
        theme.colorScheme.primary,
        loc.syncInProgress,
      ),
      SyncStatus.error => (
        Icons.error_outline,
        theme.colorScheme.error,
        loc.syncPanelError,
      ),
      SyncStatus.attention => (
        Icons.warning_amber,
        AppColors.warning,
        loc.syncNeedsDecision,
      ),
      _ =>
        app.hasPendingSync
            ? (
                Icons.cloud_upload_outlined,
                theme.colorScheme.primary,
                loc.syncPendingChanges,
              )
            : (Icons.cloud_done_outlined, AppColors.success, loc.syncIdle),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Google Drive'),
            subtitle: Text(cloud.accountEmail ?? ''),
          ),
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(text),
            subtitle: lastSynced == null
                ? null
                : Text(
                    loc.syncLastSuccess(
                      DateFormat.yMMMd(languageCode)
                          .add_Hm()
                          .format(lastSynced),
                    ),
                  ),
          ),
          if (problemText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                problemText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (problem == SyncProblem.accessDenied)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                icon: const Icon(Icons.login),
                label: Text(loc.syncSignInAgain),
                onPressed: () => _closeThen(() async {
                  await cloud.signOut();
                  await widget.onSignIn();
                }),
              ),
            ),
          if (status == SyncStatus.attention)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: () => _closeThen(widget.onDecision),
                child: Text(loc.syncChooseCopy),
              ),
            ),
          const Divider(),
          ListTile(
            leading: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            title: Text(loc.syncNow),
            enabled: !_isSyncing && status != SyncStatus.attention,
            onTap: _syncNow,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text(loc.restoreFromDriveMenu),
            onTap: () => _closeThen(widget.onRestore),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(loc.backupsTitle),
            onTap: () => _closeThen(() async {
              await Navigator.push(
                widget.outerContext,
                MaterialPageRoute(builder: (context) => const BackupsScreen()),
              );
            }),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(loc.signOutFromGoogle),
            onTap: () => _closeThen(cloud.signOut),
          ),
        ],
      ),
    );
  }
}
