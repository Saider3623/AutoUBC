import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/cloud_sync_controller.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_theme.dart';

/// Small dot next to the car name that shows the Google Drive state.
///
/// Blue with a spinner while syncing, green for two seconds after success,
/// red after a failure and orange when the user must choose between the phone
/// and the cloud data. [onTap] makes the dot tappable (used for the orange
/// state, which opens the decision dialog).
class SyncStatusIndicator extends StatefulWidget {
  final CloudSyncController cloud;
  final VoidCallback? onTap;

  const SyncStatusIndicator({super.key, required this.cloud, this.onTap});

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
    _lastStatus = widget.cloud.status;
    widget.cloud.addListener(_onSyncChanged);
  }

  @override
  void didUpdateWidget(covariant SyncStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cloud, widget.cloud)) {
      oldWidget.cloud.removeListener(_onSyncChanged);
      widget.cloud.addListener(_onSyncChanged);
    }
  }

  @override
  void dispose() {
    widget.cloud.removeListener(_onSyncChanged);
    _successTimer?.cancel();
    super.dispose();
  }

  void _onSyncChanged() {
    final newStatus = widget.cloud.status;
    final previous = _lastStatus ?? SyncStatus.unknown;
    _lastStatus = newStatus;

    if (!mounted) return;

    if (newStatus == SyncStatus.idle && previous == SyncStatus.syncing) {
      setState(() {
        _showSuccess = true;
        _successTimer?.cancel();
        _successTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSuccess = false);
        });
      });
      return;
    }

    if (newStatus != SyncStatus.idle) {
      _successTimer?.cancel();
      setState(() => _showSuccess = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final status = widget.cloud.status;

    Widget child;
    if (!widget.cloud.isConnected) {
      // No account: keep the slot empty but reserved.
      child = const SizedBox.shrink();
    } else {
      switch (status) {
        case SyncStatus.syncing:
          child = _buildIndicator(
            color: AppColors.primary,
            label: loc.syncInProgress,
            isSyncing: true,
          );
        case SyncStatus.error:
          child = _buildIndicator(
            color: AppColors.error,
            label: loc.syncError,
            emphasized: true,
          );
        case SyncStatus.attention:
          child = _buildIndicator(
            color: AppColors.warning,
            label: loc.syncNeedsDecision,
            emphasized: true,
          );
        case SyncStatus.idle:
          child = _showSuccess
              ? _buildIndicator(color: AppColors.success, label: loc.syncIdle)
              : const SizedBox.shrink();
        case SyncStatus.unknown:
          child = const SizedBox.shrink();
      }
    }

    final dot = SizedBox(width: 12, height: 12, child: child);
    if (widget.onTap == null) return dot;
    return InkResponse(
      onTap: widget.onTap,
      radius: 20,
      child: Padding(padding: const EdgeInsets.all(6), child: dot),
    );
  }

  Widget _buildIndicator({
    required Color color,
    required String label,
    bool isSyncing = false,
    bool emphasized = false,
  }) {
    final indicator = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isSyncing || emphasized
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1.5,
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
        liveRegion: isSyncing || emphasized,
        child: indicator,
      ),
    );
  }
}
