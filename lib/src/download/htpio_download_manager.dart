import 'dart:async';

import 'package:http/http.dart' as http;

import '../../htpio_error.dart';
import '../platform/platform.dart';

/// Downloads files to disk with progress, pause, resume and cancel.
/// Not available on the web (use `HtpioClient.get` with
/// `responseType: ResponseType.bytes` there).
///
/// ```dart
/// final downloads = HtpioDownloadManager();
/// final file = await downloads.downloadFile(
///   url: 'https://example.com/video.mp4',
///   savePath: '${dir.path}/video.mp4',
///   onProgress: (p) => print('${(p * 100).toStringAsFixed(0)}%'),
/// );
/// ```
class HtpioDownloadManager {
  HtpioDownloadManager({http.Client? httpClient})
      : _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final http.Client _http;
  final bool _ownsClient;
  final Map<String, _DownloadTask> _tasks = {};
  final StreamController<DownloadProgress> _progressController =
      StreamController.broadcast();

  /// Progress of every running download.
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// Downloads [url] to [savePath] and returns the file. Throws
  /// [HtpioError] on HTTP errors, network errors or [cancelDownload]; a
  /// partial file is deleted on failure.
  Future<File> downloadFile({
    required String url,
    required String savePath,
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  }) async {
    if (_tasks.containsKey(url)) {
      throw HtpioError('$url is already downloading');
    }
    final task = _DownloadTask();
    _tasks[url] = task;
    FileTarget? target;

    try {
      final request = http.AbortableRequest(
        'GET',
        Uri.parse(url),
        abortTrigger: task.abort.future,
      )..headers.addAll(headers ?? const {});

      final response = await _http.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        unawaited(response.stream.drain<void>().catchError((_) {}));
        throw HtpioError(
          'Download failed with status code ${response.statusCode}',
          statusCode: response.statusCode,
          type: HtpioErrorType.badResponse,
        );
      }
      if (task.cancelled) throw _cancelled(url);

      final output = target = await FileTarget.open(savePath);
      final total = response.contentLength ?? -1;
      var received = 0;

      task.subscription = response.stream.listen(
        (chunk) {
          output.add(chunk);
          received += chunk.length;
          final progress = total > 0 ? received / total : 0.0;
          task.progress = progress;
          if (!_progressController.isClosed) {
            _progressController.add(DownloadProgress(
              url: url,
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
            ));
          }
          onProgress?.call(progress);
        },
        onError: task.fail,
        onDone: task.finish,
        cancelOnError: true,
      );

      await task.done.future;
      await output.close();
      return output.file;
    } catch (error, stackTrace) {
      await target?.discard();
      if (task.cancelled) throw _cancelled(url);
      if (error is HtpioError) rethrow;
      throw HtpioError(
        'Download failed: $error',
        type: error is http.ClientException
            ? HtpioErrorType.connectionError
            : HtpioErrorType.unknown,
        originalError: error,
        stackTrace: stackTrace,
      );
    } finally {
      _tasks.remove(url);
    }
  }

  HtpioError _cancelled(String url) =>
      HtpioError('Download of $url was cancelled', type: HtpioErrorType.cancel);

  /// Pauses receiving data. The connection stays open.
  void pauseDownload(String url) => _tasks[url]?.subscription?.pause();

  void resumeDownload(String url) => _tasks[url]?.subscription?.resume();

  /// Stops the download; `downloadFile` throws an `HtpioError` of type
  /// `cancel` and removes the partial file.
  void cancelDownload(String url) => _tasks[url]?.cancel();

  /// Progress from 0.0 to 1.0, or `null` when [url] is not downloading.
  double? getProgress(String url) => _tasks[url]?.progress;

  bool isDownloading(String url) => _tasks.containsKey(url);

  /// Cancels all downloads and releases resources.
  void dispose() {
    for (final task in _tasks.values.toList()) {
      task.cancel();
    }
    _progressController.close();
    if (_ownsClient) _http.close();
  }
}

class _DownloadTask {
  final Completer<void> abort = Completer<void>();
  final Completer<void> done = Completer<void>();
  StreamSubscription<List<int>>? subscription;
  double progress = 0;
  bool cancelled = false;

  void finish() {
    if (!done.isCompleted) done.complete();
  }

  void fail(Object error, [StackTrace? stackTrace]) {
    if (!done.isCompleted) done.completeError(error, stackTrace);
  }

  void cancel() {
    if (cancelled) return;
    cancelled = true;
    if (!abort.isCompleted) abort.complete();
    unawaited(subscription?.cancel());
    fail(StateError('cancelled'));
  }
}

/// Progress event emitted by [HtpioDownloadManager.progressStream].
class DownloadProgress {
  DownloadProgress({
    required this.url,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
  });

  final String url;

  /// 0.0 to 1.0. Stays 0 when the server sends no `Content-Length`.
  final double progress;
  final int downloadedBytes;

  /// Total size in bytes, or -1 when unknown.
  final int totalBytes;

  @override
  String toString() =>
      'DownloadProgress(url: $url, progress: ${(progress * 100).toStringAsFixed(1)}%, '
      '$downloadedBytes/$totalBytes bytes)';
}
