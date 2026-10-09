import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:htpio/htpio.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OfflineMode', () {
    test('fails fast offline, queues writes and replays them online', () async {
      var online = false;
      final sent = <String>[];
      final htpio = HtpioClient(
        baseUrl: 'https://api.test',
        httpClient: MockClient((r) async {
          sent.add('${r.method} ${r.url.path}');
          return http.Response('{"saved":true}', 200);
        }),
      );
      final offline = OfflineMode(
        checkInterval: const Duration(hours: 1),
        connectivityChecker: () async => online,
      );
      htpio.use(offline);
      await offline.refresh();
      expect(offline.isOnline, isFalse);

      await expectLater(
        htpio.post('/notes', data: {'t': 1}),
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.offline)),
      );
      await expectLater(htpio.get('/notes'), throwsA(isA<HtpioError>()));
      expect(offline.queuedRequestsCount, 1);
      expect(sent, isEmpty);

      final replayed = offline.replayResults.first;
      final status = offline.connectivityStream.first;
      online = true;
      await offline.refresh();

      expect(await status, isTrue);
      expect(await replayed, isA<HtpioResponse>());
      expect(sent, ['POST /notes']);
      expect(offline.queuedRequestsCount, 0);
      offline.dispose();
    });
  });

  group('HtpioDownloadManager', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('htpio'));
    tearDown(() async => dir.delete(recursive: true));

    test('writes the file and reports progress', () async {
      final bytes = List<int>.generate(1000, (i) => i % 256);
      final manager = HtpioDownloadManager(
        httpClient: MockClient.streaming((request, _) async {
          return http.StreamedResponse(
            Stream.fromIterable([bytes.sublist(0, 500), bytes.sublist(500)]),
            200,
            contentLength: bytes.length,
          );
        }),
      );
      final progress = <double>[];
      final file = await manager.downloadFile(
        url: 'https://files.test/a.bin',
        savePath: '${dir.path}/nested/a.bin',
        onProgress: progress.add,
      );
      expect(await file.readAsBytes(), bytes);
      expect(progress, [0.5, 1.0]);
      expect(manager.isDownloading('https://files.test/a.bin'), isFalse);
      manager.dispose();
    });

    test('throws badResponse for HTTP errors', () async {
      final manager = HtpioDownloadManager(
        httpClient: MockClient((_) async => http.Response('nope', 404)),
      );
      await expectLater(
        manager.downloadFile(
            url: 'https://files.test/x', savePath: '${dir.path}/x'),
        throwsA(isA<HtpioError>().having((e) => e.statusCode, 'status', 404)),
      );
      expect(File('${dir.path}/x').existsSync(), isFalse);
      manager.dispose();
    });

    test('cancel stops the download and removes the partial file', () async {
      final controller = StreamController<List<int>>();
      final manager = HtpioDownloadManager(
        httpClient: MockClient.streaming((request, _) async =>
            http.StreamedResponse(controller.stream, 200, contentLength: 10)),
      );
      const url = 'https://files.test/big';
      final future =
          manager.downloadFile(url: url, savePath: '${dir.path}/big');
      controller.add([1, 2, 3]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(manager.isDownloading(url), isTrue);
      expect(manager.getProgress(url), closeTo(0.3, 0.001));

      manager.cancelDownload(url);
      await expectLater(
        future,
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.cancel)),
      );
      expect(File('${dir.path}/big').existsSync(), isFalse);
      await controller.close();
      manager.dispose();
    });
  });

  test('uploads files from disk (FormData and legacy API)', () async {
    final dir = await Directory.systemTemp.createTemp('htpio');
    final photo = File('${dir.path}/photo.txt')..writeAsStringSync('PIXELS');
    final bodies = <String>[];
    final htpio = HtpioClient(
      httpClient: MockClient((r) async {
        bodies.add(utf8.decode(r.bodyBytes));
        return http.Response('{"id":1}', 200);
      }),
    );

    await htpio.post(
      'https://api.test/upload',
      data: FormData.fromMap({
        'avatar':
            HtpioMultipartFile.fromPath(photo.path, contentType: 'text/plain'),
      }),
    );
    // ignore: deprecated_member_use_from_same_package
    await htpio.postSingleFileWithDataRequest<int>(
      endpoint: 'https://api.test/upload',
      fileJsonKey: 'doc',
      file: photo,
      data: {'note': 'hi'},
      fromJson: (j) => j['id'] as int,
    );

    expect(bodies[0], contains('name="avatar"; filename="photo.txt"'));
    expect(bodies[0], contains('PIXELS'));
    expect(bodies[1], contains('name="doc"'));
    expect(bodies[1], contains('name="note"'));
    await dir.delete(recursive: true);
  });

  test('DebugConsole keeps a bounded log', () {
    final console = DebugConsole()..clear();
    for (var i = 0; i < DebugConsole.maxLogs + 10; i++) {
      console.log('line $i');
    }
    expect(console.getLogs(), hasLength(DebugConsole.maxLogs));
    expect(
        console.getLogs().last, contains('line ${DebugConsole.maxLogs + 9}'));
  });
}
