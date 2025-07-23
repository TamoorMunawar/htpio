// File: lib/src/htpio_request.dart

import 'htpio_response.dart';
import 'htpio_error.dart';

class HtpioRequest<T> {
  final String url;
  final String method;
  final dynamic body;
  final bool cacheEnabled;
  final Map<String, String> headers;
  Duration? timeout;
  bool _cancelled = false;
  final T Function(Map<String, dynamic>)? fromJson;  // fromJson function for deserialization

  HtpioRequest({
    required this.url,
    this.method = 'GET',
    this.body,
    this.cacheEnabled = false,
    this.timeout,
    Map<String, String>? headers,
    this.fromJson,  // Accept fromJson function here
  }) : headers = headers ?? {};

  // Execute the dynamic network request
  Future<HtpioResponse<T>> execute() async {
    if (_cancelled) throw HtpioError('Request was cancelled');

    try {
      // Making the request dynamically
      final responseJson = await _makeRequest(); // Simulated request handler

      // Safely cast 'data' to Map<String, dynamic> and use fromJson to deserialize
      final data = responseJson['data'] is Map<String, dynamic>
          ? fromJson!(responseJson['data'] as Map<String, dynamic>)
          : throw HtpioError('Invalid data format');

      return HtpioResponse<T>(data: data, statusCode: responseJson['status_code']);
    } catch (e) {
      throw HtpioError('Request failed: $e');
    }
  }

  // Simulate an API response (you can replace this with actual network code)
  Future<Map<String, dynamic>> _makeRequest() async {
    // Simulate network delay and dynamic data fetching
    await Future.delayed(Duration(seconds: 2));  // Simulate network delay
    return {
      'data': {
        'id': 1,
        'title': 'Dynamic Product',
        'description': 'This is a dynamically fetched product description.',
        'price': 49.99
      },
      'status_code': 200
    };
  }

  void cancel() => _cancelled = true;
}
