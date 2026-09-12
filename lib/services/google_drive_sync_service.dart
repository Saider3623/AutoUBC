import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// The action selected during startup or after the first authorization.
enum SyncStartupAction { none, download, upload, error }

enum SyncStatus { unknown, idle, syncing, error }

SyncStatus effectiveSyncStatus({
  required SyncStatus status,
  required int activeOperations,
}) {
  return activeOperations > 0 ? SyncStatus.syncing : status;
}

/// Returns whether the app should ask for the first car after synchronization.
bool shouldPromptForFirstCarSetup({
  required bool isConnected,
  required bool hasCars,
  required SyncStartupAction syncAction,
}) {
  return isConnected && !hasCars && syncAction != SyncStartupAction.error;
}

/// Resolves the local-first startup policy.
///
/// Existing local data is authoritative on normal launches. A remote backup is
/// downloaded only when the local database file was missing at startup. A
/// pending mutation from an existing local database is uploaded silently.
SyncStartupAction resolveSyncStartupAction({
  required bool hasLocalData,
  required bool remoteExists,
  bool hasPendingLocalChanges = false,
}) {
  if (!hasLocalData && remoteExists) return SyncStartupAction.download;
  if (hasPendingLocalChanges) return SyncStartupAction.upload;
  if (hasLocalData) return SyncStartupAction.none;
  return SyncStartupAction.none;
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

/// Ім'я файлу бекапу на Google Диску.
const _kBackupFileName = 'autoubc_backup.isar';
const _kDriveScope = 'https://www.googleapis.com/auth/drive.appdata';
const _kGoogleWebClientId =
    '495555935730-cha6pi6dq22t131cn5ufspsjevfa8b1v.apps.googleusercontent.com';

/// HTTP-клієнт, що автоматично додає токен авторизації Google.
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

class _DriveSession {
  final drive.DriveApi api;
  final _AuthenticatedClient client;

  _DriveSession(this.api, this.client);

  void close() => client.close();
}

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
  bool _lastSyncFailed = false;
  SyncStatus _syncStatus = SyncStatus.unknown;

  /// Поточний Google-акаунт (null = не авторизований).
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Чи підключений акаунт.
  bool get isConnected => _currentUser != null;

  /// Чи виконується зараз синхронізація (upload/download).
  bool get isSyncing => _activeOperations > 0;

  /// Чи була помилка під час останньої спроби синхронізації.
  bool get hasSyncError => _lastSyncFailed;

  SyncStatus get syncStatus => effectiveSyncStatus(
        status: _syncStatus,
        activeOperations: _activeOperations,
      );

  void _beginOperation() {
    _activeOperations++;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
  }

  void _endOperation({
    required bool success,
    SyncStatus? terminalStatus,
  }) {
    _activeOperations = (_activeOperations > 0) ? _activeOperations - 1 : 0;
    _lastSyncFailed = terminalStatus == SyncStatus.error || !success;
    if (_activeOperations == 0) {
      _syncStatus =
          terminalStatus ?? (success ? SyncStatus.idle : SyncStatus.error);
    }
    notifyListeners();
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  // ---------------------------------------------------------------------------
  // АВТОРИЗАЦІЯ
  // ---------------------------------------------------------------------------

  /// Тихий вхід — викликається при старті додатку.
  /// Не показує жодних діалогів, якщо акаунт вже прив'язаний.
  Future<bool> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _currentUser = account;
      _syncStatus = SyncStatus.unknown;
      _lastSyncFailed = false;
      notifyListeners();
      return account != null;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDrive] Тихий вхід не вдався: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Інтерактивний вхід — викликається лише по кнопці.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _currentUser = account;
      _syncStatus = SyncStatus.unknown;
      _lastSyncFailed = false;
      notifyListeners();
      return account != null;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDrive] Помилка входу: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Вихід з акаунту.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _syncStatus = SyncStatus.unknown;
    _lastSyncFailed = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // РОБОТА З ДИСКОМ
  // ---------------------------------------------------------------------------

  /// Selects an action without comparing local and remote content.
  ///
  /// A normal authorized launch is local-first and does not contact Drive.
  /// Drive is queried only when the caller explicitly allows an empty local
  /// database to be restored (first authorization or missing local database).
  Future<SyncStartupAction> decideStartupAction({
    required bool hasLocalData,
    bool hasPendingLocalChanges = false,
    bool restoreIfEmpty = false,
  }) async {
    if (_currentUser == null) return SyncStartupAction.none;

    // A missing local database must be restored before considering any stale
    // pending marker from the previous local installation.
    if (!hasLocalData && restoreIfEmpty) {
      try {
        final session = await _getDriveSession();
        if (session == null) return SyncStartupAction.none;

        try {
          final remoteFile = await _findBackupFile(session.api);
          return resolveSyncStartupAction(
            hasLocalData: false,
            remoteExists: remoteFile != null,
          );
        } finally {
          session.close();
        }
      } catch (e, stackTrace) {
        debugPrint('[GoogleDrive] Помилка перевірки стану: $e');
        debugPrint('$stackTrace');
        return SyncStartupAction.error;
      }
    }

    if (hasPendingLocalChanges) return SyncStartupAction.upload;
    if (hasLocalData) {
      // During interactive first authorization, preserve the local database
      // and seed/update Drive from it instead of overwriting local data.
      return restoreIfEmpty ? SyncStartupAction.upload : SyncStartupAction.none;
    }
    return SyncStartupAction.none;
  }

  /// Отримати авторизований HTTP-клієнт для googleapis.
  Future<_DriveSession?> _getDriveSession() async {
    final user = _currentUser;
    if (user == null) return null;

    final auth = await user.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Google access token is unavailable.');
    }

    final innerClient = http.Client();
    final client = _AuthenticatedClient(
      {'Authorization': 'Bearer $accessToken'},
      innerClient,
    );
    return _DriveSession(drive.DriveApi(client), client);
  }

  /// Find the latest backup file in appDataFolder, when one exists.
  /// API errors are intentionally propagated to the caller: an unknown cloud
  /// state must not be treated as a missing file and replaced by local data.
  Future<drive.File?> _findBackupFile(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_kBackupFileName' and trashed = false",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, name, modifiedTime)',
    );

    return selectNewestBackupFile(list.files ?? const <drive.File>[]);
  }

  /// Вивантажити файл БД в Google Drive (appDataFolder).
  /// Якщо файл вже існує — оновлює (PATCH), якщо ні — створює (POST).
  Future<bool> uploadBackup(String dbFilePath) {
    return _enqueue(() => _uploadBackup(dbFilePath));
  }

  Future<bool> _uploadBackup(String dbFilePath) async {
    if (_currentUser == null) return false;
    _beginOperation();
    _DriveSession? session;
    try {
      session = await _getDriveSession();
      if (session == null) {
        throw StateError('Не вдалося ініціалізувати Drive API');
      }

      final api = session.api;
      final dbFile = File(dbFilePath);
      if (!await dbFile.exists()) {
        throw Exception('Файл БД не знайдено: $dbFilePath');
      }

      final existingFile = await _findBackupFile(api);
      final media = drive.Media(
        dbFile.openRead(),
        await dbFile.length(),
        contentType: 'application/octet-stream',
      );

      if (existingFile?.id != null) {
        await api.files.update(
          drive.File(),
          existingFile!.id!,
          uploadMedia: media,
        );
        debugPrint(
            '[GoogleDrive] Бекап оновлено (PATCH). ID: ${existingFile.id}');
      } else {
        final driveFile = drive.File()
          ..name = _kBackupFileName
          ..parents = ['appDataFolder'];
        await api.files.create(driveFile, uploadMedia: media);
        debugPrint('[GoogleDrive] Бекап створено (POST).');
      }

      _endOperation(success: true);
      return true;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDrive] Помилка вивантаження: $e');
      debugPrint('$stackTrace');
      _endOperation(success: false);
      return false;
    } finally {
      session?.close();
    }
  }

  /// Завантажити бекап з Google Drive і записати в локальний файл.
  /// Повертає true, якщо файл успішно завантажено.
  Future<bool> downloadBackup(
    String targetFilePath, {
    Future<bool> Function(String path)? validateFile,
  }) {
    return _enqueue(
        () => _downloadBackup(targetFilePath, validateFile: validateFile));
  }

  Future<bool> _downloadBackup(
    String targetFilePath, {
    Future<bool> Function(String path)? validateFile,
  }) async {
    if (_currentUser == null) return false;
    _beginOperation();

    _DriveSession? session;
    File? tempFile;
    try {
      session = await _getDriveSession();
      if (session == null) {
        throw StateError('Не вдалося ініціалізувати Drive API');
      }

      final api = session.api;
      final remoteFile = await _findBackupFile(api);
      if (remoteFile == null || remoteFile.id == null) {
        debugPrint('[GoogleDrive] Бекап на Диску не знайдено.');
        _endOperation(success: true, terminalStatus: SyncStatus.unknown);
        return false;
      }

      final response = await api.files.get(
        remoteFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final targetFile = File(targetFilePath);
      tempFile = File('$targetFilePath.download.isar');
      final previousFile = File('$targetFilePath.previous');

      // Recover a replacement interrupted after the old file was moved aside.
      if (!await targetFile.exists() && await previousFile.exists()) {
        await previousFile.rename(targetFile.path);
      }
      if (await tempFile.exists()) await tempFile.delete();

      final sink = tempFile.openWrite();
      try {
        await sink.addStream(response.stream);
      } finally {
        await sink.close();
      }

      if (!await tempFile.exists() || await tempFile.length() == 0) {
        throw StateError('Downloaded backup is empty.');
      }
      if (validateFile != null && !await validateFile(tempFile.path)) {
        throw StateError('Downloaded backup failed schema validation.');
      }

      if (await targetFile.exists()) {
        if (await previousFile.exists()) await previousFile.delete();
        await targetFile.rename(previousFile.path);
      }
      try {
        await tempFile.rename(targetFile.path);
        if (await previousFile.exists()) await previousFile.delete();
      } catch (_) {
        if (await targetFile.exists()) await targetFile.delete();
        if (await previousFile.exists()) {
          await previousFile.rename(targetFile.path);
        }
        rethrow;
      }

      debugPrint('[GoogleDrive] Бекап завантажено в $targetFilePath.');
      _endOperation(success: true);
      return true;
    } catch (e, stackTrace) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      debugPrint('[GoogleDrive] Помилка завантаження: $e');
      debugPrint('$stackTrace');
      _endOperation(success: false);
      return false;
    } finally {
      session?.close();
    }
  }
}
