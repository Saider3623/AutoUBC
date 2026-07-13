import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

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

  /// Поточний Google-акаунт (null = не авторизований).
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Чи виконується синхронізація прямо зараз.
  bool get isSyncing => _isSyncing;

  /// Остання помилка синхронізації (null = немає помилок).
  String? get lastSyncError => _lastSyncError;

  /// Чи підключений акаунт.
  bool get isConnected => _currentUser != null;

  // ---------------------------------------------------------------------------
  // АВТОРИЗАЦІЯ
  // ---------------------------------------------------------------------------

  /// Тихий вхід — викликається при старті додатку.
  /// Не показує жодних діалогів, якщо акаунт вже прив'язаний.
  Future<bool> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _currentUser = account;
      notifyListeners();
      return account != null;
    } catch (e) {
      debugPrint('[GoogleDrive] Тихий вхід не вдався: $e');
      return false;
    }
  }

  /// Інтерактивний вхід — викликається лише по кнопці.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _currentUser = account;
      notifyListeners();
      return account != null;
    } catch (e) {
      debugPrint('[GoogleDrive] Помилка входу: $e');
      _lastSyncError = 'Помилка входу: $e';
      notifyListeners();
      return false;
    }
  }

  /// Вихід з акаунту.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // РОБОТА З ДИСКОМ
  // ---------------------------------------------------------------------------

  /// Отримати авторизований HTTP-клієнт для googleapis.
  Future<drive.DriveApi?> _getDriveApi() async {
    final user = _currentUser;
    if (user == null) return null;
    try {
      final auth = await user.authentication;
      final client = _AuthenticatedClient(
        {'Authorization': 'Bearer ${auth.accessToken}'},
        http.Client(),
      );
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('[GoogleDrive] Помилка отримання DriveApi: $e');
      return null;
    }
  }

  /// Знайти ID файлу бекапу в appDataFolder (якщо він існує).
  Future<String?> _findBackupFileId(drive.DriveApi api) async {
    try {
      final list = await api.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_kBackupFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );
      if (list.files != null && list.files!.isNotEmpty) {
        return list.files!.first.id;
      }
    } catch (e) {
      debugPrint('[GoogleDrive] Помилка пошуку файлу: $e');
    }
    return null;
  }

  /// Вивантажити файл БД в Google Drive (appDataFolder).
  /// Якщо файл вже існує — оновлює (PATCH), якщо ні — створює (POST).
  Future<bool> uploadBackup(String dbFilePath) async {
    if (_currentUser == null) return false;
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Не вдалося ініціалізувати Drive API');

      final dbFile = File(dbFilePath);
      if (!await dbFile.exists()) {
        throw Exception('Файл БД не знайдено: $dbFilePath');
      }

      final existingId = await _findBackupFileId(api);
      final media = drive.Media(
        dbFile.openRead(),
        await dbFile.length(),
        contentType: 'application/octet-stream',
      );

      if (existingId != null) {
        // Файл вже є — оновлюємо вміст (PATCH без зміни батьківської папки).
        await api.files.update(
          drive.File(),
          existingId,
          uploadMedia: media,
        );
        debugPrint('[GoogleDrive] Бекап оновлено (PATCH). ID: $existingId');
      } else {
        // Файлу ще немає — створюємо.
        final driveFile = drive.File()
          ..name = _kBackupFileName
          ..parents = ['appDataFolder'];
        await api.files.create(driveFile, uploadMedia: media);
        debugPrint('[GoogleDrive] Бекап створено (POST).');
      }
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[GoogleDrive] Помилка вивантаження: $e');
      _lastSyncError = 'Помилка синхронізації: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Завантажити бекап з Google Drive і записати в локальний файл.
  /// Повертає true, якщо файл успішно завантажено.
  Future<bool> downloadBackup(String targetFilePath) async {
    if (_currentUser == null) return false;
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      final api = await _getDriveApi();
      if (api == null) throw Exception('Не вдалося ініціалізувати Drive API');

      final fileId = await _findBackupFileId(api);
      if (fileId == null) {
        debugPrint('[GoogleDrive] Бекап на Диску не знайдено.');
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final response = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final targetFile = File(targetFilePath);
      final sink = targetFile.openWrite();
      await sink.addStream(response.stream);
      await sink.close();

      debugPrint('[GoogleDrive] Бекап завантажено в $targetFilePath.');
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[GoogleDrive] Помилка завантаження: $e');
      _lastSyncError = 'Помилка завантаження: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Перевірити, чи є бекап на Диску.
  Future<bool> hasRemoteBackup() async {
    if (_currentUser == null) return false;
    final api = await _getDriveApi();
    if (api == null) return false;
    return await _findBackupFileId(api) != null;
  }
}
