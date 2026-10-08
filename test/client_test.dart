import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:htpio/htpio.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class User {
  User(this.id, this.name);

  factory User.fromJson(Map<String, dynamic> json) =>
      User(json['id'] as int, json['name'] as String);

  final int id;
  final String name;
}

http.Response json(Object? body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late List<http.Request> sent;

  HtpioClient clientWith(
    FutureOr<http.Response> Function(http.Request) handler, {
    String baseUrl = 'https://api.test',
  }) {
    sent = [];
    return HtpioClient(
      baseUrl: baseUrl,
      httpClient: MockClient((request) async {
        sent.add(request);
        return handler(request);
      }),
    );
  }

  group('requests', () {
    test('joins baseUrl, default and per-request query and headers', () async {
      final htpio = clientWith((_) => json({}));
      htpio.headers['x-app'] = 'demo';
      htpio.queryParameters['lang'] = 'en';

      await htpio.get(
        '/users',
        queryParameters: {
          'page': 2,
          'tags': ['a', 'b'],
          'skip': null
        },
        headers: {'x-trace': '1'},
      );

      final req = sent.single;
      expect(req.method, 'GET');
      expect(req.url.toString(),
          'https://api.test/users?lang=en&page=2&tags=a&tags=b');
      expect(req.headers['x-app'], 'demo');
      expect(req.headers['x-trace'], '1');
    });

    test('absolute URLs ignore baseUrl', () async {
      final htpio = clientWith((_) => json({}));
      await htpio.get('https://other.test/ping');
      expect(sent.single.url.toString(), 'https://other.test/ping');
    });

    test('encodes Map bodies as JSON', () async {
      final htpio = clientWith((_) => json({'ok': true}, 201));
      final res = await htpio.post('/users', data: {'name': 'Ada'});

      expect(sent.single.headers['content-type'], contains('application/json'));
      expect(jsonDecode(sent.single.body), {'name': 'Ada'});
      expect(res.statusCode, 201);
      expect(res.data, {'ok': true});
    });

    test('supports PUT, PATCH, DELETE and HEAD', () async {
      final htpio = clientWith((_) => http.Response('', 204));
      await htpio.put('/a', data: {'x': 1});
      await htpio.patch('/a', data: {'x': 2});
      await htpio.delete('/a');
      await htpio.head('/a');
      expect(sent.map((r) => r.method), ['PUT', 'PATCH', 'DELETE', 'HEAD']);
    });

    test('encodes form-urlencoded, text and bytes bodies', () async {
      final htpio = clientWith((_) => json({}));
      await htpio.post(
        '/form',
        data: {'a': 1, 'b': 'x y'},
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );
      await htpio.post('/text', data: 'hello');
      await htpio.post('/bytes', data: [1, 2, 3]);

      expect(sent[0].body, 'a=1&b=x+y');
      expect(sent[1].body, 'hello');
      expect(sent[1].headers['content-type'], startsWith('text/plain'));
      expect(sent[2].bodyBytes, [1, 2, 3]);
    });

    test('sends FormData as multipart', () async {
      final htpio = clientWith((_) => json({'uploaded': true}));
      await htpio.post(
        '/upload',
        data: FormData.fromMap({
          'title': 'cat',
          'file': HtpioMultipartFile.fromBytes([1, 2], filename: 'a.png'),
          'more': [
            HtpioMultipartFile.fromString('hi', filename: 'b.txt'),
          ],
        }),
      );

      final req = sent.single;
      expect(req.headers['content-type'],
          startsWith('multipart/form-data; boundary='));
      final body = utf8.decode(req.bodyBytes, allowMalformed: true);
      expect(body, contains('name="title"'));
      expect(body, contains('filename="a.png"'));
      expect(body, contains('filename="b.txt"'));
    });
  });

  group('responses', () {
    test('fromJson builds typed objects', () async {
      final htpio = clientWith((_) => json({'id': 1, 'name': 'Ada'}));
      final res = await htpio.get<User>('/users/1', fromJson: User.fromJson);
      expect(res.data.name, 'Ada');
      expect(res.isSuccess, isTrue);
      expect(res.headers['content-type'], 'application/json');
    });

    test('decoder handles JSON lists', () async {
      final htpio = clientWith((_) => json([
            {'id': 1, 'name': 'A'},
            {'id': 2, 'name': 'B'},
          ]));
      final res = await htpio.get<List<User>>(
        '/users',
        decoder: (data) => [
          for (final item in data as List)
            User.fromJson(item as Map<String, dynamic>)
        ],
      );
      expect(res.data.map((u) => u.id), [1, 2]);
    });

    test('fromJson receives lists wrapped in {data: ...}', () async {
      final htpio = clientWith((_) => json([1, 2]));
      final res = await htpio.get<int>(
        '/n',
        fromJson: (json) => (json['data'] as List).length,
      );
      expect(res.data, 2);
    });

    test('plain, bytes and non-JSON responses', () async {
      final htpio = clientWith((_) => http.Response('héllo', 200,
          headers: {'content-type': 'text/plain; charset=utf-8'}));
      expect((await htpio.get('/t')).data, 'héllo');
      expect(
          (await htpio.get<String>('/t', responseType: ResponseType.plain))
              .data,
          'héllo');
      final bytes =
          await htpio.get<Uint8List>('/t', responseType: ResponseType.bytes);
      expect(utf8.decode(bytes.data), 'héllo');
    });

    test('empty body gives null data', () async {
      final htpio = clientWith((_) => http.Response('', 204));
      expect((await htpio.delete('/a')).data, isNull);
    });
  });

  group('errors', () {
    test('non-2xx throws badResponse with the error body', () async {
      final htpio = clientWith((_) => json({'message': 'not found'}, 404));
      await expectLater(
        htpio.get('/missing'),
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.badResponse)
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.response!.data['message'], 'body', 'not found')
            .having((e) => e.request!.uri.path, 'request', '/missing')),
      );
    });

    test('validateStatus can accept other codes', () async {
      final htpio = clientWith((_) => json({}, 404))
        ..validateStatus = (s) => s < 500;
      expect((await htpio.get('/x')).statusCode, 404);
    });

    test('wrong type without a converter is a parse error', () async {
      final htpio = clientWith((_) => json({'a': 1}));
      await expectLater(
        htpio.get<List<int>>('/x'),
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.parse)),
      );
    });

    test('network failures are connectionError', () async {
      final htpio = clientWith((_) => throw http.ClientException('refused'));
      await expectLater(
        htpio.get('/x'),
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.connectionError)),
      );
    });

    test('timeout aborts slow requests', () async {
      final htpio = clientWith((_) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return json({});
      });
      await expectLater(
        htpio.get('/slow', timeout: const Duration(milliseconds: 50)),
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.timeout)),
      );
    });

    test('CancelToken cancels in-flight and future requests', () async {
      final htpio = clientWith((_) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return json({});
      });
      final token = CancelToken();
      final future = htpio.get('/slow', cancelToken: token);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(sent, hasLength(1));
      token.cancel('bye');
      await expectLater(
        future,
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.cancel)),
      );
      await expectLater(
        htpio.get('/again', cancelToken: token),
        throwsA(isA<HtpioError>()
            .having((e) => e.type, 'type', HtpioErrorType.cancel)),
      );
      expect(sent, hasLength(1));
    });
  });

  group('cache and mock', () {
    test('cache: true serves repeated GETs from memory', () async {
      final htpio = clientWith((_) => json({'n': sent.length}))
        ..cache = HtpioCache();
      final a = await htpio.get('/p', cache: true);
      final b = await htpio.get('/p', cache: true);
      await htpio.get('/p');
      expect(a.data, b.data);
      expect(sent, hasLength(2));
    });

    test('cache entries expire', () async {
      final cache = HtpioCache();
      cache.set('k', HtpioResponse(data: 1, statusCode: 200),
          ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cache.get<int>('k'), isNull);
    });

    test('MockServer answers instead of the network', () async {
      final mock = MockServer()..enable();
      mock.registerMock('/users/1', {'id': 1, 'name': 'Mock'});
      mock.registerMock('/boom', {'error': 'x'}, statusCode: 500);
      mock.registerSequentialMocks('/job', [
        MockResponse(data: {'state': 'pending'}),
        MockResponse(data: {'state': 'done'}),
      ]);
      final htpio = clientWith((_) => json({}))..mockServer = mock;

      final user = await htpio.get<User>('/users/1', fromJson: User.fromJson);
      expect(user.data.name, 'Mock');
      expect((await htpio.get('/job')).data['state'], 'pending');
      expect((await htpio.get('/job')).data['state'], 'done');
      await expectLater(htpio.get('/boom'), throwsA(isA<HtpioError>()));
      expect(sent, isEmpty);

      final direct = await mock.getMockResponse(HtpioRequest<User>(
          url: 'https://api.test/users/1', fromJson: User.fromJson));
      expect(direct!.data.id, 1);
    });
  });

  group('legacy API', () {
    test('getRequest/postRequest still work', () async {
      final htpio =
          clientWith((_) => json({'id': 7, 'name': 'Old'}), baseUrl: '');
      // ignore: deprecated_member_use_from_same_package
      final get = await htpio.getRequest<User>(
        endpoint: 'https://api.test/u',
        fromJson: User.fromJson,
        authToken: 't',
      );
      // ignore: deprecated_member_use_from_same_package
      await htpio.postRequest<User>(
        endpoint: 'https://api.test/u',
        data: {'name': 'Old'},
        fromJson: User.fromJson,
      );
      expect(get.data.id, 7);
      expect(sent[0].headers['authorization'], 'Bearer t');
      expect(jsonDecode(sent[1].body), {'name': 'Old'});
    });

    test('HtpioError.from wraps messages', () {
      final error = HtpioError.from('Something went wrong');
      expect(error.message, 'Something went wrong');
      expect(error.toString(), contains('Something went wrong'));
    });
  });
}
