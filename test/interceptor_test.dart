import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:htpio/htpio.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class RecordingMiddleware extends HtpioMiddleware {
  final events = <String>[];

  @override
  Future<void> beforeRequest(HtpioRequest request) async =>
      events.add('before ${request.method}');

  @override
  Future<void> afterResponse(HtpioResponse response) async =>
      events.add('after ${response.statusCode}');

  @override
  Future<void> onError(HtpioError error) async =>
      events.add('error ${error.type.name}');
}

class TagInterceptor extends HtpioInterceptor {
  TagInterceptor(this.tag, this.log);

  final String tag;
  final List<String> log;

  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    log.add('req $tag');
    request.headers['x-$tag'] = '1';
    return request;
  }

  @override
  Future<HtpioResponse> onResponse(HtpioResponse response) async {
    log.add('res $tag');
    return response;
  }
}

class FallbackInterceptor extends HtpioInterceptor {
  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async =>
      HtpioResponse(data: 'fallback', statusCode: 200, request: request);
}

void main() {
  late List<http.Request> sent;

  HtpioClient clientWith(List<http.Response> responses) {
    sent = [];
    var i = 0;
    return HtpioClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        sent.add(request);
        return responses[
            i++ < responses.length - 1 ? i - 1 : responses.length - 1];
      }),
    );
  }

  http.Response ok([Object body = const {}]) =>
      http.Response(jsonEncode(body), 200);
  http.Response status(int code) => http.Response('{}', code);

  test('interceptors run in order, responses in reverse', () async {
    final log = <String>[];
    final htpio = clientWith([ok()])
      ..addInterceptor(TagInterceptor('a', log))
      ..addInterceptor(TagInterceptor('b', log));
    await htpio.get('/');
    expect(log, ['req a', 'req b', 'res b', 'res a']);
    expect(sent.single.headers.keys, containsAll(['x-a', 'x-b']));
  });

  test('middleware sees requests, responses and errors', () async {
    final mw = RecordingMiddleware();
    final htpio = clientWith([ok(), status(400)])..use(mw);
    await htpio.get('/');
    await expectLater(htpio.get('/'), throwsA(isA<HtpioError>()));
    expect(mw.events,
        ['before GET', 'after 200', 'before GET', 'error badResponse']);
  });

  test('middleware onError runs once after all retries', () async {
    final mw = RecordingMiddleware();
    final htpio = clientWith([status(503)])
      ..use(mw)
      ..addInterceptor(
          RetryInterceptor(maxRetries: 2, baseDelay: Duration.zero));
    await expectLater(htpio.get('/'), throwsA(isA<HtpioError>()));
    expect(sent, hasLength(3));
    expect(
        mw.events.where((e) => e.startsWith('error')), ['error badResponse']);
  });

  test('onError can recover with a response', () async {
    final htpio = clientWith([status(500)])
      ..addInterceptor(FallbackInterceptor());
    expect((await htpio.get<String>('/')).data, 'fallback');
  });

  group('RetryInterceptor', () {
    test('retries retryable status codes until success', () async {
      final htpio = clientWith([
        status(503),
        status(502),
        ok({'ok': true})
      ])
        ..addInterceptor(RetryInterceptor(baseDelay: Duration.zero));
      final res = await htpio.get('/');
      expect(res.data, {'ok': true});
      expect(sent, hasLength(3));
    });

    test('keeps the response type through retries', () async {
      final htpio = clientWith([
        status(500),
        ok({'id': 3})
      ])
        ..addInterceptor(RetryInterceptor(baseDelay: Duration.zero));
      final res = await htpio.get<int>('/', fromJson: (j) => j['id'] as int);
      expect(res.data, 3);
    });

    test('gives up after maxRetries with the last error', () async {
      final htpio = clientWith([status(503)])
        ..addInterceptor(
            RetryInterceptor(maxRetries: 2, baseDelay: Duration.zero));
      await expectLater(
        htpio.get('/'),
        throwsA(isA<HtpioError>().having((e) => e.statusCode, 'status', 503)),
      );
      expect(sent, hasLength(3));
    });

    test('does not retry POST or 4xx by default', () async {
      final htpio = clientWith([status(503), status(404)])
        ..addInterceptor(RetryInterceptor(baseDelay: Duration.zero));
      await expectLater(htpio.post('/', data: {}), throwsA(isA<HtpioError>()));
      await expectLater(htpio.get('/'), throwsA(isA<HtpioError>()));
      expect(sent, hasLength(2));
    });

    test('retries connection errors', () async {
      var calls = 0;
      final htpio = HtpioClient(
        httpClient: MockClient((_) async {
          if (calls++ == 0) throw http.ClientException('reset');
          return http.Response('{}', 200);
        }),
      )..addInterceptor(RetryInterceptor(baseDelay: Duration.zero));
      await htpio.get('https://api.test/');
      expect(calls, 2);
    });

    test('backoff doubles', () {
      final retry =
          RetryInterceptor(baseDelay: const Duration(milliseconds: 100));
      expect(retry.delayFor(1).inMilliseconds, inInclusiveRange(100, 110));
      expect(retry.delayFor(3).inMilliseconds, inInclusiveRange(400, 440));
    });
  });

  group('AuthTokenInterceptor', () {
    test('adds, updates and clears the token', () async {
      final auth = AuthTokenInterceptor(token: 'one');
      final htpio = clientWith([ok()])..addInterceptor(auth);
      await htpio.get('/');
      auth.setToken('two');
      await htpio.get('/');
      auth.clearToken();
      await htpio.get('/');
      expect(
          sent.map(
              (r) => r.headers['Authorization'] ?? r.headers['authorization']),
          ['Bearer one', 'Bearer two', null]);
    });

    test('tokenProvider supplies the token lazily', () async {
      final htpio = clientWith([ok()])
        ..addInterceptor(AuthTokenInterceptor(
          tokenProvider: () async => 'stored',
          headerName: 'x-token',
          tokenPrefix: '',
        ));
      await htpio.get('/');
      expect(sent.single.headers['x-token'], 'stored');
    });

    test('refreshes once on 401 and retries with the new token', () async {
      var refreshes = 0;
      final auth = AuthTokenInterceptor(
        token: 'old',
        onRefreshToken: () async {
          refreshes++;
          return 'new';
        },
      );
      final htpio = clientWith([
        status(401),
        ok({'me': 1})
      ])
        ..addInterceptor(auth);
      final res = await htpio.get('/me');
      expect(res.data, {'me': 1});
      expect(refreshes, 1);
      expect(auth.token, 'new');
      expect(sent.last.headers['authorization'], 'Bearer new');
    });

    test('does not loop when the refreshed token is also rejected', () async {
      final htpio = clientWith([status(401)])
        ..addInterceptor(AuthTokenInterceptor(onRefreshToken: () async => 'x'));
      await expectLater(htpio.get('/'), throwsA(isA<HtpioError>()));
      expect(sent, hasLength(2));
    });
  });

  test('HtpioLogInterceptor hides sensitive headers', () async {
    final lines = <String>[];
    final htpio = clientWith([
      ok({'a': 1})
    ])
      ..addInterceptor(AuthTokenInterceptor(token: 'secret'))
      ..addInterceptor(HtpioLogInterceptor(
        requestHeaders: true,
        responseBody: true,
        logPrint: lines.add,
      ));
    await htpio.get('/x');
    expect(lines.first, '--> GET https://api.test/x');
    expect(lines.join('\n'), isNot(contains('secret')));
    expect(lines.join('\n'), contains('Authorization: ***'));
    expect(lines.last, '{a: 1}');
  });
}
