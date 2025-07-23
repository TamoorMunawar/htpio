import 'dart:convert';
import 'dart:io';
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
  final T Function(Map<String, dynamic>)? fromJson;
  final File? file;
  final List<File>? files;

  HtpioRequest({
    required this.url,
    this.method = 'GET',
    this.body,
    this.cacheEnabled = false,
    this.timeout,
    Map<String, String>? headers,
    this.fromJson,
    this.file,
    this.files,
  }) : headers = headers ?? {};

  // Execute the actual HTTP request using built-in HttpClient
  Future<HtpioResponse<T>> execute() async {
    if (_cancelled) throw HtpioError('Request was cancelled');

    try {
      final httpClient = HttpClient();
      if (timeout != null) {
        httpClient.connectionTimeout = timeout!;
      }

      final uri = Uri.parse(url);
      late HttpClientRequest request;

      // Create request based on method
      switch (method.toUpperCase()) {
        case 'GET':
          request = await httpClient.getUrl(uri);
          break;
        case 'POST':
          request = await httpClient.postUrl(uri);
          break;
        case 'PUT':
          request = await httpClient.putUrl(uri);
          break;
        case 'DELETE':
          request = await httpClient.deleteUrl(uri);
          break;
        default:
          throw HtpioError('Unsupported HTTP method: $method');
      }

      // Add headers
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      // Add body for POST/PUT requests
      if (body != null && (method.toUpperCase() == 'POST' || method.toUpperCase() == 'PUT')) {
        if (body is String) {
          request.write(body);
        } else if (body is Map) {
          request.write(jsonEncode(body));
        }
      }

      // Send request and get response
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      httpClient.close();

      // Parse response
      final responseData = responseBody.isNotEmpty ? jsonDecode(responseBody) : {};
      
      // Handle different response formats
      T parsedData;
      if (fromJson != null) {
        if (responseData is Map<String, dynamic>) {
          parsedData = fromJson!(responseData);
        } else if (responseData is List) {
          // Handle list responses
          parsedData = fromJson!({'data': responseData});
        } else {
          parsedData = fromJson!({'data': responseData});
        }
      } else {
        parsedData = responseData as T;
      }

      return HtpioResponse<T>(
        data: parsedData,
        statusCode: response.statusCode,
      );
    } catch (e) {
      throw HtpioError('Request failed: $e');
    }
  }

  void cancel() => _cancelled = true;
}
