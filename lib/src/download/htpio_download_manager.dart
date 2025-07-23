// File: lib/src/download/htpio_download_manager.dart
import 'dart:isolate';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import '../../htpio_error.dart';

class HtpioDownloadManager {
  final Map<String, StreamSubscription> _activeDownloads = {};
  final Map<String, double> _downloadProgress = {};
  final StreamController<DownloadProgress> _progressController = StreamController.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Future<File> downloadFile({
    required String url,
    required String savePath,
    Map<String, String>? headers,
    Function(double progress)? onProgress,
  }) async {
    try {
      final httpClient = HttpClient();
      final uri = Uri.parse(url);
      final request = await httpClient.getUrl(uri);
      
      // Add headers if provided
      headers?.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw HtpioError('Download failed with status: ${response.statusCode}');
      }

      final file = File(savePath);
      await file.parent.create(recursive: true);
      
      final sink = file.openWrite();
      final contentLength = response.contentLength;
      int downloadedBytes = 0;

      final subscription = response.listen(
        (data) {
          sink.add(data);
          downloadedBytes += data.length;
          
          if (contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            _downloadProgress[url] = progress;
            
            final progressEvent = DownloadProgress(
              url: url,
              progress: progress,
              downloadedBytes: downloadedBytes,
              totalBytes: contentLength,
            );
            
            _progressController.add(progressEvent);
            onProgress?.call(progress);
          }
        },
        onDone: () async {
          await sink.close();
          _activeDownloads.remove(url);
          _downloadProgress.remove(url);
          httpClient.close();
        },
        onError: (error) async {
          await sink.close();
          _activeDownloads.remove(url);
          _downloadProgress.remove(url);
          httpClient.close();
          throw HtpioError('Download failed: $error');
        },
      );

      _activeDownloads[url] = subscription;
      await subscription.asFuture();
      
      return file;
    } catch (e) {
      throw HtpioError('Download failed: $e');
    }
  }

  void pauseDownload(String url) {
    _activeDownloads[url]?.pause();
  }

  void resumeDownload(String url) {
    _activeDownloads[url]?.resume();
  }

  void cancelDownload(String url) {
    _activeDownloads[url]?.cancel();
    _activeDownloads.remove(url);
    _downloadProgress.remove(url);
  }

  double? getProgress(String url) => _downloadProgress[url];
  
  bool isDownloading(String url) => _activeDownloads.containsKey(url);
  
  void dispose() {
    for (final subscription in _activeDownloads.values) {
      subscription.cancel();
    }
    _activeDownloads.clear();
    _downloadProgress.clear();
    _progressController.close();
  }
}

class DownloadProgress {
  final String url;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;

  DownloadProgress({
    required this.url,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
  });

  @override
  String toString() {
    return 'DownloadProgress(url: $url, progress: ${(progress * 100).toStringAsFixed(1)}%, $downloadedBytes/$totalBytes bytes)';
  }
}
