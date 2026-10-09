import '../../htpio_request.dart';
import '../../htpio_response.dart';

/// Answers requests with fake data instead of the network. Great for tests,
/// demos and building UI before the backend exists.
///
/// ```dart
/// final mock = MockServer()..enable();
/// mock.registerMock('/users/1', {'id': 1, 'name': 'Ada'});
/// mock.registerMock('/users/2', {'error': 'not found'}, statusCode: 404);
///
/// final htpio = HtpioClient(baseUrl: 'https://api.example.com', mockServer: mock);
/// ```
///
/// A mock URL matches the full request URL (with or without query string)
/// or just its path.
class MockServer {
  final Map<String, MockResponse> _mocks = {};
  final Map<String, List<MockResponse>> _sequentialMocks = {};
  final Map<String, int> _callCounts = {};
  bool _isEnabled = false;

  void enable() => _isEnabled = true;

  void disable() => _isEnabled = false;

  bool get isEnabled => _isEnabled;

  void registerMock(
    String url,
    dynamic data, {
    int statusCode = 200,
    Map<String, String>? headers,
    Duration? delay,
    String method = 'GET',
  }) {
    _mocks[_createKey(method, url)] = MockResponse(
      data: data,
      statusCode: statusCode,
      headers: headers ?? const {},
      delay: delay,
    );
  }

  /// Returns [responses] one after another for repeated calls. After the
  /// last one, a mock registered with [registerMock] (if any) is used.
  void registerSequentialMocks(
    String url,
    List<MockResponse> responses, {
    String method = 'GET',
  }) {
    final key = _createKey(method, url);
    _sequentialMocks[key] = List.of(responses);
    _callCounts[key] = 0;
  }

  /// Finds the mock for [method] and [uri], or `null`.
  MockResponse? match(String method, Uri uri) {
    if (!_isEnabled) return null;
    final candidates = {
      uri.toString(),
      uri.toString().split('?').first,
      uri.path,
    };
    for (final url in candidates) {
      final key = _createKey(method, url);
      final sequence = _sequentialMocks[key];
      if (sequence != null) {
        final count = _callCounts[key] ?? 0;
        if (count < sequence.length) {
          _callCounts[key] = count + 1;
          return sequence[count];
        }
      }
      final single = _mocks[key];
      if (single != null) return single;
    }
    return null;
  }

  /// Returns the mocked response for [request] without going through a
  /// client, or `null` when nothing matches.
  Future<HtpioResponse<T>?> getMockResponse<T>(HtpioRequest<T> request) async {
    final mock = match(request.method, request.uri);
    if (mock == null) return null;
    if (mock.delay != null) await Future<void>.delayed(mock.delay!);

    final data = mock.data;
    final T parsed;
    if (request.decoder != null) {
      parsed = request.decoder!(data);
    } else if (request.fromJson != null) {
      parsed = data is Map<String, dynamic>
          ? request.fromJson!(data)
          : request.fromJson!({'data': data});
    } else {
      parsed = data as T;
    }
    return HtpioResponse<T>(
      data: parsed,
      statusCode: mock.statusCode,
      headers: mock.headers,
      request: request,
    );
  }

  void clearMocks() {
    _mocks.clear();
    _sequentialMocks.clear();
    _callCounts.clear();
  }

  void removeMock(String url, {String method = 'GET'}) {
    final key = _createKey(method, url);
    _mocks.remove(key);
    _sequentialMocks.remove(key);
    _callCounts.remove(key);
  }

  String _createKey(String method, String url) =>
      '${method.toUpperCase()}:$url';
}

/// A fake response returned by [MockServer].
class MockResponse {
  MockResponse({
    required this.data,
    this.statusCode = 200,
    this.headers = const {},
    this.delay,
  });

  /// Response body as it would look after JSON decoding (a `Map`, `List`,
  /// `String`…).
  final dynamic data;
  final int statusCode;
  final Map<String, String> headers;

  /// Simulated network latency.
  final Duration? delay;
}
