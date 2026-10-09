import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'htpio_error.dart';
import 'htpio_middleware.dart';
import 'htpio_request.dart';
import 'htpio_response.dart';
import 'src/cache/htpio_cache.dart';
import 'src/cancel_token.dart';
import 'src/debug/debug_console.dart';
import 'src/form_data.dart';
import 'src/interceptors/interceptor.dart';
import 'src/mock/mock_server.dart';
import 'src/platform/platform.dart';

/// The htpio HTTP client.
///
/// ```dart
/// final htpio = HtpioClient(baseUrl: 'https://api.example.com');
///
/// final res = await htpio.get('/users/1');
/// print(res.data['name']);
///
/// final user = await htpio.get<User>('/users/1', fromJson: User.fromJson);
/// await htpio.post('/users', data: {'name': 'Ada'});
/// ```
///
/// Create one client and reuse it: it keeps connections alive between
/// requests. Call [close] when you no longer need it.
class HtpioClient {
  /// Creates a client. Every argument is optional; see the fields below.
  HtpioClient({
    this.baseUrl = '',
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    this.timeout,
    bool Function(int statusCode)? validateStatus,
    http.Client? httpClient,
    this.cache,
    this.mockServer,
    List<HtpioInterceptor>? interceptors,
  })  : headers = headers ?? {},
        queryParameters = queryParameters ?? {},
        validateStatus = validateStatus ?? _defaultValidateStatus,
        _http = httpClient ?? http.Client() {
    interceptors?.forEach(addInterceptor);
  }

  /// Prefix for relative paths, e.g. `https://api.example.com/v1`.
  String baseUrl;

  /// Headers sent with every request. Per-request headers win.
  final Map<String, String> headers;

  /// Query parameters sent with every request.
  final Map<String, dynamic> queryParameters;

  /// Default total time allowed per request. `null` means no limit.
  Duration? timeout;

  /// Decides which status codes count as success. Default: 200–299.
  bool Function(int statusCode) validateStatus;

  /// Response cache used by requests made with `cache: true`.
  HtpioCache? cache;

  /// When set and enabled, matching requests are answered by the mock
  /// instead of the network.
  MockServer? mockServer;

  final http.Client _http;
  final List<HtpioMiddleware> _middlewares = [];
  final List<HtpioInterceptor> _interceptors = [];
  final DebugConsole _debug = DebugConsole();

  /// Set in `HtpioRequest.extra` by interceptors that re-send a request
  /// (retry, token refresh). Middleware `onError` then runs only once, for
  /// the outermost request.
  static const String resendKey = 'htpio_resend';

  static bool _defaultValidateStatus(int status) =>
      status >= 200 && status < 300;

  /// Registered interceptors, in the order they run for requests.
  List<HtpioInterceptor> get interceptors => List.unmodifiable(_interceptors);

  /// Adds a middleware (see [HtpioMiddleware]).
  void use(HtpioMiddleware middleware) {
    middleware.client = this;
    _middlewares.add(middleware);
  }

  /// Adds an interceptor (see [HtpioInterceptor]).
  void addInterceptor(HtpioInterceptor interceptor) {
    interceptor.client = this;
    _interceptors.add(interceptor);
  }

  /// Removes a previously added interceptor.
  bool removeInterceptor(HtpioInterceptor interceptor) =>
      _interceptors.remove(interceptor);

  /// Closes the underlying connections. The client cannot be used afterwards.
  void close() => _http.close();

  // ---------------------------------------------------------------------------
  // Verbs
  // ---------------------------------------------------------------------------

  /// Sends a GET request.
  Future<HtpioResponse<T>> get<T>(
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
  }) {
    return request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
      decoder: decoder,
      responseType: responseType,
      cancelToken: cancelToken,
      timeout: timeout,
      cache: cache,
      extra: extra,
    );
  }

  /// Sends a POST request. See [request] for how [data] is encoded.
  Future<HtpioResponse<T>> post<T>(
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
  }) {
    return request<T>(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
      decoder: decoder,
      responseType: responseType,
      cancelToken: cancelToken,
      timeout: timeout,
      extra: extra,
    );
  }

  /// Sends a PUT request.
  Future<HtpioResponse<T>> put<T>(
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
  }) {
    return request<T>(
      path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
      decoder: decoder,
      responseType: responseType,
      cancelToken: cancelToken,
      timeout: timeout,
      extra: extra,
    );
  }

  /// Sends a PATCH request.
  Future<HtpioResponse<T>> patch<T>(
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
  }) {
    return request<T>(
      path,
      method: 'PATCH',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
      decoder: decoder,
      responseType: responseType,
      cancelToken: cancelToken,
      timeout: timeout,
      extra: extra,
    );
  }

  /// Sends a DELETE request.
  Future<HtpioResponse<T>> delete<T>(
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
  }) {
    return request<T>(
      path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      fromJson: fromJson,
      decoder: decoder,
      responseType: responseType,
      cancelToken: cancelToken,
      timeout: timeout,
      extra: extra,
    );
  }

  /// Sends a HEAD request. The response has no body.
  Future<HtpioResponse<dynamic>> head(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    CancelToken? cancelToken,
    Duration? timeout,
  }) {
    return request<dynamic>(
      path,
      method: 'HEAD',
      queryParameters: queryParameters,
      headers: headers,
      cancelToken: cancelToken,
      timeout: timeout,
    );
  }

  /// Sends a request with any [method].
  ///
  /// [data] is encoded as:
  /// * `FormData` → `multipart/form-data`
  /// * `String` → text as is
  /// * `List<int>` → raw bytes
  /// * `Map` with `Content-Type: application/x-www-form-urlencoded` → form fields
  /// * anything else (`Map`, `List`, objects with `toJson()`) → JSON
  ///
  /// The response body is decoded according to [responseType]. Pass
  /// [fromJson] or [decoder] to turn it into your own type `T`.
  Future<HtpioResponse<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(dynamic data)? decoder,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
    Duration? timeout,
    bool cache = false,
    Map<String, dynamic>? extra,
  }) {
    return send<T>(
      HtpioRequest<T>(
        url: path,
        method: method.toUpperCase(),
        body: data,
        queryParameters: queryParameters,
        headers: headers,
        fromJson: fromJson,
        decoder: decoder,
        responseType: responseType,
        cancelToken: cancelToken,
        timeout: timeout,
        cacheEnabled: cache,
        extra: extra,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pipeline
  // ---------------------------------------------------------------------------

  /// Runs [request] through middlewares, interceptors, cache, mock and
  /// network. Throws [HtpioError] on failure.
  Future<HtpioResponse<T>> send<T>(HtpioRequest<T> request) async {
    var current = _prepare(request);
    try {
      for (final middleware in _middlewares) {
        await middleware.beforeRequest(current);
      }
      for (final interceptor in _interceptors) {
        current = await interceptor.onRequest(current) as HtpioRequest<T>;
      }

      _debug.log('${current.method} ${current.uri}');

      final cacheKey = _cacheKey(current);
      if (cacheKey != null) {
        final cached = cache!.get<T>(cacheKey);
        if (cached != null) {
          _debug.log('Cache hit ${current.uri}');
          return cached;
        }
      }

      HtpioResponse<dynamic> response = await _dispatch<T>(current);
      for (final interceptor in _interceptors.reversed) {
        response = await interceptor.onResponse(response);
      }
      for (final middleware in _middlewares.reversed) {
        await middleware.afterResponse(response);
      }

      final typed = _retype<T>(response, current);
      if (cacheKey != null) cache!.set<T>(cacheKey, typed);
      return typed;
    } catch (error, stackTrace) {
      var wrapped = _wrapError(error, stackTrace, current);
      _debug.log('Error: $wrapped');

      for (final interceptor in _interceptors) {
        try {
          final recovered = await interceptor.onError(wrapped, current);
          return _retype<T>(recovered, current);
        } catch (next, nextStack) {
          wrapped = _wrapError(next, nextStack, current);
        }
      }
      if (current.extra[resendKey] != true) {
        for (final middleware in _middlewares) {
          await middleware.onError(wrapped);
        }
      }
      throw wrapped;
    }
  }

  /// Interceptors work with untyped responses (a retry, refresh or fallback
  /// returns `HtpioResponse<dynamic>`); restore the caller's type `T`.
  HtpioResponse<T> _retype<T>(HtpioResponse response, HtpioRequest<T> request) {
    if (response is HtpioResponse<T>) return response;
    final data = response.data;
    return HtpioResponse<T>(
      data: data is T ? data : _convert<T>(request, data),
      statusCode: response.statusCode,
      headers: response.headers,
      request: response.request ?? request,
      reasonPhrase: response.reasonPhrase,
    );
  }

  /// Applies [baseUrl], default headers and default query parameters.
  /// Safe to call more than once on the same request.
  HtpioRequest<T> _prepare<T>(HtpioRequest<T> request) {
    final url = _resolveUrl(request.url);
    final mergedHeaders = {...headers, ...request.headers};
    final mergedQuery = {...queryParameters, ...request.queryParameters};
    request.timeout ??= timeout;
    if (url == request.url &&
        mergedHeaders.length == request.headers.length &&
        mergedQuery.length == request.queryParameters.length) {
      return request;
    }
    return request.copyWith(
      url: url,
      headers: mergedHeaders,
      queryParameters: mergedQuery,
    );
  }

  String _resolveUrl(String url) {
    if (baseUrl.isEmpty ||
        url.startsWith('http://') ||
        url.startsWith('https://')) {
      return url;
    }
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (url.isEmpty) return base;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  String? _cacheKey(HtpioRequest request) {
    if (cache == null || !request.cacheEnabled || request.method != 'GET') {
      return null;
    }
    return 'GET:${request.uri}';
  }

  Future<HtpioResponse<T>> _dispatch<T>(HtpioRequest<T> request) async {
    if (request.isCancelled) {
      throw HtpioError(
        'Request was cancelled',
        type: HtpioErrorType.cancel,
        originalError: request.cancelToken.reason,
        request: request,
      );
    }

    final mock = mockServer;
    if (mock != null && mock.isEnabled) {
      final match = mock.match(request.method, request.uri);
      if (match != null) {
        if (match.delay != null) await Future<void>.delayed(match.delay!);
        return _complete(
          request,
          statusCode: match.statusCode,
          headers: match.headers,
          data: match.data,
        );
      }
    }

    final abort = Completer<void>();
    var timedOut = false;
    Timer? timer;
    final limit = request.timeout;
    if (limit != null) {
      timer = Timer(limit, () {
        timedOut = true;
        if (!abort.isCompleted) abort.complete();
      });
    }
    unawaited(request.cancelToken.whenCancelled.then((_) {
      if (!abort.isCompleted) abort.complete();
    }));

    // Not every http.Client honours abortTrigger, so race against it too.
    Future<R> guard<R>(Future<R> future) => Future.any<R>([
          future,
          abort.future.then<R>(
            (_) => throw http.RequestAbortedException(request.uri),
          ),
        ]);

    try {
      final httpRequest = await _buildHttpRequest(request, abort.future);
      final streamed = await guard(_http.send(httpRequest));
      final raw = await guard(http.Response.fromStream(streamed));
      return _complete(
        request,
        statusCode: raw.statusCode,
        headers: raw.headers,
        data: _decodeBody(request, raw),
        reasonPhrase: raw.reasonPhrase,
      );
    } on http.RequestAbortedException catch (e, st) {
      if (timedOut) {
        throw HtpioError(
          'Request timed out after ${limit!.inMilliseconds} ms',
          type: HtpioErrorType.timeout,
          originalError: e,
          stackTrace: st,
          request: request,
        );
      }
      throw HtpioError(
        'Request was cancelled',
        type: HtpioErrorType.cancel,
        originalError: request.cancelToken.reason ?? e,
        stackTrace: st,
        request: request,
      );
    } finally {
      timer?.cancel();
    }
  }

  Future<http.BaseRequest> _buildHttpRequest(
    HtpioRequest request,
    Future<void> abortTrigger,
  ) async {
    final uri = request.uri;
    var body = request.body;

    if (body is! FormData && (request.file != null || request.files != null)) {
      final form = FormData();
      if (body is Map) {
        body.forEach((k, v) {
          if (v != null) form.fields['$k'] = '$v';
        });
      }
      for (final f in [
        if (request.file != null) request.file!,
        ...?request.files
      ]) {
        form.files.add(
          MapEntry(request.fileField, HtpioMultipartFile.fromPath(f.path)),
        );
      }
      body = form;
    }

    if (body is FormData) {
      final multipart = http.AbortableMultipartRequest(
        request.method,
        uri,
        abortTrigger: abortTrigger,
      );
      request.headers.forEach((key, value) {
        // The multipart boundary is set by http; a bare user value breaks it.
        if (key.toLowerCase() != 'content-type') multipart.headers[key] = value;
      });
      multipart.fields.addAll(body.fields);
      multipart.files.addAll(await body.toMultipartFiles());
      return multipart;
    }

    final simple = http.AbortableRequest(
      request.method,
      uri,
      abortTrigger: abortTrigger,
    );
    simple.headers.addAll(request.headers);
    if (body == null) return simple;

    final contentType = simple.headers['content-type'] ?? '';
    if (body is String) {
      simple.headers
          .putIfAbsent('content-type', () => 'text/plain; charset=utf-8');
      simple.body = body;
    } else if (body is List<int>) {
      simple.headers
          .putIfAbsent('content-type', () => 'application/octet-stream');
      simple.bodyBytes = body;
    } else if (body is Map &&
        contentType.contains('application/x-www-form-urlencoded')) {
      simple.bodyFields = body.map((k, v) => MapEntry('$k', '$v'));
    } else {
      simple.headers
          .putIfAbsent('content-type', () => 'application/json; charset=utf-8');
      simple.body = jsonEncode(body);
    }
    return simple;
  }

  dynamic _decodeBody(HtpioRequest request, http.Response raw) {
    switch (request.responseType) {
      case ResponseType.bytes:
        return raw.bodyBytes;
      case ResponseType.plain:
        return _text(raw.bodyBytes);
      case ResponseType.json:
        final text = _text(raw.bodyBytes);
        if (text.trim().isEmpty) return null;
        try {
          return jsonDecode(text);
        } on FormatException {
          return text;
        }
    }
  }

  static String _text(Uint8List bytes) =>
      utf8.decode(bytes, allowMalformed: true);

  HtpioResponse<T> _complete<T>(
    HtpioRequest<T> request, {
    required int statusCode,
    required Map<String, String> headers,
    required dynamic data,
    String? reasonPhrase,
  }) {
    final accept = request.validateStatus ?? validateStatus;
    if (!accept(statusCode)) {
      throw HtpioError(
        'Request failed with status code $statusCode',
        statusCode: statusCode,
        type: HtpioErrorType.badResponse,
        request: request,
        response: HtpioResponse<dynamic>(
          data: data,
          statusCode: statusCode,
          headers: headers,
          request: request,
          reasonPhrase: reasonPhrase,
        ),
      );
    }
    return HtpioResponse<T>(
      data: _convert<T>(request, data),
      statusCode: statusCode,
      headers: headers,
      request: request,
      reasonPhrase: reasonPhrase,
    );
  }

  T _convert<T>(HtpioRequest<T> request, dynamic data) {
    try {
      if (request.decoder != null) return request.decoder!(data);
      final fromJson = request.fromJson;
      if (fromJson != null) {
        if (data is Map<String, dynamic>) return fromJson(data);
        if (data == null) return fromJson(<String, dynamic>{});
        return fromJson({'data': data});
      }
      if (data is T) return data;
      throw FormatException(
        'Response data is ${data.runtimeType}, not $T. '
        'Pass fromJson or decoder to convert it.',
      );
    } on HtpioError {
      rethrow;
    } catch (e, st) {
      throw HtpioError(
        'Failed to parse response: $e',
        type: HtpioErrorType.parse,
        originalError: e,
        stackTrace: st,
        request: request,
      );
    }
  }

  HtpioError _wrapError(
      Object error, StackTrace stackTrace, HtpioRequest request) {
    if (error is HtpioError) {
      return error.request == null ? error.copyWith(request: request) : error;
    }
    if (error is TimeoutException) {
      return HtpioError(
        error.message ?? 'Request timed out',
        type: HtpioErrorType.timeout,
        originalError: error,
        stackTrace: stackTrace,
        request: request,
      );
    }
    if (error is http.ClientException) {
      return HtpioError(
        error.message,
        type: HtpioErrorType.connectionError,
        originalError: error,
        stackTrace: stackTrace,
        request: request,
      );
    }
    return HtpioError(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
      request: request,
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy API (1.1.x). Kept so existing apps keep compiling.
  // ---------------------------------------------------------------------------

  Map<String, String> _legacyHeaders(String? authToken) => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// Legacy GET. Use [get] instead.
  @Deprecated('Use get(path, fromJson: ...). Will be removed in 2.0.0.')
  Future<HtpioResponse<T>> getRequest<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) {
    return get<T>(endpoint,
        headers: _legacyHeaders(authToken), fromJson: fromJson);
  }

  @Deprecated(
      'Use post(path, data: ..., fromJson: ...). Will be removed in 2.0.0.')

  /// Legacy POST. Use [post] instead.
  Future<HtpioResponse<T>> postRequest<T>({
    required String endpoint,
    required dynamic data,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) {
    return post<T>(
      endpoint,
      data: jsonEncode(data),
      headers: _legacyHeaders(authToken),
      fromJson: fromJson,
    );
  }

  @Deprecated(
      'Use put(path, data: ..., fromJson: ...). Will be removed in 2.0.0.')

  /// Legacy PUT. Use [put] instead.
  Future<HtpioResponse<T>> putRequest<T>({
    required String endpoint,
    required dynamic data,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) {
    return put<T>(
      endpoint,
      data: jsonEncode(data),
      headers: _legacyHeaders(authToken),
      fromJson: fromJson,
    );
  }

  /// Legacy DELETE. Use [delete] instead.
  @Deprecated('Use delete(path, fromJson: ...). Will be removed in 2.0.0.')
  Future<HtpioResponse<T>> deleteRequest<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) {
    return delete<T>(endpoint,
        headers: _legacyHeaders(authToken), fromJson: fromJson);
  }

  @Deprecated(
      'Use post(path, data: FormData.fromMap({...})). Will be removed in 2.0.0.')

  /// Legacy multi-file upload. Use [post] with [FormData] instead.
  Future<HtpioResponse<T>> postFilesWithDataRequest<T>({
    required String endpoint,
    required String fileJsonKey,
    required List<File> files,
    required Map<String, String>? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return send<T>(HtpioRequest<T>(
      url: endpoint,
      method: 'POST',
      body: data,
      files: files,
      fileField: fileJsonKey,
      fromJson: fromJson,
    ));
  }

  @Deprecated(
      'Use post(path, data: FormData.fromMap({...})). Will be removed in 2.0.0.')

  /// Legacy single-file upload. Use [post] with [FormData] instead.
  Future<HtpioResponse<T>> postSingleFileWithDataRequest<T>({
    required String endpoint,
    required String fileJsonKey,
    required File file,
    required Map<String, String>? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return send<T>(HtpioRequest<T>(
      url: endpoint,
      method: 'POST',
      body: data,
      file: file,
      fileField: fileJsonKey,
      fromJson: fromJson,
    ));
  }
}
