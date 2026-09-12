import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_theme.dart';

class SyncStatusIndicator extends StatelessWidget {
  final GoogleDriveSyncService sync;

  const SyncStatusIndicator({super.key, required this.sync});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final status = sync.syncStatus;
    final (label, color) = switch (status) {
      SyncStatus.unknown => (loc.syncUnknown, AppColors.muted),
      SyncStatus.idle => (loc.syncIdle, AppColors.success),
      SyncStatus.syncing => (loc.syncInProgress, AppColors.primary),
      SyncStatus.error => (loc.syncError, AppColors.error),
    };

    final indicator = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: status == SyncStatus.unknown
            ? Border.all(color: color, width: 1.5)
            : null,
        boxShadow: status == SyncStatus.syncing
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1.5,
                ),
              ]
            : null,
      ),
      child: status == SyncStatus.syncing
          ? const CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : null,
    );

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        liveRegion: status == SyncStatus.syncing || status == SyncStatus.error,
        child: indicator,
      ),
    );
  }
}
