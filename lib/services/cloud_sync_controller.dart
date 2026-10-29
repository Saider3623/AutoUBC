import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database_service.dart';
import '../providers/app_provider.dart';
import 'cloud_sync_policy.dart';
import 'google_drive_sync_service.dart';

/// Outcome of a startup or sign-in synchronization flow.
enum CloudFlowResult {
  notConnected,

  /// The local and cloud copies already match (or both are empty).
  inSync,

  /// The cloud copy replaced the local database.
  restored,

  /// The local database was uploaded.
  uploaded,

  /// The copies differ and the user must choose which one to keep.
  needsDecision,

  /// Drive or the cloud file could not be read; nothing was changed.
  failed,
}

/// Choice offered when the local and cloud copies differ.
enum ConflictChoice { useCloud, usePhone }

/// Summaries of both copies, shown to the user before one replaces the other.
class CloudComparison {
  final DatabaseSummary local;
  final DatabaseSummary cloud;
  final DateTime? cloudModified;

  const CloudComparison({
    required this.local,
    required this.cloud,
    this.cloudModified,
  });
}

/// Decides when and in which direction data moves between the phone and
/// Google Drive.
///
/// The main rule: this device never uploads over an existing cloud backup of
/// an account until it has confirmed which copy is the reference for that
/// account (the *baseline*). The baseline is confirmed when the cloud copy was
/// restored, when there was no cloud copy, when both copies match, or when the
/// user explicitly chose the phone data. Before every replacement the other
/// copy is kept: a dated copy in Drive, a tagged local backup on the phone.
class CloudSyncController extends ChangeNotifier {
  CloudSyncController({
    required this.app,
    required this.drive,
    DatabaseService? database,
  }) : db = database ?? DatabaseService() {
    drive.addListener(notifyListeners);
    app.onDataSaved = uploadNow;
  }

  final AppProvider app;
  final GoogleDriveSyncService drive;
  final DatabaseService db;

  static const _baselineKey = 'cloud_baseline_account';

  bool _needsDecision = false;
  CloudComparison? _comparison;
  String? _cloudSnapshotPath;
  Future<CloudFlowResult>? _baselineCheck;
  bool _disposed = false;

  bool get isConnected => drive.isConnected;

  String? get accountEmail => drive.accountEmail;

  /// Whether the copies differ and uploads wait for the user's choice.
  bool get needsDecision => _needsDecision;

  /// Copies compared by the last check that needs a decision or a restore
  /// confirmation.
  CloudComparison? get comparison => _comparison;

  SyncStatus get status {
    final driveStatus = drive.syncStatus;
    if (driveStatus == SyncStatus.syncing) return driveStatus;
    if (_needsDecision) return SyncStatus.attention;
    return driveStatus;
  }

  @override
  void dispose() {
    _disposed = true;
    drive.removeListener(notifyListeners);
    if (app.onDataSaved == uploadNow) app.onDataSaved = null;
    _discardCloudSnapshot();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Entry points
  // ---------------------------------------------------------------------------

  /// Startup: silent sign-in, then the baseline check for that account.
  Future<CloudFlowResult> start() async {
    await drive.signInSilently();
    if (!drive.isConnected) return CloudFlowResult.notConnected;
    final result = await _ensureBaseline(interactive: false, allowRestore: true);
    if (result == CloudFlowResult.inSync && app.hasPendingSync) {
      final synced = await app.flushPendingSync();
      return synced ? CloudFlowResult.uploaded : CloudFlowResult.failed;
    }
    return result;
  }

  /// Interactive sign-in from the welcome screen or the menu.
  Future<CloudFlowResult> signIn() async {
    final signedIn = await drive.signIn();
    if (!signedIn) return CloudFlowResult.notConnected;
    return _ensureBaseline(interactive: true, allowRestore: true);
  }

  /// Uploads the pending local state first, then disconnects the account.
  Future<void> signOut() async {
    if (_isBaselineConfirmedSync) await app.flushPendingSync();
    await drive.signOut();
    _clearDecision();
  }

  /// Upload hook used by [AppProvider] after local changes. Returns whether
  /// the cloud copy now matches the local database.
  Future<bool> uploadNow() async {
    if (!drive.isConnected || _needsDecision) return false;
    if (!await _isBaselineConfirmed()) {
      final result =
          await _ensureBaseline(interactive: false, allowRestore: false);
      if (result == CloudFlowResult.inSync) return true;
      if (result == CloudFlowResult.uploaded) return true;
      return false;
    }
    return _upload();
  }

  /// Downloads the cloud copy and compares it with the local data, so the
  /// user can confirm a restore. Returns `null` when there is no cloud copy;
  /// throws when Drive cannot be read.
  Future<CloudComparison?> prepareRestore() async {
    final remote = await drive.findBackup();
    if (remote == null) return null;
    final prepared = await _downloadAndSummarize(remote);
    final comparison = CloudComparison(
      local: await db.summarizeLocal(),
      cloud: prepared,
      cloudModified: remote.modifiedTime,
    );
    _comparison = comparison;
    return comparison;
  }

  /// Replaces the local data with the copy prepared by [prepareRestore].
  Future<bool> confirmRestore() async {
    final path = _cloudSnapshotPath;
    if (path == null) return false;
    try {
      await _restoreFrom(path);
      _clearDecision();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[CloudSync] Restore failed: $error');
      debugPrint('$stackTrace');
      return false;
    } finally {
      _discardCloudSnapshot();
    }
  }

  /// Drops the copy prepared by [prepareRestore] without using it.
  void cancelRestore() {
    if (!_needsDecision) {
      _comparison = null;
      _discardCloudSnapshot();
    }
  }

  /// Applies the user's choice after the copies were found to differ.
  Future<bool> resolveConflict(ConflictChoice choice) async {
    if (!_needsDecision) return false;
    try {
      if (choice == ConflictChoice.useCloud) {
        final path = _cloudSnapshotPath;
        if (path == null) return false;
        await _restoreFrom(path);
      } else {
        final revision = app.pendingRevision;
        final uploaded = await _upload(keepSeparateCopy: true);
        if (!uploaded) return false;
        await _confirmBaseline();
        await app.markSyncCompleted(revision: revision);
      }
      _clearDecision();
      return true;
    } catch (error, stackTrace) {
      debugPrint('[CloudSync] Conflict resolution failed: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Baseline
  // ---------------------------------------------------------------------------

  String? _confirmedAccount;
  bool get _isBaselineConfirmedSync =>
      _confirmedAccount != null && _confirmedAccount == drive.accountId;

  Future<bool> _isBaselineConfirmed() async {
    final account = drive.accountId;
    if (account == null) return false;
    if (_confirmedAccount == account) return true;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_baselineKey);
    if (stored == account) _confirmedAccount = account;
    return stored == account;
  }

  Future<void> _confirmBaseline() async {
    final account = drive.accountId;
    if (account == null) return;
    _confirmedAccount = account;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baselineKey, account);
  }

  /// Runs at most one baseline check at a time; concurrent callers share it.
  Future<CloudFlowResult> _ensureBaseline({
    required bool interactive,
    required bool allowRestore,
  }) {
    final running = _baselineCheck;
    if (running != null) return running;
    final check = _checkBaseline(
      interactive: interactive,
      allowRestore: allowRestore,
    );
    _baselineCheck = check;
    return check.whenComplete(() {
      if (identical(_baselineCheck, check)) _baselineCheck = null;
    });
  }

  Future<CloudFlowResult> _checkBaseline({
    required bool interactive,
    required bool allowRestore,
  }) async {
    if (!drive.isConnected) return CloudFlowResult.notConnected;
    await app.initialization;
    if (app.loadError != null) return CloudFlowResult.failed;
    if (await _isBaselineConfirmed()) return CloudFlowResult.inSync;

    try {
      final local = await db.summarizeLocal();
      final remote = await drive.findBackup();
      DatabaseSummary? cloud;
      if (remote != null) cloud = await _downloadAndSummarize(remote);

      final action = resolveBaseline(
        local: local,
        cloud: cloud,
        interactive: interactive,
      );
      debugPrint('[CloudSync] Baseline: $action (local $local, cloud $cloud)');

      switch (action) {
        case BaselineAction.alreadyInSync:
          _discardCloudSnapshot();
          await _confirmBaseline();
          await app.markSyncCompleted();
          return CloudFlowResult.inSync;
        case BaselineAction.uploadLocal:
          _discardCloudSnapshot();
          final revision = app.pendingRevision;
          if (!await _upload()) return CloudFlowResult.failed;
          await _confirmBaseline();
          await app.markSyncCompleted(revision: revision);
          return CloudFlowResult.uploaded;
        case BaselineAction.restoreCloud:
          if (allowRestore) {
            await _restoreFrom(_cloudSnapshotPath!);
            _discardCloudSnapshot();
            return CloudFlowResult.restored;
          }
          return _askUser(local, cloud!, remote!);
        case BaselineAction.ask:
          return _askUser(local, cloud!, remote!);
      }
    } catch (error, stackTrace) {
      debugPrint('[CloudSync] Baseline check failed: $error');
      debugPrint('$stackTrace');
      _discardCloudSnapshot();
      return CloudFlowResult.failed;
    }
  }

  CloudFlowResult _askUser(
    DatabaseSummary local,
    DatabaseSummary cloud,
    RemoteBackup remote,
  ) {
    _comparison = CloudComparison(
      local: local,
      cloud: cloud,
      cloudModified: remote.modifiedTime,
    );
    _needsDecision = true;
    _notify();
    return CloudFlowResult.needsDecision;
  }

  void _clearDecision() {
    _needsDecision = false;
    _comparison = null;
    _discardCloudSnapshot();
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Transfers
  // ---------------------------------------------------------------------------

  /// Downloads [remote] to a temporary file and keeps it for a later restore.
  /// Throws when the file cannot be downloaded or is not a valid database.
  Future<DatabaseSummary> _downloadAndSummarize(RemoteBackup remote) async {
    _discardCloudSnapshot();
    final path = await db.temporarySnapshotPath();
    await drive.downloadBackup(remote, path);
    final summary = await db.summarizeSnapshot(path);
    if (summary == null) {
      await _deleteQuietly(path);
      throw StateError('The Google Drive backup is not a valid database.');
    }
    _cloudSnapshotPath = path;
    return summary;
  }

  Future<void> _restoreFrom(String snapshotPath) async {
    await db.replaceWithSnapshot(snapshotPath);
    await app.refreshAll();
    await app.markSyncCompleted();
    await _confirmBaseline();
  }

  Future<bool> _upload({bool keepSeparateCopy = false}) async {
    final snapshotPath = await db.createDatabaseSnapshot();
    try {
      return await drive.uploadBackup(
        snapshotPath,
        keepSeparateCopy: keepSeparateCopy,
      );
    } finally {
      await _deleteQuietly(snapshotPath);
    }
  }

  void _discardCloudSnapshot() {
    final path = _cloudSnapshotPath;
    _cloudSnapshotPath = null;
    if (path != null) unawaited(_deleteQuietly(path));
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
