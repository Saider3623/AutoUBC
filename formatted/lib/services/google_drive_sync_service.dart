import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'cloud_sync_policy.dart';

/// State of the Google Drive connection shown next to the car name.
enum SyncStatus {
  /// Nothing has been synchronized in this session yet.
  unknown,
  idle,
  syncing,
  error,

  /// The phone and the cloud hold different data and the user must choose.
  attention,
}

SyncStatus effectiveSyncStatus({
  required SyncStatus status,
  required int activeOperations,
}) {
  return activeOperations > 0 ? SyncStatus.syncing : status;
}

/// Why the last Drive operation failed, in terms the user can act on.
enum SyncProblem {
  /// No connection, or Google did not answer in time. Retried later.
  offline,

  /// Google refused access: the Drive permission was not granted at sign-in
  /// or was revoked. Signing in again fixes it.
  accessDenied,

  /// The Google account has no free storage left.
  storageFull,

  other,
}

/// Maps an exception of a Drive operation to a [SyncProblem].
SyncProblem classifySyncError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is http.ClientException) {
    return SyncProblem.offline;
  }
  if (error is drive.DetailedApiRequestError) {
    final reasons = {for (final detail in error.errors) detail.reason};
    final message = error.message?.toLowerCase() ?? '';
    if (reasons.contains('storageQuotaExceeded') ||
        message.contains('storage quota')) {
      return SyncProblem.storageFull;
    }
    if (reasons.contains('rateLimitExceeded') ||
        reasons.contains('userRateLimitExceeded')) {
      return SyncProblem.other;
    }
    if (error.status == 401 || error.status == 403) {
      return SyncProblem.accessDenied;
    }
    return SyncProblem.other;
  }
  if (error is PlatformException) {
    if (error.code.contains('network')) return SyncProblem.offline;
    return SyncProblem.accessDenied;
  }
  if (error is StateError && error.message.contains('access token')) {
    return SyncProblem.accessDenied;
  }
  return SyncProblem.other;
}

/// Returns the newest backup candidate from Drive results.
drive.File? selectNewestBackupFile(Iterable<drive.File> files) {
  final candidates =
      files.where((file) => file.id != null && file.id!.isNotEmpty).toList()
        ..sort((a, b) {
          final aModified = a.modifiedTime;
          final bModified = b.modifiedTime;
          if (aModified == null && bModified == null) return 0;
          if (aModified == null) return 1;
          if (bModified == null) return -1;
          return bModified.compareTo(aModified);
        });

  return candidates.isEmpty ? null : candidates.first;
}

/// A backup file stored in the Drive app data folder.
class RemoteBackup {
  final String id;
  final String name;
  final DateTime? modifiedTime;

  const RemoteBackup({required this.id, required this.name, this.modifiedTime});
}

const _kDriveScope = 'https://www.googleapis.com/auth/drive.appdata';
const _kGoogleWebClientId =
    '495555935730-cha6pi6dq22t131cn5ufspsjevfa8b1v.apps.googleusercontent.com';

/// Every network step has an explicit deadline. A stalled Drive request or an
/// unresponsive sign-in must never block the caller (and the UI isolate)
/// forever, because the sync queue would stay occupied and the spinner would
/// never stop.
const _kAuthTimeout = Duration(seconds: 15);
const _kMetadataTimeout = Duration(seconds: 30);
const _kTransferTimeout = Duration(seconds: 120);

/// A download is aborted when no data arrives for this long. There is no cap
/// on the total time, so a slow but working connection still finishes.
const _kStallTimeout = Duration(seconds: 30);

/// HTTP client that adds the Google authorization header to every request.
class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner;

  _AuthenticatedClient(this._headers, this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Google sign-in and file transfer to the Drive app data folder.
///
/// This class only moves files. Decisions about which copy wins are made by
/// `CloudSyncController` with the rules in `cloud_sync_policy.dart`.
class GoogleDriveSyncService extends ChangeNotifier {
  static final GoogleDriveSyncService _instance =
      GoogleDriveSyncService._internal();
  factory GoogleDriveSyncService() => _instance;
  GoogleDriveSyncService._internal();

  final _googleSignIn = GoogleSignIn(
    serverClientId: _kGoogleWebClientId,
    scopes: [_kDriveScope],
  );

  GoogleSignInAccount? _currentUser;
  Future<void> _operationQueue = Future<void>.value();
  int _activeOperations = 0;
  SyncStatus _syncStatus = SyncStatus.unknown;
  DateTime? _lastSuccessAt;
  String? _lastError;
  SyncProblem? _lastProblem;

  /// The signed-in Google account, `null` when signed out.
  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isConnected => _currentUser != null;

  /// Stable id of the signed-in account.
  String? get accountId => _currentUser?.id;

  String? get accountEmail => _currentUser?.email;

  /// Whether an upload or download is running.
  bool get isSyncing => _activeOperations > 0;

  bool get hasSyncError => _syncStatus == SyncStatus.error;

  /// Time of the last successful Drive operation in this session.
  DateTime? get lastSuccessAt => _lastSuccessAt;

  /// Technical description of the last failed Drive operation.
  String? get lastError => _lastError;

  /// What went wrong in the last failed Drive operation, `null` after a
  /// success.
  SyncProblem? get lastProblem => _lastProblem;

  SyncStatus get syncStatus => effectiveSyncStatus(
    status: _syncStatus,
    activeOperations: _activeOperations,
  );

  void _beginOperation() {
    _activeOperations++;
    notifyListeners();
  }

  void _endOperation({required bool success, Object? error}) {
    _activeOperations = (_activeOperations > 0) ? _activeOperations - 1 : 0;
    if (success) {
      _lastSuccessAt = DateTime.now();
      _lastError = null;
      _lastProblem = null;
    } else {
      _lastError = error?.toString();
      _lastProblem = error == null
          ? SyncProblem.other
          : classifySyncError(error);
    }
    if (_activeOperations == 0) {
      _syncStatus = success ? SyncStatus.idle : SyncStatus.error;
    }
    notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  /// Runs one Drive operation: serialized with the others, counted for the
  /// status indicator, with a fresh authorized client that is always closed.
  Future<T> _operation<T>(
    String label,
    Future<T> Function(drive.DriveApi api) body,
  ) {
    return _enqueue(() async {
      _beginOperation();
      _AuthenticatedClient? client;
      try {
        client = await _authorizedClient();
        final value = await body(drive.DriveApi(client));
        _endOperation(success: true);
        return value;
      } catch (error, stackTrace) {
        debugPrint('[GoogleDrive] $label failed: $error');
        debugPrint('$stackTrace');
        _endOperation(success: false, error: error);
        rethrow;
      } finally {
        client?.close();
      }
    });
  }

  Future<_AuthenticatedClient> _authorizedClient() async {
    final user = _currentUser;
    if (user == null) throw StateError('Not signed in to Google.');

    final auth = await user.authentication.timeout(_kAuthTimeout);
    final accessToken = auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Google access token is unavailable.');
    }
    return _AuthenticatedClient({
      'Authorization': 'Bearer $accessToken',
    }, http.Client());
  }

  // ---------------------------------------------------------------------------
  // Authorization
  // ---------------------------------------------------------------------------

  /// Signs in without any dialog when the account was connected before.
  Future<bool> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently().timeout(
        _kAuthTimeout,
      );
      _setUser(account);
      return account != null;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDrive] Silent sign-in failed: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Interactive sign-in, started only by the user.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn().timeout(_kTransferTimeout);
      if (account != null) await _ensureDriveScope();
      _setUser(account);
      return account != null;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDrive] Sign-in failed: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// The consent screen lets the user untick Google Drive. Asking for the
  /// scope again shows that screen only when the permission is missing.
  Future<void> _ensureDriveScope() async {
    try {
      final granted = await _googleSignIn
          .requestScopes([_kDriveScope])
          .timeout(_kTransferTimeout);
      if (!granted) debugPrint('[GoogleDrive] Drive access was not granted.');
    } catch (e) {
      debugPrint('[GoogleDrive] Drive scope check failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _setUser(null);
  }

  void _setUser(GoogleSignInAccount? account) {
    _currentUser = account;
    _syncStatus = SyncStatus.unknown;
    _lastError = null;
    _lastProblem = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Drive files
  // ---------------------------------------------------------------------------

  /// Finds the main backup. API errors are propagated: an unknown cloud state
  /// must never be treated as a missing file and replaced by local data.
  Future<RemoteBackup?> findBackup() {
    return _operation('find backup', _findMainBackup);
  }

  Future<RemoteBackup?> _findMainBackup(drive.DriveApi api) async {
    final list = await api.files
        .list(
          spaces: 'appDataFolder',
          q: "name = '$cloudBackupFileName' and trashed = false",
          orderBy: 'modifiedTime desc',
          $fields: 'files(id, name, modifiedTime)',
        )
        .timeout(_kMetadataTimeout);
    final file = selectNewestBackupFile(list.files ?? const <drive.File>[]);
    return file == null ? null : _toRemote(file);
  }

  /// Lists the dated copies kept before the main backup was replaced, newest
  /// first.
  Future<List<RemoteBackup>> listDatedCopies() {
    return _operation('list copies', _listDatedCopies);
  }

  Future<List<RemoteBackup>> _listDatedCopies(drive.DriveApi api) async {
    final list = await api.files
        .list(
          spaces: 'appDataFolder',
          q: 'trashed = false',
          pageSize: 200,
          $fields: 'files(id, name, modifiedTime)',
        )
        .timeout(_kMetadataTimeout);
    final copies = [
      for (final file in list.files ?? const <drive.File>[])
        if (file.id != null &&
            (file.name ?? '').startsWith(cloudDatedCopyPrefix))
          _toRemote(file),
    ]..sort((a, b) => b.name.compareTo(a.name));
    return copies;
  }

  RemoteBackup _toRemote(drive.File file) => RemoteBackup(
    id: file.id!,
    name: file.name ?? '',
    modifiedTime: file.modifiedTime?.toLocal(),
  );

  /// Downloads [backup] into [targetPath]. Throws when the transfer fails or
  /// stalls; a partial file is deleted.
  Future<void> downloadBackup(RemoteBackup backup, String targetPath) {
    return _operation('download', (api) async {
      final target = File(targetPath);
      try {
        final media =
            await api.files
                    .get(
                      backup.id,
                      downloadOptions: drive.DownloadOptions.fullMedia,
                    )
                    .timeout(_kMetadataTimeout)
                as drive.Media;
        final sink = target.openWrite();
        try {
          // The stall timeout ends the stream with an error; `addStream` then
          // cancels the HTTP stream and returns, so the sink can be closed.
          await sink.addStream(media.stream.timeout(_kStallTimeout));
        } finally {
          try {
            await sink.close();
          } catch (_) {}
        }
        if (!await target.exists() || await target.length() == 0) {
          throw StateError('Downloaded backup is empty.');
        }
      } catch (_) {
        try {
          if (await target.exists()) await target.delete();
        } catch (_) {}
        rethrow;
      }
    });
  }

  /// Uploads [snapshotPath] as the main backup. Before an existing backup is
  /// replaced, a dated copy of it is kept (one per day, or a separate one when
  /// [keepSeparateCopy] is set). Returns whether the upload succeeded.
  Future<bool> uploadBackup(
    String snapshotPath, {
    bool keepSeparateCopy = false,
  }) async {
    if (_currentUser == null) return false;
    try {
      await _operation('upload', (api) async {
        final file = File(snapshotPath);
        if (!await file.exists()) {
          throw StateError('Snapshot not found: $snapshotPath');
        }

        final existing = await _findMainBackup(api);
        if (existing != null) {
          await _keepDatedCopy(api, existing, unique: keepSeparateCopy);
        }

        final media = drive.Media(
          file.openRead(),
          await file.length(),
          contentType: 'application/octet-stream',
        );
        if (existing != null) {
          await api.files
              .update(drive.File(), existing.id, uploadMedia: media)
              .timeout(_kTransferTimeout);
        } else {
          final driveFile = drive.File()
            ..name = cloudBackupFileName
            ..parents = ['appDataFolder'];
          await api.files
              .create(driveFile, uploadMedia: media)
              .timeout(_kTransferTimeout);
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Copies the current main backup to a dated file and prunes old copies.
  ///
  /// A routine copy failure does not block the upload (yesterday's copy is
  /// already there). A [unique] copy is made before an explicit replacement
  /// chosen by the user, so its failure aborts the replacement.
  Future<void> _keepDatedCopy(
    drive.DriveApi api,
    RemoteBackup current, {
    required bool unique,
  }) async {
    try {
      final copies = await _listDatedCopies(api);
      final name = datedCloudCopyName(DateTime.now(), unique: unique);
      if (!copies.any((copy) => copy.name == name)) {
        final copy = drive.File()
          ..name = name
          ..parents = ['appDataFolder'];
        await api.files.copy(copy, current.id).timeout(_kMetadataTimeout);
        copies.add(RemoteBackup(id: '', name: name));
      }
      final toDelete = datedCopiesToDelete(copies.map((copy) => copy.name));
      for (final copy in copies) {
        if (copy.id.isNotEmpty && toDelete.contains(copy.name)) {
          try {
            await api.files.delete(copy.id).timeout(_kMetadataTimeout);
          } catch (error) {
            debugPrint('[GoogleDrive] Could not delete ${copy.name}: $error');
          }
        }
      }
    } catch (error) {
      if (unique) rethrow;
      debugPrint('[GoogleDrive] Dated copy skipped: $error');
    }
  }
}
