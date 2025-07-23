import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'htpio_request.dart';
import 'htpio_response.dart';
import 'htpio_error.dart';
import 'htpio_middleware.dart';
import 'src/interceptors/interceptor.dart';
import 'src/debug/debug_console.dart';

class HtpioClient {
  final List<HtpioMiddleware> _middlewares = [];
  final List<HtpioInterceptor> _interceptors = [];
  final DebugConsole _debug = DebugConsole();

  void use(HtpioMiddleware middleware) => _middlewares.add(middleware);
  void addInterceptor(HtpioInterceptor interceptor) => _interceptors.add(interceptor);

  Future<HtpioResponse<T>> send<T>(HtpioRequest<T> request) async {
    try {
      _debug.log('Sending request to ${request.url}');

      // Process middlewares before the request
      for (final middleware in _middlewares) {
        await middleware.beforeRequest(request);
      }

      // Process interceptors before the request
      HtpioRequest<T> processedRequest = request;
      for (final interceptor in _interceptors) {
        processedRequest = await interceptor.onRequest(processedRequest) as HtpioRequest<T>;
      }

      // Execute the actual HTTP request
      final response = await processedRequest.execute();

      // Process interceptors after the response
      HtpioResponse processedResponse = response;
      for (final interceptor in _interceptors.reversed) {
        processedResponse = await interceptor.onResponse(processedResponse);
      }

      // Process middlewares after the response
      for (final middleware in _middlewares.reversed) {
        await middleware.afterResponse(processedResponse);
      }

      return processedResponse as HtpioResponse<T>;
    } catch (error) {
      final wrapped = HtpioError.from(error);
      _debug.log('Error: ${wrapped.message}');
      rethrow;
    }
  }

  // GET Request
  Future<HtpioResponse<T>> getRequest<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    
    log('REQUEST TO: $endpoint');
    log('Headers: $headers');

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'GET',
      headers: headers,
      fromJson: fromJson,
    );

    return send(request);
  }

  // POST Request
  Future<HtpioResponse<T>> postRequest<T>({
    required String endpoint,
    required dynamic data,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'POST',
      headers: headers,
      body: jsonEncode(data),
      fromJson: fromJson,
    );

    return send(request);
  }

  // PUT Request
  Future<HtpioResponse<T>> putRequest<T>({
    required String endpoint,
    required dynamic data,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'PUT',
      headers: headers,
      body: jsonEncode(data),
      fromJson: fromJson,
    );

    return send(request);
  }

  // DELETE Request
  Future<HtpioResponse<T>> deleteRequest<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'DELETE',
      headers: headers,
      fromJson: fromJson,
    );

    return send(request);
  }

  // File upload with data
  Future<HtpioResponse<T>> postFilesWithDataRequest<T>({
    required String endpoint,
    required String fileJsonKey,
    required List<File> files,
    required Map<String, String>? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };

    log('REQUEST TO : $endpoint');
    log('Headers: $headers');

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'POST',
      headers: headers,
      files: files,
      body: data,
      fromJson: fromJson,
    );

    return send(request);
  }

  // POST single file with data
  Future<HtpioResponse<T>> postSingleFileWithDataRequest<T>({
    required String endpoint,
    required String fileJsonKey,
    required File file,
    required Map<String, String>? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
    };

    log('REQUEST TO : $endpoint');
    log('Headers: $headers');

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'POST',
      headers: headers,
      file: file,
      body: data,
      fromJson: fromJson,
    );

    return send(request);
  }
}
