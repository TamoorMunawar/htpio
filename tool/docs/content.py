# Content of the htpio documentation site (docs/index.html).
#
# Edit this file, then run:  python3 tool/docs/build.py
#
# Structure: SECTIONS is a list of groups. Each group has items; each item is
# one class, function or topic with a signature, text, optional parameter
# table, example code and example output.
#
# Code examples are compile-checked by build.py --check (see tool/docs/README.md).
# Examples marked top=True are top-level declarations (classes); the others run
# inside an async function where `htpio`, `User`, `token`, `file`, `dir`,
# `url`, `refreshToken` and `text` already exist.

VERSION = '1.2.0'

SECTIONS = [
  # ---------------------------------------------------------------- start
  {
    'id': 'start', 'title': 'Getting started',
    'items': [
      {
        'id': 'install', 'name': 'Install',
        'text': 'Add htpio to your Flutter app, then import it. One import gives you everything.',
        'shell': 'flutter pub add htpio',
        'code': "import 'package:htpio/htpio.dart';",
        'top': True,
      },
      {
        'id': 'first-request', 'name': 'Your first request',
        'text': 'Create one client for your whole app and reuse it. It keeps connections open, which makes later requests faster.',
        'code': """final htpio = HtpioClient(baseUrl: 'https://api.example.com');

final res = await htpio.get('/users/1');
print(res.statusCode);     // 200
print(res.data);           // {id: 1, name: Ada Lovelace}
print(res.data['name']);   // Ada Lovelace""",
        'output': """200
{id: 1, name: Ada Lovelace}
Ada Lovelace""",
      },
      {
        'id': 'typed-models', 'name': 'Typed models',
        'text': 'Give htpio your model’s <code>fromJson</code> and <code>res.data</code> becomes that model.',
        'code': """class User {
  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as int, name: json['name'] as String);

  final int id;
  final String name;
}""",
        'top': True,
        'code2': """final res = await htpio.get<User>('/users/1', fromJson: User.fromJson);
print(res.data.name); // Ada Lovelace""",
      },
      {
        'id': 'api-layer', 'name': 'Recommended app structure',
        'text': 'Keep one client in a single file and put each endpoint in an API class. Widgets call the API class and never build URLs themselves.',
        'code': """// lib/api/client.dart
final api = HtpioClient(
  baseUrl: 'https://api.example.com/v1',
  timeout: const Duration(seconds: 20),
  interceptors: [
    AuthTokenInterceptor(tokenProvider: () => secureStorage.read('token')),
    RetryInterceptor(),
    if (kDebugMode) HtpioLogInterceptor(responseBody: true),
  ],
);

// lib/api/user_api.dart
class UserApi {
  Future<User> me() async =>
      (await api.get<User>('/me', fromJson: User.fromJson)).data;

  Future<List<User>> search(String q, {CancelToken? cancelToken}) async {
    final res = await api.get<List<User>>(
      '/users',
      queryParameters: {'q': q},
      cancelToken: cancelToken,
      decoder: (data) => [for (final e in data as List) User.fromJson(e)],
    );
    return res.data;
  }

  Future<void> rename(int id, String name) =>
      api.patch('/users/$id', data: {'name': name});
}""",
        'top': True,
      },
    ],
  },

  # ---------------------------------------------------------------- client
  {
    'id': 'client', 'title': 'HtpioClient',
    'items': [
      {
        'id': 'HtpioClient', 'name': 'HtpioClient()', 'kind': 'constructor',
        'sig': """HtpioClient({
  String baseUrl = '',
  Map<String, String>? headers,
  Map<String, dynamic>? queryParameters,
  Duration? timeout,
  bool Function(int statusCode)? validateStatus,
  http.Client? httpClient,
  HtpioCache? cache,
  MockServer? mockServer,
  List<HtpioInterceptor>? interceptors,
})""",
        'text': 'Creates the client. Every argument is optional.',
        'params': [
          ('baseUrl', 'String', "Joined to relative paths. <code>'/users'</code> becomes <code>baseUrl + '/users'</code>. Full URLs are used as is."),
          ('headers', 'Map<String, String>', 'Sent with every request. Per-request headers win.'),
          ('queryParameters', 'Map<String, dynamic>', 'Added to every request URL.'),
          ('timeout', 'Duration?', 'Default time limit for a whole request. <code>null</code> means no limit.'),
          ('validateStatus', 'bool Function(int)', 'Which status codes count as success. Default: 200–299. Others throw <code>HtpioError</code>.'),
          ('httpClient', 'http.Client', 'Custom transport. Pass a <code>MockClient</code> in unit tests.'),
          ('cache', 'HtpioCache?', 'Used by requests made with <code>cache: true</code>.'),
          ('mockServer', 'MockServer?', 'When enabled, answers matching requests without the network.'),
          ('interceptors', 'List<HtpioInterceptor>', 'Same as calling <code>addInterceptor</code> for each.'),
        ],
        'code': """final htpio = HtpioClient(
  baseUrl: 'https://api.example.com/v1',
  headers: {'accept-language': 'en'},
  queryParameters: {'app': 'mobile'},
  timeout: const Duration(seconds: 20),
  interceptors: [RetryInterceptor()],
);

// All of these can be changed later:
htpio.baseUrl = 'https://staging.example.com/v1';
htpio.headers['x-app-version'] = '2.0.0';
htpio.timeout = const Duration(seconds: 30);""",
      },
      {
        'id': 'get', 'name': 'get()', 'kind': 'method', 'verb': 'GET',
        'sig': """Future<HtpioResponse<T>> get<T>(
  String path, {
  Map<String, dynamic>? queryParameters,
  Map<String, String>? headers,
  T Function(Map<String, dynamic>)? fromJson,
  T Function(dynamic data)? decoder,
  ResponseType responseType = ResponseType.json,
  CancelToken? cancelToken,
  Duration? timeout,
  bool cache = false,
  Map<String, dynamic>? extra,
})""",
        'text': 'Fetches data. The response body is decoded for you.',
        'params': [
          ('path', 'String', 'Path joined to <code>baseUrl</code>, or a full URL.'),
          ('queryParameters', 'Map<String, dynamic>', '<code>{\'page\': 2}</code> → <code>?page=2</code>. A list repeats the key; <code>null</code> values are skipped.'),
          ('headers', 'Map<String, String>', 'Extra headers for this request only.'),
          ('fromJson', 'T Function(Map)', 'Turns a JSON object into your model.'),
          ('decoder', 'T Function(dynamic)', 'Turns any decoded body (list, string…) into <code>T</code>. Use it for lists.'),
          ('responseType', 'ResponseType', '<code>json</code> (default), <code>plain</code> for a String, <code>bytes</code> for a Uint8List.'),
          ('cancelToken', 'CancelToken?', 'Lets you cancel the request.'),
          ('timeout', 'Duration?', 'Overrides the client timeout.'),
          ('cache', 'bool', 'Serve from the client’s <code>HtpioCache</code> when possible.'),
          ('extra', 'Map<String, dynamic>', 'Values for your own interceptors to read.'),
        ],
        'code': """// JSON map
final res = await htpio.get('/users/1');
print(res.data['name']);

// Query parameters: /products?category=phones&page=2&tag=new&tag=sale
await htpio.get('/products', queryParameters: {
  'category': 'phones',
  'page': 2,
  'tag': ['new', 'sale'],
});

// Typed model
final user = await htpio.get<User>('/users/1', fromJson: User.fromJson);

// Typed list
final users = await htpio.get<List<User>>(
  '/users',
  decoder: (data) => [for (final e in data as List) User.fromJson(e)],
);""",
      },
      {
        'id': 'post', 'name': 'post()', 'kind': 'method', 'verb': 'POST',
        'sig': """Future<HtpioResponse<T>> post<T>(
  String path, {
  Object? data,
  Map<String, dynamic>? queryParameters,
  Map<String, String>? headers,
  T Function(Map<String, dynamic>)? fromJson,
  T Function(dynamic data)? decoder,
  ResponseType responseType = ResponseType.json,
  CancelToken? cancelToken,
  Duration? timeout,
  Map<String, dynamic>? extra,
})""",
        'text': 'Creates something. <code>data</code> is encoded from its type: a Map becomes JSON, <code>FormData</code> becomes a file upload. See <a href="#encoding">Sending data</a>. The other parameters work as in <a href="#get">get()</a>.',
        'code': """final res = await htpio.post(
  '/users',
  data: {'name': 'Grace', 'email': 'grace@example.com'},
);
print('${res.statusCode} ${res.data}');""",
        'output': '201 {id: 2, name: Grace, email: grace@example.com}',
      },
      {
        'id': 'put', 'name': 'put()', 'kind': 'method', 'verb': 'PUT',
        'sig': 'Future<HtpioResponse<T>> put<T>(String path, {Object? data, ...})',
        'text': 'Replaces a resource. Same parameters as <a href="#post">post()</a>.',
        'code': "await htpio.put('/users/2', data: {'name': 'Grace Hopper', 'email': 'g@example.com'});",
      },
      {
        'id': 'patch', 'name': 'patch()', 'kind': 'method', 'verb': 'PATCH',
        'sig': 'Future<HtpioResponse<T>> patch<T>(String path, {Object? data, ...})',
        'text': 'Changes part of a resource. Same parameters as <a href="#post">post()</a>.',
        'code': "await htpio.patch('/users/2', data: {'name': 'Rear Admiral Hopper'});",
      },
      {
        'id': 'delete', 'name': 'delete()', 'kind': 'method', 'verb': 'DELETE',
        'sig': 'Future<HtpioResponse<T>> delete<T>(String path, {Object? data, ...})',
        'text': 'Deletes a resource. A body is optional. Same parameters as <a href="#post">post()</a>.',
        'code': """final res = await htpio.delete('/users/2');
print(res.statusCode); // 204
print(res.data);       // null (empty body)""",
      },
      {
        'id': 'head', 'name': 'head()', 'kind': 'method', 'verb': 'HEAD',
        'sig': """Future<HtpioResponse<dynamic>> head(
  String path, {
  Map<String, dynamic>? queryParameters,
  Map<String, String>? headers,
  CancelToken? cancelToken,
  Duration? timeout,
})""",
        'text': 'Fetches only the headers, for example to check a file’s size before downloading it.',
        'code': """final res = await htpio.head('/files/video.mp4');
print(res.headers['content-length']);""",
      },
      {
        'id': 'request', 'name': 'request()', 'kind': 'method', 'verb': 'ANY',
        'sig': """Future<HtpioResponse<T>> request<T>(
  String path, {
  String method = 'GET',
  Object? data,
  ...same as get()
})""",
        'text': 'Sends a request with any HTTP method. All the verb methods above call this one.',
        'code': "final res = await htpio.request('/users', method: 'OPTIONS');",
      },
      {
        'id': 'send', 'name': 'send()', 'kind': 'method',
        'sig': 'Future<HtpioResponse<T>> send<T>(HtpioRequest<T> request)',
        'text': 'Sends a request object you built yourself. Interceptors use it to send a request again.',
        'code': """final req = HtpioRequest<User>(
  url: '/users/1',
  fromJson: User.fromJson,
  headers: {'x-trace': 'abc'},
);
final res = await htpio.send(req);""",
      },
      {
        'id': 'addInterceptor', 'name': 'addInterceptor() / removeInterceptor()', 'kind': 'method',
        'sig': """void addInterceptor(HtpioInterceptor interceptor)
bool removeInterceptor(HtpioInterceptor interceptor)
List<HtpioInterceptor> get interceptors""",
        'text': 'Adds or removes an <a href="#HtpioInterceptor">interceptor</a>. Requests pass through interceptors in the order they were added, and responses pass through in reverse order.',
        'code': """final logger = HtpioLogInterceptor();
htpio.addInterceptor(logger);
print(htpio.interceptors.length);
htpio.removeInterceptor(logger);""",
      },
      {
        'id': 'use', 'name': 'use()', 'kind': 'method',
        'sig': 'void use(HtpioMiddleware middleware)',
        'text': 'Adds a <a href="#HtpioMiddleware">middleware</a>, for example <a href="#OfflineMode">OfflineMode</a>.',
        'code': 'htpio.use(OfflineMode());',
      },
      {
        'id': 'close', 'name': 'close()', 'kind': 'method',
        'sig': 'void close()',
        'text': 'Closes open connections. Call it when the client is no longer needed, for example in a test’s <code>tearDown</code>. A closed client can’t send requests.',
        'code': 'htpio.close();',
      },
    ],
  },

  # ---------------------------------------------------------------- data
  {
    'id': 'data', 'title': 'Sending data',
    'items': [
      {
        'id': 'encoding', 'name': 'How data is encoded', 'kind': 'guide',
        'text': 'Pass any of these as <code>data</code>. htpio picks the encoding and sets the <code>Content-Type</code> header.',
        'table': [
          ('You pass', 'Sent as'),
          ('<code>Map</code>, <code>List</code>, object with <code>toJson()</code>', 'JSON · <code>application/json</code>'),
          ('<code>FormData</code>', 'File upload · <code>multipart/form-data</code>'),
          ('<code>String</code>', 'Text, unchanged · <code>text/plain</code> unless you set a type'),
          ('<code>List&lt;int&gt;</code> / <code>Uint8List</code>', 'Raw bytes · <code>application/octet-stream</code>'),
          ('<code>Map</code> + header <code>content-type: application/x-www-form-urlencoded</code>', 'Form fields · <code>a=1&amp;b=2</code>'),
        ],
        'code': """// JSON
await htpio.post('/login', data: {'email': 'a@b.com', 'password': 'secret'});

// Form URL-encoded (OAuth token endpoints often need this)
await htpio.post(
  '/oauth/token',
  data: {'grant_type': 'password', 'username': 'ada', 'password': 'pw'},
  headers: {'content-type': 'application/x-www-form-urlencoded'},
);

// Plain text and raw bytes
await htpio.post('/notes', data: 'Remember the milk');
await htpio.put('/avatar', data: [0x89, 0x50, 0x4E, 0x47]);""",
      },
      {
        'id': 'FormData', 'name': 'FormData', 'kind': 'class',
        'sig': """FormData()
factory FormData.fromMap(Map<String, dynamic> map)
final Map<String, String> fields
final List<MapEntry<String, HtpioMultipartFile>> files""",
        'text': 'A file-upload body (<code>multipart/form-data</code>). In <code>fromMap</code>, <code>HtpioMultipartFile</code> values (or lists of them) become files and every other value is sent as text. You can send the same form again; files are re-read each time, so retries work.',
        'code': """final form = FormData.fromMap({
  'title': 'My holiday',
  'public': true,
  'photo': HtpioMultipartFile.fromPath(file.path, contentType: 'image/jpeg'),
  'extras': [
    HtpioMultipartFile.fromPath('${dir.path}/a.jpg'),
    HtpioMultipartFile.fromPath('${dir.path}/b.jpg'),
  ],
});
await htpio.post('/albums', data: form);

// Or build it step by step
final form2 = FormData();
form2.fields['title'] = 'Report';
form2.files.add(MapEntry('pdf', HtpioMultipartFile.fromPath('${dir.path}/r.pdf')));
await htpio.post('/reports', data: form2);""",
      },
      {
        'id': 'HtpioMultipartFile', 'name': 'HtpioMultipartFile', 'kind': 'class',
        'sig': """HtpioMultipartFile.fromPath(String path, {String? filename, String? contentType})
HtpioMultipartFile.fromBytes(List<int> bytes, {String? filename, String? contentType})
HtpioMultipartFile.fromString(String value, {String? filename, String? contentType})""",
        'text': 'One file inside a <code>FormData</code>. <code>fromPath</code> reads from disk and works on mobile and desktop. On the web there are no file paths, so use <code>fromBytes</code> (for example with bytes from a file picker).',
        'params': [
          ('filename', 'String?', 'Name the server sees. Defaults to the file’s name for <code>fromPath</code>.'),
          ('contentType', 'String?', 'MIME type, e.g. <code>image/png</code>.'),
        ],
        'code': """final a = HtpioMultipartFile.fromPath(file.path, contentType: 'image/jpeg');
final b = HtpioMultipartFile.fromBytes(pickedBytes, filename: 'photo.png');
final c = HtpioMultipartFile.fromString('name,age\\nAda,36', filename: 'people.csv');""",
      },
    ],
  },

  # ---------------------------------------------------------------- responses
  {
    'id': 'responses', 'title': 'Responses',
    'items': [
      {
        'id': 'HtpioResponse', 'name': 'HtpioResponse<T>', 'kind': 'class',
        'sig': """final T data
final int statusCode
final Map<String, String> headers
final HtpioRequest? request
final String? reasonPhrase
bool get isSuccess""",
        'text': 'What every request returns.',
        'params': [
          ('data', 'T', 'The body: decoded JSON, a String, bytes, or your model.'),
          ('statusCode', 'int', 'e.g. <code>200</code>, <code>201</code>, <code>204</code>.'),
          ('headers', 'Map<String, String>', 'Response headers with lower-case keys.'),
          ('request', 'HtpioRequest?', 'The request that produced it.'),
          ('reasonPhrase', 'String?', 'Status text, e.g. <code>OK</code>.'),
          ('isSuccess', 'bool', '<code>true</code> for 200–299.'),
        ],
        'code': """final res = await htpio.get('/users/1');
print(res.statusCode);              // 200
print(res.headers['content-type']); // application/json
print(res.isSuccess);               // true""",
      },
      {
        'id': 'ResponseType', 'name': 'ResponseType', 'kind': 'enum',
        'sig': 'enum ResponseType { json, plain, bytes }',
        'text': 'How the body is decoded. With <code>json</code> (the default), a body that isn’t valid JSON is returned as a String instead of failing. An empty body gives <code>null</code>.',
        'code': """final html  = await htpio.get<String>('/page', responseType: ResponseType.plain);
final image = await htpio.get<Uint8List>('/logo.png', responseType: ResponseType.bytes);
// Flutter: Image.memory(image.data)""",
      },
      {
        'id': 'fromJson-decoder', 'name': 'fromJson vs decoder', 'kind': 'guide',
        'text': 'Both turn the response body into your own type. Pick by the shape of the JSON.',
        'table': [
          ('JSON shape', 'Use'),
          ('<code>{ "id": 1, … }</code>', '<code>fromJson: User.fromJson</code>'),
          ('<code>[ {…}, {…} ]</code>', '<code>decoder: (d) => [for (final e in d as List) User.fromJson(e)]</code>'),
          ('<code>{ "data": [ … ], "total": 9 }</code>', '<code>decoder: (d) => Page.fromJson(d)</code>'),
          ('anything, no conversion', 'leave both out; <code>res.data</code> is a Map, List or String'),
        ],
        'text2': 'If <code>fromJson</code> receives a JSON list, the list is passed as <code>{\'data\': list}</code>. If your <code>fromJson</code> or <code>decoder</code> throws, the request fails with <code>HtpioErrorType.parse</code>.',
      },
    ],
  },

  # ---------------------------------------------------------------- errors
  {
    'id': 'errors', 'title': 'Errors',
    'items': [
      {
        'id': 'HtpioError', 'name': 'HtpioError', 'kind': 'class',
        'sig': """final String message
final HtpioErrorType type
final int? statusCode
final HtpioResponse? response
final HtpioRequest? request
final dynamic originalError
final StackTrace? stackTrace""",
        'text': 'The only exception htpio throws, so you need just one <code>catch</code>. For a 4xx or 5xx reply, <code>response.data</code> holds the error body the server sent.',
        'code': """try {
  await htpio.get('/missing');
} on HtpioError catch (e) {
  print(e);
  print('type=${e.type.name} status=${e.statusCode} body=${e.response?.data}');
}""",
        'output': """HtpioError(badResponse) [404]: Request failed with status code 404
type=badResponse status=404 body={message: User not found}""",
      },
      {
        'id': 'HtpioErrorType', 'name': 'HtpioErrorType', 'kind': 'enum',
        'sig': 'enum HtpioErrorType { timeout, badResponse, cancel, connectionError, offline, parse, unknown }',
        'table': [
          ('Value', 'Happens when'),
          ('<code>badResponse</code>', 'The server replied with a status outside <code>validateStatus</code> (4xx/5xx by default).'),
          ('<code>timeout</code>', 'The request took longer than its <code>timeout</code>.'),
          ('<code>connectionError</code>', 'No internet, DNS failure, refused connection, TLS error.'),
          ('<code>cancel</code>', 'A <code>CancelToken</code> was cancelled.'),
          ('<code>offline</code>', '<code>OfflineMode</code> knows the device is offline.'),
          ('<code>parse</code>', '<code>fromJson</code> / <code>decoder</code> threw, or the data isn’t a <code>T</code>.'),
          ('<code>unknown</code>', 'Anything else. See <code>originalError</code>.'),
        ],
        'text': 'Use it to show the right message to the user.',
        'code': """String messageFor(HtpioError e) => switch (e.type) {
      HtpioErrorType.timeout => 'The server is slow. Please try again.',
      HtpioErrorType.connectionError ||
      HtpioErrorType.offline => 'No internet connection.',
      HtpioErrorType.badResponse when e.statusCode == 401 => 'Please log in again.',
      HtpioErrorType.badResponse => 'Server error (${e.statusCode}).',
      _ => 'Something went wrong.',
    };""",
        'top': True,
      },
      {
        'id': 'validateStatus', 'name': 'validateStatus', 'kind': 'guide',
        'text': 'Decides which status codes count as success. Set it on the client for all requests, or on a single <code>HtpioRequest</code>.',
        'code': """// Treat 4xx as normal responses and only throw on 5xx
final lenient = HtpioClient(validateStatus: (status) => status < 500);
final res = await lenient.get('https://api.example.com/maybe-missing');
if (res.statusCode == 404) print('not found');""",
      },
    ],
  },

  # ---------------------------------------------------------------- cancel
  {
    'id': 'cancel', 'title': 'Cancel & timeout',
    'items': [
      {
        'id': 'CancelToken', 'name': 'CancelToken', 'kind': 'class',
        'sig': """CancelToken()
void cancel([Object? reason])
bool get isCancelled
Object? get reason
Future<void> get whenCancelled""",
        'text': 'Stops a request that is already running. One token can cancel many requests. A cancelled request throws <code>HtpioError</code> with type <code>cancel</code>.',
        'code': """final cancelToken = CancelToken();
final future = htpio.get('/slow', cancelToken: cancelToken);
cancelToken.cancel('user left the page');

try {
  await future;
} on HtpioError catch (e) {
  print(e);
}""",
        'output': 'HtpioError(cancel): Request was cancelled',
      },
      {
        'id': 'search-as-you-type', 'name': 'Recipe: search as you type', 'kind': 'guide',
        'text': 'Cancel the previous search each time the user types, so an old, slow reply can never overwrite the new one.',
        'code': """class SearchController {
  CancelToken? _last;

  Future<List<dynamic>?> onChanged(String text) async {
    _last?.cancel();
    final cancelToken = _last = CancelToken();
    try {
      final res = await htpio.get(
        '/search',
        queryParameters: {'q': text},
        cancelToken: cancelToken,
      );
      return res.data as List;
    } on HtpioError catch (e) {
      if (e.type == HtpioErrorType.cancel) return null; // replaced by a newer search
      rethrow;
    }
  }
}""",
        'top': True,
      },
      {
        'id': 'timeout', 'name': 'Timeouts', 'kind': 'guide',
        'text': 'A timeout covers the whole request, from connecting to the last byte. Set a default on the client and override it per request.',
        'code': """final htpio2 = HtpioClient(timeout: const Duration(seconds: 20));
await htpio2.get('https://api.example.com/report', timeout: const Duration(seconds: 60));""",
        'output': 'HtpioError(timeout): Request timed out after 60000 ms   ← if the report takes longer than 60 s',
      },
    ],
  },

  # ---------------------------------------------------------------- interceptors
  {
    'id': 'interceptors', 'title': 'Interceptors',
    'items': [
      {
        'id': 'HtpioInterceptor', 'name': 'HtpioInterceptor', 'kind': 'class',
        'sig': """abstract class HtpioInterceptor {
  HtpioClient? client;
  Future<HtpioRequest> onRequest(HtpioRequest request);
  Future<HtpioResponse> onResponse(HtpioResponse response);
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request);
}""",
        'text': 'Base class for your own interceptors. Override only the methods you need. <code>onRequest</code> can change the request before it is sent. <code>onResponse</code> can change the response. <code>onError</code> can recover by returning a response, or pass the error on by throwing it. <code>client</code> is set when you call <code>addInterceptor</code>; use <code>client!.send(request)</code> to send a request again.',
        'code': """class ApiKeyInterceptor extends HtpioInterceptor {
  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    request.headers['x-api-key'] = 'my-key';
    return request;
  }
}

/// Unwraps APIs that answer {"success": true, "data": {...}}.
class EnvelopeInterceptor extends HtpioInterceptor {
  @override
  Future<HtpioResponse> onResponse(HtpioResponse response) async {
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      return HtpioResponse(
        data: body['data'],
        statusCode: response.statusCode,
        headers: response.headers,
        request: response.request,
      );
    }
    return response;
  }
}

/// Shows cached data when the server is down.
class FallbackInterceptor extends HtpioInterceptor {
  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async {
    if (error.statusCode == 503) {
      return HtpioResponse(data: {'maintenance': true}, statusCode: 200, request: request);
    }
    throw error;
  }
}""",
        'top': True,
      },
      {
        'id': 'AuthTokenInterceptor', 'name': 'AuthTokenInterceptor', 'kind': 'class',
        'sig': """AuthTokenInterceptor({
  String? token,
  String headerName = 'Authorization',
  String tokenPrefix = 'Bearer',
  FutureOr<String?> Function()? tokenProvider,
  Future<String?> Function()? onRefreshToken,
  List<int> refreshStatusCodes = const [401],
})
String? get token
void setToken(String? token)
void clearToken()""",
        'text': 'Adds <code>Authorization: Bearer &lt;token&gt;</code> to every request. With <code>onRefreshToken</code> set, a 401 reply triggers one token refresh and the request is sent again. If several requests fail at the same moment, they share a single refresh.',
        'params': [
          ('token', 'String?', 'Starting token.'),
          ('tokenProvider', 'Function', 'Reads the token for each request, e.g. from secure storage. Used when no token is set.'),
          ('onRefreshToken', 'Future<String?> Function()', 'Returns a new token. Return <code>null</code> to give up; the original 401 error is then thrown.'),
          ('headerName / tokenPrefix', 'String', 'For APIs that use another header: <code>headerName: \'x-api-key\', tokenPrefix: \'\'</code>.'),
          ('refreshStatusCodes', 'List<int>', 'Which codes mean “token expired”. Default <code>[401]</code>.'),
        ],
        'code': """final auth = AuthTokenInterceptor(
  token: token,
  onRefreshToken: () async {
    // Use a separate client so the refresh call isn't intercepted.
    final res = await HtpioClient().post(
      'https://api.example.com/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return res.data['access_token'] as String?;
  },
);
htpio.addInterceptor(auth);

auth.setToken('token-after-login');
auth.clearToken(); // on logout""",
        'output': '200 {auth: Bearer fresh}   ← first try got 401, token refreshed, request repeated',
      },
      {
        'id': 'RetryInterceptor', 'name': 'RetryInterceptor', 'kind': 'class',
        'sig': """RetryInterceptor({
  int maxRetries = 3,
  Duration baseDelay = const Duration(seconds: 1),
  bool useExponentialBackoff = true,
  List<int> retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  Set<String> retryMethods = const {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'},
  bool Function(HtpioError error)? retryIf,
})
bool shouldRetry(HtpioError error, HtpioRequest request)
Duration delayFor(int attempt)""",
        'text': 'Retries failed requests, waiting 1 s, then 2 s, then 4 s. It retries timeouts, connection errors and the status codes listed. POST is not retried by default, so a payment is never sent twice.',
        'params': [
          ('maxRetries', 'int', 'Retries after the first attempt.'),
          ('baseDelay', 'Duration', 'Wait before the first retry.'),
          ('useExponentialBackoff', 'bool', '<code>false</code> waits 1×, 2×, 3× <code>baseDelay</code> instead.'),
          ('retryMethods', 'Set<String>', 'Add <code>\'POST\'</code> only if your API is safe to repeat.'),
          ('retryIf', 'bool Function(HtpioError)', 'Your own rule. Replaces the built-in checks.'),
        ],
        'code': """htpio.addInterceptor(RetryInterceptor(
  maxRetries: 3,
  baseDelay: const Duration(milliseconds: 500),
  retryIf: (e) => e.type == HtpioErrorType.connectionError || e.statusCode == 503,
));""",
        'output': '200 {attempt: 3}   ← server failed twice with 503, third try succeeded',
      },
      {
        'id': 'HtpioLogInterceptor', 'name': 'HtpioLogInterceptor', 'kind': 'class',
        'sig': """HtpioLogInterceptor({
  bool requestHeaders = false,
  bool requestBody = false,
  bool responseHeaders = false,
  bool responseBody = false,
  void Function(String line) logPrint = <dart:developer log>,
  Set<String> hiddenHeaders = const {'authorization', 'cookie', 'set-cookie'},
})""",
        'text': 'Logs every request and response. Tokens and cookies are always shown as <code>***</code>. Pass <code>logPrint: debugPrint</code> to send the lines to the Flutter console.',
        'code': """htpio.addInterceptor(HtpioLogInterceptor(
  requestHeaders: true,
  responseBody: true,
  logPrint: debugPrint,
));""",
        'output': """--> GET https://api.example.com/users/1
Authorization: ***
<-- 200 GET https://api.example.com/users/1
{id: 1, name: Ada Lovelace}""",
      },
      {
        'id': 'HtpioMiddleware', 'name': 'HtpioMiddleware', 'kind': 'class',
        'sig': """abstract class HtpioMiddleware {
  HtpioClient? client;
  Future<void> beforeRequest(HtpioRequest request);
  Future<void> afterResponse(HtpioResponse response);
  Future<void> onError(HtpioError error);
}""",
        'text': 'Watches requests without changing them. Use it for analytics, timing or crash reporting. Throwing in <code>beforeRequest</code> stops the request. <code>onError</code> runs once, after all retries have finished.',
        'code': """class TimingMiddleware extends HtpioMiddleware {
  final _watch = Stopwatch();

  @override
  Future<void> beforeRequest(HtpioRequest request) async => _watch
    ..reset()
    ..start();

  @override
  Future<void> afterResponse(HtpioResponse response) async =>
      print('${response.request?.uri.path} took ${_watch.elapsedMilliseconds} ms');

  @override
  Future<void> onError(HtpioError error) async =>
      print('report to crashlytics: $error');
}""",
        'top': True,
        'code2': 'htpio.use(TimingMiddleware());',
      },
    ],
  },

  # ---------------------------------------------------------------- cache & offline
  {
    'id': 'offline', 'title': 'Cache & offline',
    'items': [
      {
        'id': 'HtpioCache', 'name': 'HtpioCache', 'kind': 'class',
        'sig': """HtpioCache({Duration defaultTtl = const Duration(minutes: 5), int maxEntries = 100})
HtpioResponse<T>? get<T>(String key)
void set<T>(String key, HtpioResponse<T> response, {Duration? ttl})
void remove(String key)
void clear()
bool containsKey(String key)
int get size""",
        'text': 'An in-memory cache. Pass it to the client, then add <code>cache: true</code> to the GET requests you want cached. Only successful GET responses are stored. Keys look like <code>GET:https://api.example.com/categories</code>.',
        'code': """final cached = HtpioClient(
  baseUrl: 'https://api.example.com',
  cache: HtpioCache(defaultTtl: const Duration(minutes: 10)),
);

await cached.get('/categories', cache: true); // network
await cached.get('/categories', cache: true); // memory, for 10 minutes

cached.cache!.remove('GET:https://api.example.com/categories');
cached.cache!.clear(); // e.g. on logout""",
      },
      {
        'id': 'OfflineMode', 'name': 'OfflineMode', 'kind': 'class',
        'sig': """OfflineMode({
  Duration checkInterval = const Duration(seconds: 5),
  Future<bool> Function()? connectivityChecker,
  Set<String> queueMethods = const {'POST', 'PUT', 'PATCH', 'DELETE'},
  int maxQueueSize = 100,
})
Stream<bool> get connectivityStream
Stream<Object> get replayResults
bool get isOnline
int get queuedRequestsCount
Future<void> refresh()
Future<void> retryQueuedRequests()
void clearQueue()
void dispose()""",
        'text': 'While the device is offline, requests fail immediately with <code>HtpioErrorType.offline</code>, so the user isn’t left waiting for a timeout. Saves (POST, PUT, PATCH, DELETE) are queued and sent automatically when the connection comes back. Each replayed result appears on <code>replayResults</code>.',
        'code': """final offline = OfflineMode();
htpio.use(offline);

offline.connectivityStream.listen((online) {
  print(online ? 'Back online' : 'You are offline');
});
offline.replayResults.listen((result) {
  if (result is HtpioResponse) print('synced ${result.request?.uri}');
  if (result is HtpioError) print('sync failed: $result');
});

print(offline.queuedRequestsCount);
await offline.refresh();            // check now instead of waiting
await offline.retryQueuedRequests();
offline.dispose();                  // when the app closes""",
      },
      {
        'id': 'ConnectivityHelper', 'name': 'ConnectivityHelper', 'kind': 'class',
        'sig': """static Future<bool> isOnline({String host = 'google.com', Duration timeout})
static Future<bool> isOnlineReliable({List<String> hosts, Duration timeout})
static Stream<bool> watch({Duration interval})
static Stream<bool> get onStatusChange
static Future<bool> isWiFiConnected()
static Future<List<NetworkInterface>> getNetworkInterfaces()""",
        'text': 'Quick internet checks you can call anywhere. On mobile and desktop they look up a host name (DNS). On the web they use the browser’s online status. <code>isWiFiConnected</code> is a rough guess; use the <code>connectivity_plus</code> package if you need an exact answer.',
        'code': """if (!await ConnectivityHelper.isOnline()) {
  print('Please connect to the internet');
}
final sure = await ConnectivityHelper.isOnlineReliable();
ConnectivityHelper.watch(interval: const Duration(seconds: 10))
    .listen((online) => print('online: $online'));""",
      },
    ],
  },

  # ---------------------------------------------------------------- downloads
  {
    'id': 'downloads', 'title': 'Downloads',
    'items': [
      {
        'id': 'HtpioDownloadManager', 'name': 'HtpioDownloadManager', 'kind': 'class',
        'sig': """HtpioDownloadManager({http.Client? httpClient})
Future<File> downloadFile({
  required String url,
  required String savePath,
  Map<String, String>? headers,
  void Function(double progress)? onProgress,
})
void pauseDownload(String url)
void resumeDownload(String url)
void cancelDownload(String url)
double? getProgress(String url)
bool isDownloading(String url)
Stream<DownloadProgress> get progressStream
void dispose()""",
        'text': 'Downloads large files straight to disk with progress, pause, resume and cancel. Folders in <code>savePath</code> are created for you. If a download fails or is cancelled, the partial file is deleted. Needs a file system: on the web, use <code>get(url, responseType: ResponseType.bytes)</code> instead.',
        'code': """final downloads = HtpioDownloadManager();

final saved = await downloads.downloadFile(
  url: url,
  savePath: '${dir.path}/videos/intro.mp4',
  headers: {'Authorization': 'Bearer $token'},
  onProgress: (p) => print('${(p * 100).toStringAsFixed(0)}%'),
);
print('saved to ${saved.path}');

downloads.pauseDownload(url);
downloads.resumeDownload(url);
downloads.cancelDownload(url);      // downloadFile throws HtpioError(cancel)
print(downloads.isDownloading(url));
print(downloads.getProgress(url));  // 0.0 – 1.0, or null""",
        'output': """50%
100%
saved to <app documents>/videos/intro.mp4""",
      },
      {
        'id': 'DownloadProgress', 'name': 'DownloadProgress', 'kind': 'class',
        'sig': """final String url
final double progress        // 0.0 – 1.0 (0 if size unknown)
final int downloadedBytes
final int totalBytes         // -1 if the server didn't say""",
        'text': 'One event on <code>progressStream</code>. Handy for showing every download in a single list.',
        'code': """HtpioDownloadManager().progressStream.listen((p) {
  print(p); // DownloadProgress(url: …, progress: 42.0%, 420/1000 bytes)
});""",
      },
    ],
  },

  # ---------------------------------------------------------------- testing
  {
    'id': 'testing', 'title': 'Mocking & testing',
    'items': [
      {
        'id': 'MockServer', 'name': 'MockServer', 'kind': 'class',
        'sig': """void enable()
void disable()
bool get isEnabled
void registerMock(String url, dynamic data, {int statusCode = 200,
    Map<String, String>? headers, Duration? delay, String method = 'GET'})
void registerSequentialMocks(String url, List<MockResponse> responses, {String method = 'GET'})
void removeMock(String url, {String method = 'GET'})
void clearMocks()
MockResponse? match(String method, Uri uri)
Future<HtpioResponse<T>?> getMockResponse<T>(HtpioRequest<T> request)""",
        'text': 'Fake API answers, with no server needed. Use it to build screens before the backend is ready, run demos offline, or test error screens. A mock URL can be a full URL or just a path. Error status codes throw, exactly as a real server would.',
        'code': """final mock = MockServer()..enable();
mock.registerMock('/users/1', {'id': 1, 'name': 'Ada'});
mock.registerMock('/users', {'id': 2}, method: 'POST', statusCode: 201);
mock.registerMock('/users/404', {'message': 'not found'}, statusCode: 404);
mock.registerMock('/slow', {'ok': true}, delay: const Duration(seconds: 2));
mock.registerSequentialMocks('/job/7', [
  MockResponse(data: {'state': 'queued'}),
  MockResponse(data: {'state': 'running'}),
  MockResponse(data: {'state': 'done'}),
]);

final demo = HtpioClient(baseUrl: 'https://api.example.com', mockServer: mock);
print((await demo.get('/users/1')).data);
mock.disable(); // back to the real network""",
        'output': '{id: 1, name: Ada}',
      },
      {
        'id': 'MockResponse', 'name': 'MockResponse', 'kind': 'class',
        'sig': """MockResponse({
  required dynamic data,
  int statusCode = 200,
  Map<String, String> headers = const {},
  Duration? delay,
})""",
        'text': 'One fake response for <code>registerSequentialMocks</code>. <code>data</code> is what the decoded JSON would look like (a Map, List or String).',
        'code': "final r = MockResponse(data: {'state': 'done'}, delay: const Duration(milliseconds: 300));",
      },
      {
        'id': 'unit-tests', 'name': 'Unit tests with MockClient', 'kind': 'guide',
        'text': 'For unit tests, pass <code>MockClient</code> from <code>package:http/testing.dart</code>. You can check exactly what was sent and reply with anything.',
        'code': """import 'package:flutter_test/flutter_test.dart';
import 'package:htpio/htpio.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads a user', () async {
    final client = HtpioClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/users/1');
        return http.Response('{"id": 1, "name": "Ada"}', 200);
      }),
    );
    final res = await client.get('/users/1');
    expect(res.data['name'], 'Ada');
  });
}""",
        'standalone': True,
      },
      {
        'id': 'DebugConsole', 'name': 'DebugConsole', 'kind': 'class',
        'sig': """static int maxLogs = 200
void log(String message)
List<String> getLogs()
void clear()
Widget overlay({int lines = 5})""",
        'text': 'Every client writes its requests and errors here. <code>overlay()</code> shows the latest lines on top of your app while you develop. Headers and bodies are never logged, so tokens don’t appear on screen.',
        'code': """Widget buildApp() => MaterialApp(
      home: Stack(
        children: [
          const Placeholder(), // your home page
          if (kDebugMode) DebugConsole().overlay(lines: 5),
        ],
      ),
    );""",
        'top': True,
      },
    ],
  },

  # ---------------------------------------------------------------- reference
  {
    'id': 'reference', 'title': 'Reference',
    'items': [
      {
        'id': 'HtpioRequest', 'name': 'HtpioRequest<T>', 'kind': 'class',
        'sig': """HtpioRequest({
  required String url,
  String method = 'GET',
  dynamic body,
  bool cacheEnabled = false,
  Duration? timeout,
  Map<String, String>? headers,
  Map<String, dynamic>? queryParameters,
  T Function(Map<String, dynamic>)? fromJson,
  T Function(dynamic data)? decoder,
  ResponseType responseType = ResponseType.json,
  CancelToken? cancelToken,
  bool Function(int statusCode)? validateStatus,
  Map<String, dynamic>? extra,
})
Uri get uri
CancelToken get cancelToken
bool get isCancelled
void cancel()
HtpioRequest<T> copyWith({url, method, body, headers, queryParameters, timeout, extra})""",
        'text': 'One request. The verb methods build these for you; build one yourself only for <code>send()</code> or inside an interceptor. <code>uri</code> is the final URL including query parameters.',
        'code': """final req = HtpioRequest<User>(
  url: 'https://api.example.com/users',
  queryParameters: {'page': 2},
  fromJson: User.fromJson,
);
print(req.uri); // https://api.example.com/users?page=2
final again = req.copyWith(headers: {'x-retry': '1'});""",
      },
      {
        'id': 'platforms', 'name': 'Platform support', 'kind': 'guide',
        'table': [
          ('Feature', 'Android · iOS · macOS · Windows · Linux', 'Web'),
          ('Requests, interceptors, cache, mock, cancel', 'Yes', 'Yes'),
          ('Uploads with <code>fromBytes</code> / <code>fromString</code>', 'Yes', 'Yes'),
          ('Uploads with <code>fromPath</code>', 'Yes', 'No (no file paths)'),
          ('<code>HtpioDownloadManager</code>', 'Yes', 'No: use <code>ResponseType.bytes</code>'),
          ('<code>ConnectivityHelper</code> / <code>OfflineMode</code>', 'DNS lookup', 'Browser online status'),
        ],
        'text': 'htpio is pure Dart with no native code, so there is nothing to set up per platform. It also works when your app is compiled to WebAssembly (WASM).',
      },
      {
        'id': 'migration', 'name': 'Upgrading from 1.1.x', 'kind': 'guide',
        'text': '1.2 doesn’t break existing code: the old methods still work but are marked deprecated. Switch at your own pace.',
        'table': [
          ('1.1.x', '1.2+'),
          ("<code>getRequest(endpoint: url, fromJson: f)</code>", "<code>get(url, fromJson: f)</code>"),
          ("<code>postRequest(endpoint: url, data: d, fromJson: f)</code>", "<code>post(url, data: d, fromJson: f)</code>"),
          ("<code>putRequest</code> / <code>deleteRequest</code>", "<code>put</code> / <code>delete</code>"),
          ("<code>authToken: t</code>", "<code>AuthTokenInterceptor(token: t)</code>"),
          ("<code>postSingleFileWithDataRequest</code> / <code>postFilesWithDataRequest</code>", "<code>post(url, data: FormData.fromMap({...}))</code>"),
          ("<code>request.execute()</code>", "<code>client.send(request)</code>"),
        ],
        'text2': '<strong>Behavior changes:</strong> 4xx and 5xx responses now throw <code>HtpioError</code> instead of returning silently. <code>RetryInterceptor</code> and file uploads now actually work.',
      },
    ],
  },
]
