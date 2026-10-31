import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/database_service.dart';
import '../l10n/app_localizations.dart';
import '../services/cloud_sync_controller.dart';
import '../services/cloud_sync_policy.dart';
import '../services/google_drive_sync_service.dart';
import '../widgets/cloud_comparison_dialog.dart';

/// Lists the Google Drive copies and the local backups and restores a chosen
/// one after the user has compared it with the current data.
class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  late Future<List<RemoteBackup>>? _cloud;
  late Future<List<LocalBackup>> _local;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final cloud = context.read<CloudSyncController>();
    _cloud = cloud.isConnected ? cloud.listCloudBackups() : null;
    _local = DatabaseService().listLocalBackups();
  }

  Future<void> _restore(
    Future<CloudComparison> Function() prepare,
    Future<bool> Function() confirm, {
    String? sourceColumn,
  }) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final cloud = context.read<CloudSyncController>();

    CloudComparison comparison;
    try {
      comparison = await runWithProgress(context, loc.cloudCheckingDrive, prepare);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(loc.backupOpenFailed)));
      return;
    }
    if (!mounted) return;
    final confirmed = await showCloudRestoreDialog(
      context,
      comparison,
      sourceColumn: sourceColumn,
    );
    if (!mounted) return;
    if (!confirmed) {
      cloud.cancelRestore();
      return;
    }
    final restored = await runWithProgress(context, loc.cloudRestoring, confirm);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(restored ? loc.backupRestored : loc.cloudOperationFailed),
    ));
    if (restored) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final cloud = context.read<CloudSyncController>();
    final dateTime = DateFormat.yMMMd(languageCode).add_Hm();
    final dateOnly = DateFormat.yMMMd(languageCode);

    String tagLabel(String? tag) => switch (tag) {
          'before-restore' => loc.backupBeforeRestore,
          'before-delete' => loc.backupBeforeDelete,
          _ => loc.backupAutomatic,
        };

    return Scaffold(
      appBar: AppBar(title: Text(loc.backupsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _local;
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionHeader(loc.backupsCloudSection),
            if (_cloud == null)
              ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(loc.backupsCloudSignedOut),
              )
            else
              FutureBuilder<List<RemoteBackup>>(
                future: _cloud,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(loc.cloudOperationFailed),
                    );
                  }
                  final copies = snapshot.data ?? const [];
                  if (copies.isEmpty) {
                    return ListTile(
                      leading: const Icon(Icons.cloud_outlined),
                      title: Text(loc.cloudNoBackup),
                    );
                  }
                  return Column(
                    children: [
                      for (final copy in copies)
                        ListTile(
                          leading: Icon(copy.name == cloudBackupFileName
                              ? Icons.cloud_done_outlined
                              : Icons.history),
                          title: Text(copy.name == cloudBackupFileName
                              ? loc.backupCurrentCloudCopy
                              : loc.backupDatedCopy(
                                  dateOnly.format(
                                      parseDatedCopyDate(copy.name) ??
                                          copy.modifiedTime ??
                                          DateTime.now()),
                                )),
                          subtitle: copy.modifiedTime == null
                              ? null
                              : Text(dateTime.format(copy.modifiedTime!)),
                          trailing: const Icon(Icons.restore),
                          onTap: () => _restore(
                            () => cloud.prepareRestoreFrom(copy),
                            cloud.confirmRestore,
                          ),
                        ),
                    ],
                  );
                },
              ),
            const Divider(height: 24),
            _SectionHeader(loc.backupsLocalSection),
            FutureBuilder<List<LocalBackup>>(
              future: _local,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final backups = snapshot.data ?? const [];
                if (backups.isEmpty) {
                  return ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: Text(loc.backupsLocalEmpty),
                  );
                }
                return Column(
                  children: [
                    for (final backup in backups)
                      ListTile(
                        leading: const Icon(Icons.phone_android),
                        title: Text(dateTime.format(backup.time)),
                        subtitle: Text(tagLabel(backup.tag)),
                        trailing: const Icon(Icons.restore),
                        onTap: () => _restore(
                          () => cloud.prepareLocalRestore(backup),
                          cloud.confirmLocalRestore,
                          sourceColumn: loc.backupColumn,
                        ),
                      ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                loc.backupsExplanation,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;

  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
