import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:htpio/htpio.dart'; // This is the package you're working on.
import 'package:bcrypt/bcrypt.dart';

// Define your custom HtpioClient for handling HTTP requests similar to ApiHelper
class HtpioClient {
  final Duration _timeoutDuration = const Duration(seconds: 30);
  final List<HtpioMiddleware> _middlewares = [];
  final List<HtpioInterceptor> _interceptors = [];
  final HtpioCache _cache = HtpioCache();
  final DebugConsole _debug = DebugConsole();

  // Use middlewares and interceptors
  void use(HtpioMiddleware middleware) => _middlewares.add(middleware);
  void addInterceptor(HtpioInterceptor interceptor) =>
      _interceptors.add(interceptor);

  // Generic method to send requests
  Future<HtpioResponse<T>> send<T>(HtpioRequest<T> request) async {
    try {
      _debug.log('Sending request to ${request.url}');

      for (final middleware in _middlewares) {
        await middleware.beforeRequest(request);
      }

      for (final interceptor in _interceptors) {
        request = await interceptor.onRequest(request) as HtpioRequest<T>;
      }

      final response = await request.execute();  // Execute the request dynamically

      for (final interceptor in _interceptors.reversed) {
        await interceptor.onResponse(response);
      }

      for (final middleware in _middlewares.reversed) {
        await middleware.afterResponse(response);
      }

      return response;
    } catch (error) {
      final wrapped = HtpioError.from(error);
      _debug.log('Error: ${wrapped.message}');
      rethrow;
    }
  }

  // GET Request handling (similar to ApiHelper)
  Future<HtpioResponse<T>> getRequest<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    String? authToken,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
    log('REQUEST TO : $endpoint');
    log('Headers: $headers');

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'GET',
      headers: headers,
      fromJson: fromJson,  // Pass `fromJson` for deserialization
    );

    return send(request);
  }

  // POST Request handling (similar to ApiHelper)
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
      fromJson: fromJson,  // Pass `fromJson` for deserialization
    );

    return send(request);
  }

  // PUT Request handling (similar to ApiHelper)
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
      fromJson: fromJson,  // Pass `fromJson` for deserialization
    );

    return send(request);
  }

  // DELETE Request handling (similar to ApiHelper)
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
      fromJson: fromJson,  // Pass `fromJson` for deserialization
    );

    return send(request);
  }

  // Handle file upload with data, similar to ApiHelper
  Future<HtpioResponse<T>> postFilesWithDataRequest<T>({
    required String endpoint,
    required String fileJsonKey,
    required List<File> files,
    required Map<String, String>? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'multipart/form-data',
      // Add your Authorization headers if necessary
    };

    log('REQUEST TO : $endpoint');
    log('Headers: $headers');

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'POST',
      headers: headers,
      files: files,
      body: data,
      fromJson: fromJson,  // Pass `fromJson` for deserialization
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
      // Add your Authorization headers if necessary
    };

    log('REQUEST TO : $endpoint');
    log('Headers: $headers');

    final request = HtpioRequest<T>(
      url: endpoint,
      method: 'POST',
      headers: headers,
      file: file,
      body: data,
      fromJson: fromJson,  // Pass `fromJson` for deserialization
    );

    return send(request);
  }
}
