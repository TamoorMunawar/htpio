// File: lib/src/download/htpio_download_manager.dart
import 'dart:isolate';
import 'dart:io';
import 'dart:async';

class HtpioDownloadManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  Future<void> startDownload(String url, String savePath) async {
    _isolate = await Isolate.spawn(_downloadIsolate, _receivePort.sendPort);
    _sendPort = await _receivePort.first as SendPort;
    _sendPort?.send([url, savePath]);
  }

  static void _downloadIsolate(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    port.listen((message) async {
      final url = message[0];
      final path = message[1];
      final file = File(path);
      await file.writeAsString('Downloaded content from $url');
    });
  }

  void pause() => _isolate?.kill(priority: Isolate.immediate);
}
