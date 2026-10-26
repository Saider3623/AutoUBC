import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Collects every log line produced by the app (`print`, `debugPrint`,
/// framework errors, uncaught async errors and explicit [RemoteLog.add] calls)
/// and uploads it to a private GitHub repository.
///
/// The feature is off unless the build provides a token:
///
/// ```text
/// flutter run --dart-define-from-file=.secrets/remote_log.json
/// ```
///
/// Without `LOG_GITHUB_TOKEN` every method here is a no-op, so builds made
/// without the secrets file behave exactly as before.
///
/// Each launch writes one file `logs/<yyyy-MM-dd>/<HHmmss>_<os>_<id>.log`.
/// Lines are first appended to a local file, so a session that ended with a
/// crash or a killed process is uploaded on the next launch.
class RemoteLog {
  RemoteLog._();

  static const String _token = String.fromEnvironment('LOG_GITHUB_TOKEN');
  static const String _repo = String.fromEnvironment(
    'LOG_GITHUB_REPO',
    defaultValue: 'fesh-biz/autoubc-logs',
  );
  static const String _branch =
      String.fromEnvironment('LOG_GITHUB_BRANCH', defaultValue: 'main');

  /// Upload period while the app is running. GitHub limits content-creating
  /// requests to ~500 per hour, so this must not be much shorter.
  static const Duration _uploadInterval = Duration(seconds: 30);

  /// A session file is split into parts after this size (Contents API payload
  /// stays well under its 1 MB comfort limit after base64 encoding).
  static const int _maxPartBytes = 512 * 1024;

  /// Old local session files kept when uploads keep failing.
  static const int _maxPendingFiles = 30;

  static bool get isEnabled => _token.isNotEmpty;

  static bool _started = false;
  static final List<String> _early = [];
  static Directory? _dir;
  static File? _file;
  static String _remoteBase = '';
  static int _part = 1;
  static String? _remoteSha;
  static bool _dirty = false;
  static Future<void> _queue = Future.value();
  static Timer? _timer;
  static AppLifecycleListener? _lifecycle;

  /// Runs [body] with log capture enabled. When remote logging is disabled it
  /// simply calls [body].
  static void run(Future<void> Function() body) {
    if (!isEnabled) {
      body();
      return;
    }
    runZoned(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        _installHooks();
        await _start();
        await body();
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          add(line);
          parent.print(zone, line);
        },
      ),
    );
  }

  /// Adds one log line. Safe to call from anywhere; ignored when disabled.
  static void add(String? message) {
    if (!isEnabled || message == null) return;
    final ts = DateTime.now().toIso8601String();
    final time = ts.length >= 23 ? ts.substring(11, 23) : ts;
    final line = '$time $message\n';
    final file = _file;
    if (file == null) {
      _early.add(line);
      return;
    }
    try {
      file.writeAsStringSync(line, mode: FileMode.append, flush: false);
      _dirty = true;
      if (file.lengthSync() > _maxPartBytes) _rollover();
    } catch (_) {
      // Logging must never break the app.
    }
  }

  /// Uploads the current session immediately (e.g. when the app goes to the
  /// background).
  static Future<void> flush() {
    if (!_started) return Future.value();
    return _enqueue(_uploadCurrent);
  }

  static void _installHooks() {
    // `debugPrint` ends in `print`, so the zone hook in [run] already captures
    // it; overriding it here would duplicate every line.
    final originalFlutterError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      add('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
      if (originalFlutterError != null) {
        originalFlutterError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final originalPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      add('[Uncaught] $error\n$stack');
      // Keep the default reporting so behaviour stays the same.
      return originalPlatformError?.call(error, stack) ?? false;
    };
  }

  static Future<void> _start() async {
    if (_started) return;
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory('${support.path}/remote_logs');
      await dir.create(recursive: true);
      _dir = dir;

      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final date = '${now.year}-${two(now.month)}-${two(now.day)}';
      final time = '${two(now.hour)}${two(now.minute)}${two(now.second)}';
      final id = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
      _remoteBase = 'logs/$date/${time}_${Platform.operatingSystem}_$id';

      // Files left over from previous launches are uploaded first.
      final leftovers = await _listLocalFiles();

      _file = File('${dir.path}/${_encodeLocalName(_remotePath())}');
      _started = true;

      add('=== AutoUBC session $_remoteBase ===');
      add('os: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      add('dart: ${Platform.version}');
      add('mode: ${kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'debug'}');
      add('locale: ${Platform.localeName}');
      for (final line in _early) {
        _file!.writeAsStringSync(line, mode: FileMode.append);
      }
      _early.clear();

      _enqueue(() => _uploadLeftovers(leftovers));
      _enqueue(_uploadCurrent);
      _timer = Timer.periodic(_uploadInterval, (_) {
        if (_dirty) flush();
      });
      _lifecycle = AppLifecycleListener(
        onPause: flush,
        onHide: flush,
        onDetach: flush,
      );
    } catch (e) {
      debugPrint('[RemoteLog] start failed: $e');
    }
  }

  static String _remotePath() =>
      _part == 1 ? '$_remoteBase.log' : '${_remoteBase}_part$_part.log';

  // Local file names keep the remote path so leftovers can be re-uploaded.
  static String _encodeLocalName(String remotePath) =>
      remotePath.replaceAll('/', '__');

  static String _decodeLocalName(String name) => name.replaceAll('__', '/');

  static Future<List<File>> _listLocalFiles() async {
    final dir = _dir;
    if (dir == null) return [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    while (files.length > _maxPendingFiles) {
      try {
        files.removeAt(0).deleteSync();
      } catch (_) {}
    }
    return files;
  }

  static void _rollover() {
    final finished = _file;
    final finishedSha = _remoteSha;
    _enqueue(() async {
      if (finished == null) return;
      final ok = await _put(_pathOf(finished), finished, finishedSha);
      if (ok != null) _safeDelete(finished);
    });
    _part++;
    _remoteSha = null;
    _file = File('${_dir!.path}/${_encodeLocalName(_remotePath())}');
    _dirty = true;
  }

  static String _pathOf(File file) =>
      _decodeLocalName(file.uri.pathSegments.last);

  static Future<void> _uploadLeftovers(List<File> files) async {
    for (final file in files) {
      final sha = await _put(_pathOf(file), file, null, lookupSha: true);
      if (sha != null) _safeDelete(file);
    }
  }

  static Future<void> _uploadCurrent() async {
    final file = _file;
    if (file == null || !_dirty) return;
    _dirty = false;
    final path = _remotePath();
    final sha = await _put(path, file, _remoteSha);
    // A rollover may have switched to a new part while uploading.
    if (!identical(file, _file)) return;
    if (sha == null) {
      _dirty = true;
    } else {
      _remoteSha = sha;
    }
  }

  /// Creates or replaces [path] in the repository with the content of [file].
  /// Returns the new blob SHA, or null on failure.
  static Future<String?> _put(
    String path,
    File file,
    String? sha, {
    bool lookupSha = false,
  }) async {
    try {
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      if (lookupSha) sha = await _getSha(path);
      var response = await _putRequest(path, bytes, sha);
      if (response.statusCode == 409 || response.statusCode == 422) {
        // Stale or missing SHA: refresh it and try once more.
        response = await _putRequest(path, bytes, await _getSha(path));
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['content'] as Map<String, dynamic>)['sha'] as String;
      }
      _console('upload $path failed: ${response.statusCode} '
          '${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
    } catch (e) {
      _console('upload $path error: $e');
    }
    return null;
  }

  static Future<http.Response> _putRequest(
    String path,
    List<int> bytes,
    String? sha,
  ) {
    return http
        .put(
          _contentsUri(path),
          headers: _headers,
          body: jsonEncode({
            'message': 'log: $path',
            'content': base64Encode(bytes),
            'branch': _branch,
            if (sha != null) 'sha': sha,
          }),
        )
        .timeout(const Duration(seconds: 60));
  }

  static Future<String?> _getSha(String path) async {
    final response = await http
        .get(
          _contentsUri(path).replace(queryParameters: {'ref': _branch}),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body);
    return json is Map<String, dynamic> ? json['sha'] as String? : null;
  }

  static Uri _contentsUri(String path) =>
      Uri.parse('https://api.github.com/repos/$_repo/contents/$path');

  static Map<String, String> get _headers => const {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      };

  static Future<void> _enqueue(Future<void> Function() job) {
    final next = _queue.then((_) => job()).catchError((Object e) {
      _console('queue error: $e');
    });
    _queue = next;
    return next;
  }

  static void _safeDelete(File file) {
    try {
      file.deleteSync();
    } catch (_) {}
  }

  // Writes to the console only; must not go through [add] to avoid loops.
  static void _console(String message) {
    Zone.root.print('[RemoteLog] $message');
  }

  @visibleForTesting
  static void disposeForTest() {
    _timer?.cancel();
    _lifecycle?.dispose();
  }
}
