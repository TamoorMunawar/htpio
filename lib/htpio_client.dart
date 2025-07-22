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

      final response = await request.execute();

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
}
