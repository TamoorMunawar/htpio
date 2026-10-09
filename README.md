# htpio

[![pub package](https://img.shields.io/pub/v/htpio.svg)](https://pub.dev/packages/htpio)
[![likes](https://img.shields.io/pub/likes/htpio)](https://pub.dev/packages/htpio/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

An easy HTTP client for Flutter. It's as simple as `package:http` for quick calls, and has the features a real app needs: base URL, typed JSON, interceptors, retry, token refresh, caching, an offline queue, uploads, downloads and mocking.

Works on **Android, iOS, Web, macOS, Windows and Linux**.

**Full documentation:** every class and function, with copy-paste examples: **[tamoormunawar.github.io/htpio](https://tamoormunawar.github.io/htpio/)**

```dart
import 'package:htpio/htpio.dart';

final htpio = HtpioClient(baseUrl: 'https://dummyjson.com');

void main() async {
  final res = await htpio.get('/products/1');
  print(res.data['title']);
}
```

---

## Every function at a glance

| You want to… | Use | Docs |
|---|---|---|
| Create a client | `HtpioClient(baseUrl: …, headers: …, timeout: …)` | [HtpioClient](https://tamoormunawar.github.io/htpio/#HtpioClient) |
| Read data | `get('/path', queryParameters: {…})` | [get](https://tamoormunawar.github.io/htpio/#get) |
| Create / replace / change / delete | `post` · `put` · `patch` · `delete` | [post](https://tamoormunawar.github.io/htpio/#post) · [put](https://tamoormunawar.github.io/htpio/#put) · [patch](https://tamoormunawar.github.io/htpio/#patch) · [delete](https://tamoormunawar.github.io/htpio/#delete) |
| Only headers / any other method | `head` · `request(path, method: …)` | [head](https://tamoormunawar.github.io/htpio/#head) · [request](https://tamoormunawar.github.io/htpio/#request) |
| Send a request object | `send(HtpioRequest(…))` | [send](https://tamoormunawar.github.io/htpio/#send) · [HtpioRequest](https://tamoormunawar.github.io/htpio/#HtpioRequest) |
| Get your own model back | `fromJson:` / `decoder:` | [fromJson vs decoder](https://tamoormunawar.github.io/htpio/#fromJson-decoder) |
| Get text or bytes | `responseType: ResponseType.plain / .bytes` | [ResponseType](https://tamoormunawar.github.io/htpio/#ResponseType) |
| Upload files | `FormData.fromMap({'f': HtpioMultipartFile.fromPath(…)})` | [FormData](https://tamoormunawar.github.io/htpio/#FormData) · [HtpioMultipartFile](https://tamoormunawar.github.io/htpio/#HtpioMultipartFile) |
| Handle errors | `on HtpioError catch (e)` → `e.type`, `e.statusCode`, `e.response` | [HtpioError](https://tamoormunawar.github.io/htpio/#HtpioError) · [HtpioErrorType](https://tamoormunawar.github.io/htpio/#HtpioErrorType) |
| Cancel a request | `CancelToken()` → `cancel()` | [CancelToken](https://tamoormunawar.github.io/htpio/#CancelToken) |
| Add a login token / refresh it | `AuthTokenInterceptor(token:, onRefreshToken:)` | [AuthTokenInterceptor](https://tamoormunawar.github.io/htpio/#AuthTokenInterceptor) |
| Retry failures | `RetryInterceptor(maxRetries: 3)` | [RetryInterceptor](https://tamoormunawar.github.io/htpio/#RetryInterceptor) |
| Log traffic | `HtpioLogInterceptor()` | [HtpioLogInterceptor](https://tamoormunawar.github.io/htpio/#HtpioLogInterceptor) |
| Write your own hook | `extends HtpioInterceptor` / `HtpioMiddleware` | [HtpioInterceptor](https://tamoormunawar.github.io/htpio/#HtpioInterceptor) · [HtpioMiddleware](https://tamoormunawar.github.io/htpio/#HtpioMiddleware) |
| Cache GET responses | `HtpioClient(cache: HtpioCache())` + `cache: true` | [HtpioCache](https://tamoormunawar.github.io/htpio/#HtpioCache) |
| Work offline | `use(OfflineMode())` | [OfflineMode](https://tamoormunawar.github.io/htpio/#OfflineMode) · [ConnectivityHelper](https://tamoormunawar.github.io/htpio/#ConnectivityHelper) |
| Download big files | `HtpioDownloadManager().downloadFile(…)` | [HtpioDownloadManager](https://tamoormunawar.github.io/htpio/#HtpioDownloadManager) |
| Fake the API | `MockServer()..registerMock(…)` | [MockServer](https://tamoormunawar.github.io/htpio/#MockServer) · [MockResponse](https://tamoormunawar.github.io/htpio/#MockResponse) |
| See requests on screen | `DebugConsole().overlay()` | [DebugConsole](https://tamoormunawar.github.io/htpio/#DebugConsole) |

## Contents

- [Install](#install)
- [Making requests](#making-requests)
- [Typed responses](#typed-responses)
- [Sending data](#sending-data)
- [Handling errors](#handling-errors)
- [Client configuration](#client-configuration)
- [Interceptors](#interceptors)
  - [Auth token & refresh](#auth-token--refresh)
  - [Retry](#retry)
  - [Logging](#logging)
  - [Write your own](#write-your-own)
- [Middleware](#middleware)
- [Cancel & timeout](#cancel--timeout)
- [Caching](#caching)
- [Offline mode](#offline-mode)
- [Downloads](#downloads)
- [Mocking & testing](#mocking--testing)
- [Debug overlay](#debug-overlay)
- [Upgrading from 1.1.x](#upgrading-from-11x)

---

## Install

```bash
flutter pub add htpio
```

```dart
import 'package:htpio/htpio.dart';
```

## Making requests

Create **one** client and reuse it everywhere. It keeps connections open, which makes requests faster.

```dart
final htpio = HtpioClient(baseUrl: 'https://api.example.com');

await htpio.get('/users');
await htpio.get('/users', queryParameters: {'page': 2, 'limit': 20});
await htpio.post('/users', data: {'name': 'Ada'});
await htpio.put('/users/1', data: {'name': 'Ada Lovelace'});
await htpio.patch('/users/1', data: {'age': 36});
await htpio.delete('/users/1');
await htpio.head('/users');

// Any other method
await htpio.request('/users', method: 'OPTIONS');
```

Every call returns an `HtpioResponse`:

```dart
final res = await htpio.get('/users/1');

res.data;        // decoded JSON (Map / List), or a String if the body isn't JSON
res.statusCode;  // 200
res.headers;     // {'content-type': 'application/json', ...}
res.isSuccess;   // true for 2xx
```

Paths are joined to `baseUrl`. A full URL (`https://...`) is used as is.

## Typed responses

Pass `fromJson` to get your own model back:

```dart
class User {
  User({required this.id, required this.name});
  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'], name: json['name']);
  final int id;
  final String name;
}

final res = await htpio.get<User>('/users/1', fromJson: User.fromJson);
print(res.data.name); // res.data is a User
```

For lists, or any other shape, use `decoder`:

```dart
final res = await htpio.get<List<User>>(
  '/users',
  decoder: (data) => (data as List).map((e) => User.fromJson(e)).toList(),
);
```

Need raw text or bytes (images, PDFs)?

```dart
final html  = await htpio.get<String>('/page', responseType: ResponseType.plain);
final image = await htpio.get<Uint8List>('/logo.png', responseType: ResponseType.bytes);
```

## Sending data

`data` is encoded for you based on its type:

| You pass | Sent as |
|---|---|
| `Map`, `List`, or an object with `toJson()` | JSON (`application/json`) |
| `FormData` | `multipart/form-data` (file upload) |
| `String` | text, as is |
| `List<int>` / `Uint8List` | raw bytes |
| `Map` + header `content-type: application/x-www-form-urlencoded` | form fields |

**JSON**

```dart
await htpio.post('/login', data: {'email': 'a@b.com', 'password': 'secret'});
```

**File upload**

```dart
final form = FormData.fromMap({
  'title': 'My holiday',
  'photo': HtpioMultipartFile.fromPath(file.path, contentType: 'image/jpeg'),
  'extras': [
    HtpioMultipartFile.fromPath(a.path),
    HtpioMultipartFile.fromPath(b.path),
  ],
});

await htpio.post('/upload', data: form);
```

On the web, use `HtpioMultipartFile.fromBytes(bytes, filename: 'photo.jpg')`. There are no file paths in a browser.

**Form URL-encoded**

```dart
await htpio.post(
  '/token',
  data: {'grant_type': 'password', 'username': 'ada'},
  headers: {'content-type': 'application/x-www-form-urlencoded'},
);
```

## Handling errors

Every failure throws one type, `HtpioError`. Check `type` to find out what happened:

```dart
try {
  final res = await htpio.get('/users/1');
} on HtpioError catch (e) {
  switch (e.type) {
    case HtpioErrorType.badResponse:      // server replied 4xx / 5xx
      print(e.statusCode);                // 404
      print(e.response?.data);            // error body from the server
    case HtpioErrorType.timeout:          // too slow
    case HtpioErrorType.connectionError:  // no internet, DNS, TLS...
    case HtpioErrorType.cancel:           // you cancelled it
    case HtpioErrorType.offline:          // OfflineMode queued it
    case HtpioErrorType.parse:            // fromJson / decoder threw
    case HtpioErrorType.unknown:
      print(e.message);
  }
}
```

By default only 2xx counts as success. To change that:

```dart
final htpio = HtpioClient(validateStatus: (status) => status < 500);
```

## Client configuration

```dart
final htpio = HtpioClient(
  baseUrl: 'https://api.example.com/v1',
  headers: {'accept-language': 'en'},     // sent with every request
  queryParameters: {'app': 'mobile'},     // added to every request
  timeout: Duration(seconds: 20),         // default per-request limit
  validateStatus: (s) => s >= 200 && s < 300,
  interceptors: [AuthTokenInterceptor(token: token), RetryInterceptor()],
  cache: HtpioCache(),
);

// Change settings later
htpio.baseUrl = 'https://staging.example.com/v1';
htpio.headers['x-app-version'] = '2.0.0';

// Per-request values override client values
await htpio.get('/me', headers: {'accept-language': 'de'}, timeout: Duration(seconds: 5));

// Free resources when you are done (e.g. in a test's tearDown)
htpio.close();
```

## Interceptors

Interceptors can change requests and responses, or recover from errors. Requests pass through interceptors in the order you added them. Responses pass through in reverse order.

```dart
htpio.addInterceptor(AuthTokenInterceptor(token: token));
htpio.addInterceptor(RetryInterceptor());
htpio.addInterceptor(HtpioLogInterceptor());
```

### Auth token & refresh

```dart
final auth = AuthTokenInterceptor(
  token: savedToken,                       // or: tokenProvider: () => storage.read('token')
  onRefreshToken: () async {               // optional: called on 401
    final res = await HtpioClient().post(
      'https://api.example.com/refresh',
      data: {'refresh_token': refreshToken},
    );
    return res.data['access_token'];       // return null to give up
  },
);
htpio.addInterceptor(auth);

auth.setToken(newToken);  // after login
auth.clearToken();        // after logout
```

Every request gets `Authorization: Bearer <token>`. When the server answers `401`, htpio calls `onRefreshToken` once and retries the request with the new token. If many requests fail together, they share a single refresh. You can change the header with `headerName: 'x-api-key', tokenPrefix: ''`.

### Retry

```dart
htpio.addInterceptor(RetryInterceptor(
  maxRetries: 3,
  baseDelay: Duration(seconds: 1),  // 1s, 2s, 4s (exponential backoff)
));
```

It retries timeouts, connection errors and status codes `408, 429, 500, 502, 503, 504`. By default it only retries safe methods (`GET, HEAD, PUT, DELETE, OPTIONS`), so a payment `POST` is never sent twice. You can change this with `retryMethods`, `retryableStatusCodes`, or your own `retryIf: (error) => ...`.

### Logging

```dart
htpio.addInterceptor(HtpioLogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

```
--> POST https://api.example.com/users
{name: Ada}
<-- 201 POST https://api.example.com/users
{id: 7, name: Ada}
```

`Authorization` and cookie headers always print as `***`.

### Write your own

Override only what you need:

```dart
class ApiKeyInterceptor extends HtpioInterceptor {
  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    request.headers['x-api-key'] = 'my-key';
    return request;
  }

  @override
  Future<HtpioResponse> onResponse(HtpioResponse response) async {
    // e.g. unwrap {"data": ...} envelopes
    return response;
  }

  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async {
    if (error.statusCode == 503) {
      // Return a response to recover...
      return HtpioResponse(data: {'maintenance': true}, statusCode: 200, request: request);
    }
    throw error; // ...or throw to pass the error on
  }
}
```

Inside an interceptor, `client` is the `HtpioClient` it was added to. Use `client!.send(request)` to send a request again.

## Middleware

Middleware observes requests without changing them. Use it for analytics, timing, or crash reporting.

```dart
class AnalyticsMiddleware extends HtpioMiddleware {
  @override
  Future<void> beforeRequest(HtpioRequest request) async =>
      analytics.log('api_call', {'path': request.uri.path});

  @override
  Future<void> onError(HtpioError error) async =>
      crashlytics.recordError(error, error.stackTrace);
}

htpio.use(AnalyticsMiddleware());
```

## Cancel & timeout

```dart
final token = CancelToken();

htpio.get('/search', queryParameters: {'q': text}, cancelToken: token);

token.cancel(); // the request stops and throws HtpioError(type: cancel)
```

A typical search-as-you-type:

```dart
CancelToken? _last;

Future<void> onChanged(String text) async {
  _last?.cancel();
  _last = CancelToken();
  final res = await htpio.get('/search', queryParameters: {'q': text}, cancelToken: _last);
}
```

Timeouts cover the whole request, from connecting to the last byte:

```dart
await htpio.get('/report', timeout: Duration(seconds: 60));
```

## Caching

```dart
final htpio = HtpioClient(
  baseUrl: 'https://api.example.com',
  cache: HtpioCache(defaultTtl: Duration(minutes: 5)),
);

await htpio.get('/categories', cache: true); // network
await htpio.get('/categories', cache: true); // from memory for 5 minutes

htpio.cache!.clear();
```

Only successful `GET` requests made with `cache: true` are cached.

## Offline mode

```dart
final offline = OfflineMode();
htpio.use(offline);

offline.connectivityStream.listen((online) {
  showBanner(online ? 'Back online' : 'You are offline');
});
offline.replayResults.listen((result) => print('replayed: $result'));
```

While the device is offline, requests fail straight away with `HtpioErrorType.offline`, so you don't wait for a timeout. `POST`, `PUT`, `PATCH` and `DELETE` requests are queued, then sent again automatically when the connection comes back. Change this with `queueMethods`.

For a one-off check, use `ConnectivityHelper.isOnline()`.

## Downloads

```dart
final downloads = HtpioDownloadManager();

final file = await downloads.downloadFile(
  url: 'https://example.com/video.mp4',
  savePath: '${dir.path}/video.mp4',
  onProgress: (p) => setState(() => progress = p), // 0.0 – 1.0
);

downloads.pauseDownload(url);
downloads.resumeDownload(url);
downloads.cancelDownload(url); // throws HtpioError(type: cancel), removes the partial file
```

`downloads.progressStream` reports progress for every running download. Downloading to a file needs a file system. On the web, use `htpio.get(url, responseType: ResponseType.bytes)` instead.

## Mocking & testing

**Mock server.** Build UI before the backend exists, or run demos offline:

```dart
final mock = MockServer()..enable();
mock.registerMock('/users/1', {'id': 1, 'name': 'Ada'});
mock.registerMock('/users/2', {'error': 'not found'}, statusCode: 404);
mock.registerMock('/slow', {'ok': true}, delay: Duration(seconds: 2));
mock.registerSequentialMocks('/job', [
  MockResponse(data: {'state': 'pending'}),
  MockResponse(data: {'state': 'done'}),
]);

final htpio = HtpioClient(baseUrl: 'https://api.example.com', mockServer: mock);
```

**Unit tests.** Inject `MockClient` from `package:http/testing.dart`:

```dart
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final htpio = HtpioClient(
  baseUrl: 'https://api.test',
  httpClient: MockClient((request) async {
    expect(request.url.path, '/users/1');
    return http.Response('{"id": 1, "name": "Ada"}', 200);
  }),
);
```

## Debug overlay

Show the latest requests on screen while you develop:

```dart
Stack(
  children: [
    const MyHomePage(),
    if (kDebugMode) DebugConsole().overlay(lines: 5),
  ],
)
```

It shows method, URL and errors, but never headers or bodies, so tokens don't appear on screen.

## Upgrading from 1.1.x

Version 1.2 is backwards compatible. The old methods still work but are deprecated:

| 1.1.x | 1.2+ |
|---|---|
| `getRequest(endpoint: url, fromJson: f)` | `get(url, fromJson: f)` |
| `postRequest(endpoint: url, data: d, fromJson: f)` | `post(url, data: d, fromJson: f)` |
| `putRequest` / `deleteRequest` | `put` / `delete` |
| `authToken: t` | `AuthTokenInterceptor(token: t)` |
| `postSingleFileWithDataRequest` / `postFilesWithDataRequest` | `post(url, data: FormData.fromMap({...}))` |
| `request.execute()` | `client.send(request)` |

Also new in 1.2:

- Errors for 4xx and 5xx responses are now thrown. Before, they returned silently.
- `RetryInterceptor` now actually retries.
- File uploads actually send the files.

See the [CHANGELOG](CHANGELOG.md) for details.

## Contributing

Found a bug or want a feature? Open an [issue](https://github.com/TamoorMunawar/htpio/issues). Pull requests are welcome; please run `flutter analyze` and `flutter test` first.

## License

MIT. See [LICENSE](LICENSE).
