import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_theme.dart';
import '../services/remote_log_service.dart';

// #region debug-point D6:reporter
void _dbgIndicator(String h, String loc, String msg,
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
  // #region debug-point C:indicator
  int _buildCount = 0;
  Timer? _heartbeat;
  // #endregion

  @override
  void initState() {
    super.initState();
    _lastStatus = widget.sync.syncStatus;
    widget.sync.addListener(_onSyncChanged);
    _applyInitialStatus();
    // #region debug-point C:indicator
    _dbgIndicator('C', 'sync_status_indicator.dart:initState',
        'init status=${widget.sync.syncStatus} connected=${widget.sync.isConnected}');
    _heartbeat = Timer.periodic(const Duration(seconds: 1), (_) {
      _dbgIndicator(
          'C',
          'sync_status_indicator.dart:heartbeat',
          'ui alive builds=$_buildCount status=${widget.sync.syncStatus} '
              'connected=${widget.sync.isConnected}');
    });
    // #endregion
  }

  @override
  void dispose() {
    // #region debug-point C:indicator
    _heartbeat?.cancel();
    _dbgIndicator('C', 'sync_status_indicator.dart:dispose', 'disposed');
    // #endregion
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
    // #region debug-point C:indicator
    _dbgIndicator('C', 'sync_status_indicator.dart:_onSyncChanged',
        'status $previous -> $newStatus');
    // #endregion

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
    // #region debug-point C:indicator
    _buildCount++;
    // #endregion
    final loc = AppLocalizations.of(context)!;
    final status = widget.sync.syncStatus;

    Widget child;
    if (!widget.sync.isConnected || status == SyncStatus.unknown) {
      // No account and no sync activity: keep the slot empty but reserved.
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
