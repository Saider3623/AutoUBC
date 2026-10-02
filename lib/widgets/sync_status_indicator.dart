import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_theme.dart';

class SyncStatusIndicator extends StatefulWidget {
  final GoogleDriveSyncService sync;

  const SyncStatusIndicator({super.key, required this.sync});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  bool _showSuccess = false;
  Timer? _successTimer;
  SyncStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _lastStatus = widget.sync.syncStatus;
    widget.sync.addListener(_onSyncChanged);
    _applyInitialStatus();
  }

  @override
  void dispose() {
    widget.sync.removeListener(_onSyncChanged);
    _successTimer?.cancel();
    super.dispose();
  }

  void _applyInitialStatus() {
    final status = widget.sync.syncStatus;
    if (status == SyncStatus.error) {
      _showSuccess = false;
      _successTimer?.cancel();
    }
  }

  void _onSyncChanged() {
    final SyncStatus newStatus = widget.sync.syncStatus;
    final SyncStatus previous = _lastStatus ?? SyncStatus.unknown;
    _lastStatus = newStatus;

    if (!mounted) return;

    if (newStatus == SyncStatus.error) {
      setState(() {
        _showSuccess = false;
        _successTimer?.cancel();
      });
      return;
    }

    if (newStatus == SyncStatus.idle &&
        (previous == SyncStatus.syncing || previous == SyncStatus.unknown)) {
      setState(() {
        _showSuccess = true;
        _successTimer?.cancel();
        _successTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && widget.sync.syncStatus == SyncStatus.idle) {
            setState(() {
              _showSuccess = false;
            });
          }
        });
      });
      return;
    }

    if (newStatus == SyncStatus.syncing) {
      setState(() {
        _showSuccess = false;
        _successTimer?.cancel();
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final status = widget.sync.syncStatus;

    Widget child;
    if (status == SyncStatus.unknown) {
      child = const SizedBox.shrink();
    } else if (status == SyncStatus.idle) {
      if (_showSuccess) {
        child = _buildIndicator(
          color: AppColors.success,
          label: loc.syncIdle,
        );
      } else {
        child = const SizedBox.shrink();
      }
    } else if (status == SyncStatus.error) {
      child = _buildIndicator(
        color: AppColors.error,
        label: loc.syncError,
        isError: true,
      );
    } else if (status == SyncStatus.syncing) {
      child = _buildIndicator(
        color: AppColors.primary,
        label: loc.syncInProgress,
        isSyncing: true,
      );
    } else {
      child = const SizedBox.shrink();
    }

    return SizedBox(
      width: 12,
      height: 12,
      child: child,
    );
  }

  Widget _buildIndicator({
    required Color color,
    required String label,
    bool isSyncing = false,
    bool isError = false,
  }) {
    final indicator = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isSyncing
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1.5,
                ),
              ]
            : isError
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
      ),
      child: isSyncing
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
        liveRegion: isSyncing || isError,
        child: indicator,
      ),
    );
  }
}
