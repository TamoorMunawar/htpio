import 'htpio_client.dart';
import 'htpio_response.dart';
import 'htpio_error.dart';
import 'dart:io';  // For handling file uploads

class HtpioRequest<T> {
  final String url;
  final String method;
  final dynamic body;
  final bool cacheEnabled;
  final Map<String, String> headers;
  Duration? timeout;
  bool _cancelled = false;
  final T Function(Map<String, dynamic>)? fromJson;  // fromJson function for deserialization
  final File? file;  // Single file for upload
  final List<File>? files;  // Multiple files for upload

  HtpioRequest({
    required this.url,
    this.method = 'GET',
    this.body,
    this.cacheEnabled = false,
    this.timeout,
    Map<String, String>? headers,
    this.fromJson,  // Accept fromJson function here
    this.file,  // Single file upload
    this.files,  // Multiple files upload
  }) : headers = headers ?? {};

  // Execute the dynamic network request
  Future<HtpioResponse<T>> execute() async {
    if (_cancelled) throw HtpioError('Request was cancelled');

    try {
      // Making the request dynamically
      final responseJson = await _makeRequest(); // Real network request with Htpio

      // Safely cast 'data' to Map<String, dynamic> and use fromJson to deserialize
      final data = responseJson['data'] is Map<String, dynamic>
          ? fromJson!(responseJson['data'] as Map<String, dynamic>)
          : throw HtpioError('Invalid data format');

      return HtpioResponse<T>(data: data, statusCode: responseJson['status_code']);
    } catch (e) {
      throw HtpioError('Request failed: $e');
    }
  }

  // Make the actual network request using HtpioClient
  Future<Map<String, dynamic>> _makeRequest() async {
    final client = HtpioClient();

    // Prepare the HtpioRequest
    final request = HtpioRequest<Map<String, dynamic>>(
      url: url,
      method: method,
      body: body,
      headers: headers,
      fromJson: (json) => json,  // Directly return the json as it is
    );

    // Send the request and get the response
    final response = await client.send<Map<String, dynamic>>(request);

    // Return the response data and status code
    return {
      'data': response.data,
      'status_code': response.statusCode,
    };
  }

  void cancel() => _cancelled = true;
}
