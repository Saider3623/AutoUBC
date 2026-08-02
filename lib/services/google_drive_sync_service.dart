import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The action selected during the first sync handshake after sign-in.
enum SyncStartupAction { none, download, upload, conflict, error }

/// Resolves the safe action for a checked local/remote sync state.
SyncStartupAction resolveSyncStartupAction({
  required bool hasLocalData,
  required bool remoteExists,
  bool hasPendingLocalChanges = false,
  DateTime? lastKnownRemoteModified,
  DateTime? remoteModified,
}) {
  if (!hasLocalData && remoteExists) return SyncStartupAction.download;
  if (hasLocalData && !remoteExists) return SyncStartupAction.upload;
  if (!hasLocalData && !remoteExists) return SyncStartupAction.none;
  if (hasPendingLocalChanges && hasLocalData && remoteExists) {
    return SyncStartupAction.conflict;
  }

  if (lastKnownRemoteModified != null &&
      remoteModified != null &&
      lastKnownRemoteModified.toUtc().isAtSameMomentAs(remoteModified.toUtc())) {
    return SyncStartupAction.none;
  }

  return SyncStartupAction.conflict;
}

/// Returns the newest backup candidate from Drive results.
drive.File? selectNewestBackupFile(Iterable<drive.File> files) {
  final candidates = files
      .where((file) => file.id != null && file.id!.isNotEmpty)
      .toList()
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
    scopes: [_kDriveScope],
  );

  GoogleSignInAccount? _currentUser;
  bool _isSyncing = false;
  String? _lastSyncError;
  Future<void> _operationQueue = Future<void>.value();
  bool _remoteBaselineReady = false;
  DateTime? _lastKnownRemoteModified;

  static const _lastRemoteModifiedKey = 'google_drive_last_remote_modified';
  static const _lastRemoteAccountKey = 'google_drive_last_remote_account';

  /// Поточний Google-акаунт (null = не авторизований).
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Чи виконується синхронізація прямо зараз.
  bool get isSyncing => _isSyncing;

  /// Остання помилка синхронізації (null = немає помилок).
  String? get lastSyncError => _lastSyncError;

  /// Чи підключений акаунт.
  bool get isConnected => _currentUser != null;

  Future<void> _loadRemoteBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAccount = prefs.getString(_lastRemoteAccountKey);
    final currentAccount = _currentUser?.email;
    if (savedAccount == null ||
        currentAccount == null ||
        savedAccount != currentAccount) {
      _lastKnownRemoteModified = null;
      _remoteBaselineReady = false;
      return;
    }

    final raw = prefs.getString(_lastRemoteModifiedKey);
    _lastKnownRemoteModified = raw == null ? null : DateTime.tryParse(raw);
    _remoteBaselineReady = _lastKnownRemoteModified != null;
  }

  Future<void> _saveRemoteBaseline(DateTime? modifiedTime) async {
    final baseline = (modifiedTime ?? DateTime.now()).toUtc();
    _lastKnownRemoteModified = baseline;
    _remoteBaselineReady = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRemoteModifiedKey, baseline.toIso8601String());
    final account = _currentUser?.email;
    if (account != null) {
      await prefs.setString(_lastRemoteAccountKey, account);
    }
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
      await _loadRemoteBaseline();
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
      await _loadRemoteBaseline();
      _lastSyncError = null;
      notifyListeners();
      return account != null;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDrive] Помилка входу: $e');
      debugPrint('$stackTrace');
      _lastSyncError = 'Помилка входу: $e';
      notifyListeners();
      return false;
    }
  }

  /// Вихід з акаунту.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _lastKnownRemoteModified = null;
    _remoteBaselineReady = false;
    _lastSyncError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastRemoteModifiedKey);
    await prefs.remove(_lastRemoteAccountKey);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // РОБОТА З ДИСКОМ
  // ---------------------------------------------------------------------------

  /// Selects a non-destructive action for the first sync after sign-in.
  /// Existing local data is never overwritten unless the caller explicitly
  /// chooses the download action.
  Future<SyncStartupAction> decideStartupAction({
    required bool hasLocalData,
    bool hasPendingLocalChanges = false,
  }) async {
    if (_currentUser == null) return SyncStartupAction.none;

    try {
      final session = await _getDriveSession();
      if (session == null) return SyncStartupAction.none;

      drive.File? remoteFile;
      try {
        remoteFile = await _findBackupFile(session.api);
      } finally {
        session.close();
      }

      final remoteExists = remoteFile != null;
      final action = resolveSyncStartupAction(
        hasLocalData: hasLocalData,
        remoteExists: remoteExists,
        hasPendingLocalChanges: hasPendingLocalChanges,
        lastKnownRemoteModified: _lastKnownRemoteModified,
        remoteModified: remoteFile?.modifiedTime,
      );
      if (!hasLocalData && !remoteExists) {
        // The cloud state was successfully checked and is empty. The first
        // local save can safely create the initial backup.
        _remoteBaselineReady = true;
      } else if (action == SyncStartupAction.none) {
        _remoteBaselineReady = true;
      } else if (action == SyncStartupAction.upload) {
        _remoteBaselineReady = false;
      }
      return action;
    } catch (e, stackTrace) {
      _lastSyncError = 'Не вдалося перевірити Google Drive: $e';
      debugPrint('[GoogleDrive] Помилка перевірки стану: $e');
      debugPrint('$stackTrace');
      notifyListeners();
      return SyncStartupAction.error;
    }
  }

  /// Marks a successful download or an explicitly accepted local state as the
  /// current sync baseline.
  void markRemoteBaselineReady() {
    _remoteBaselineReady = true;
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

  /// Знайти найсвіжіший файл бекапу в appDataFolder (якщо він існує).
  /// Помилки API навмисно пробрасываются викликачу: невідомий стан хмари
  /// не можна трактувати як відсутній файл і замінювати локальним backup.
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
    if (_currentUser == null || !_remoteBaselineReady) return false;
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

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

      drive.File? uploadedFile;
      if (existingFile?.id != null) {
        // Файл вже є — оновлюємо вміст (PATCH без зміни батьківської папки).
        uploadedFile = await api.files.update(
          drive.File(),
          existingFile!.id!,
          uploadMedia: media,
        );
        debugPrint(
            '[GoogleDrive] Бекап оновлено (PATCH). ID: ${existingFile.id}');
      } else {
        // Файлу ще немає — створюємо.
        final driveFile = drive.File()
          ..name = _kBackupFileName
          ..parents = ['appDataFolder'];
        uploadedFile = await api.files.create(driveFile, uploadMedia: media);
        debugPrint('[GoogleDrive] Бекап створено (POST).');
      }

      final remoteModified = uploadedFile.modifiedTime ??
          (await _findBackupFile(api))?.modifiedTime;
      if (remoteModified == null) {
        throw StateError('Google Drive did not return backup modifiedTime.');
      }
      await _saveRemoteBaseline(remoteModified);
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDrive] Помилка вивантаження: $e');
      debugPrint('$stackTrace');
      _lastSyncError = 'Помилка синхронізації: $e';
      return false;
    } finally {
      session?.close();
      if (_isSyncing) {
        _isSyncing = false;
        notifyListeners();
      }
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
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

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
        _isSyncing = false;
        notifyListeners();
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
        if (await previousFile.exists()) await previousFile.rename(targetFile.path);
        rethrow;
      }

      await _saveRemoteBaseline(remoteFile.modifiedTime);
      debugPrint('[GoogleDrive] Бекап завантажено в $targetFilePath.');
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      debugPrint('[GoogleDrive] Помилка завантаження: $e');
      debugPrint('$stackTrace');
      _lastSyncError = 'Помилка завантаження: $e';
      return false;
    } finally {
      session?.close();
      if (_isSyncing) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }
}
