import 'dart:developer' as developer;

import '../../htpio_error.dart';
import '../../htpio_request.dart';
import '../../htpio_response.dart';
import 'interceptor.dart';

/// Prints requests, responses and errors. Sensitive headers are hidden.
///
/// ```dart
/// htpio.addInterceptor(HtpioLogInterceptor(responseBody: true));
/// ```
class HtpioLogInterceptor extends HtpioInterceptor {
  /// Creates a logger. Only the request line and status are printed unless
  /// you enable more.
  HtpioLogInterceptor({
    this.requestHeaders = false,
    this.requestBody = false,
    this.responseHeaders = false,
    this.responseBody = false,
    this.logPrint = _defaultPrint,
    this.hiddenHeaders = const {'authorization', 'cookie', 'set-cookie'},
  });

  /// Print request headers.
  final bool requestHeaders;

  /// Print the request body.
  final bool requestBody;

  /// Print response headers.
  final bool responseHeaders;

  /// Print the response body.
  final bool responseBody;

  /// Where log lines go. Defaults to `dart:developer` `log`.
  final void Function(String line) logPrint;

  /// Header names (lower-case) whose values are replaced by `***`.
  final Set<String> hiddenHeaders;

  static void _defaultPrint(String line) => developer.log(line, name: 'htpio');

  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    logPrint('--> ${request.method} ${request.uri}');
    if (requestHeaders) _logHeaders(request.headers);
    if (requestBody && request.body != null) logPrint('${request.body}');
    return request;
  }

  @override
  Future<HtpioResponse> onResponse(HtpioResponse response) async {
    final req = response.request;
    logPrint(
        '<-- ${response.statusCode} ${req?.method ?? ''} ${req?.uri ?? ''}');
    if (responseHeaders) _logHeaders(response.headers);
    if (responseBody) logPrint('${response.data}');
    return response;
  }

  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async {
    logPrint('<-- ERROR ${request.method} ${request.uri}: $error');
    if (responseBody && error.response != null) {
      logPrint('${error.response!.data}');
    }
    throw error;
  }

  void _logHeaders(Map<String, String> headers) {
    headers.forEach((key, value) {
      final shown = hiddenHeaders.contains(key.toLowerCase()) ? '***' : value;
      logPrint('$key: $shown');
    });
  }
}
