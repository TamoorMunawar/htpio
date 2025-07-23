// File: lib/src/htpio_client.dart
import 'package:htpio/htpio.dart';




class HtpioClient {
  final List<HtpioMiddleware> _middlewares = [];
  final List<HtpioInterceptor> _interceptors = [];
  final HtpioCache _cache = HtpioCache();
  final DebugConsole _debug = DebugConsole();

  void use(HtpioMiddleware middleware) => _middlewares.add(middleware);
  void addInterceptor(HtpioInterceptor interceptor) =>
      _interceptors.add(interceptor);

  Future<HtpioResponse<T>> send<T>(HtpioRequest<T> request) async {
    try {
      _debug.log('Sending request to ${request.url}');

      for (final middleware in _middlewares) {
        await middleware.beforeRequest(request);
      }

      for (final interceptor in _interceptors) {
        request = await interceptor.onRequest(request) as HtpioRequest<T>;
      }

      if (request.cacheEnabled) {
        final cached = _cache.get<T>(request.url);
        if (cached != null) return cached;
      }

      final response = await request.execute();  // Execute request dynamically

      for (final interceptor in _interceptors.reversed) {
        await interceptor.onResponse(response);
      }

      for (final middleware in _middlewares.reversed) {
        await middleware.afterResponse(response);
      }

      if (request.cacheEnabled) {
        _cache.set<T>(request.url, response);
      }

      return response;
    } catch (error) {
      final wrapped = HtpioError.from(error);
      _debug.log('Error: ${wrapped.message}');

      for (final middleware in _middlewares) {
        await middleware.onError(wrapped);
      }

      for (final interceptor in _interceptors.reversed) {
        await interceptor.onError(wrapped, request);
      }

      rethrow;
    }
  }

  // GET Request handling (now correct)
  Future<HtpioResponse<T>> get<T>(
      String url,
      T Function(Map<String, dynamic>) fromJson, {
        Map<String, String>? headers,
      }) async {
    final request = HtpioRequest<T>(
      url: url,
      method: 'GET',
      headers: headers,
      fromJson: fromJson,  // Pass `fromJson` here for deserialization
    );
    return send(request);
  }

  // POST Request handling
  Future<HtpioResponse<T>> post<T>(
      String url,
      dynamic body,
      T Function(Map<String, dynamic>) fromJson, {
        Map<String, String>? headers,
      }) async {
    final request = HtpioRequest<T>(
      url: url,
      method: 'POST',
      body: body,
      headers: headers,
      fromJson: fromJson,  // Pass `fromJson` here for deserialization
    );
    return send(request);
  }

  // PUT Request handling
  Future<HtpioResponse<T>> put<T>(
      String url,
      dynamic body,
      T Function(Map<String, dynamic>) fromJson, {
        Map<String, String>? headers,
      }) async {
    final request = HtpioRequest<T>(
      url: url,
      method: 'PUT',
      body: body,
      headers: headers,
      fromJson: fromJson,  // Pass `fromJson` here for deserialization
    );
    return send(request);
  }

  // DELETE Request handling
  Future<HtpioResponse<T>> delete<T>(
      String url,
      T Function(Map<String, dynamic>) fromJson, {
        Map<String, String>? headers,
      }) async {
    final request = HtpioRequest<T>(
      url: url,
      method: 'DELETE',
      headers: headers,
      fromJson: fromJson,  // Pass `fromJson` here for deserialization
    );
    return send(request);
  }
}


