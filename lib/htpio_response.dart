import 'htpio_request.dart';

/// A completed HTTP response.
class HtpioResponse<T> {
  /// Creates a response. htpio builds these for you; create one yourself in
  /// interceptors or tests.
  HtpioResponse({
    required this.data,
    required this.statusCode,
    Map<String, String>? headers,
    this.request,
    this.reasonPhrase,
  }) : headers = headers ?? const {};

  /// Builds a response from a JSON map, reading `status_code` (default 200).
  factory HtpioResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return HtpioResponse<T>(
      data: fromJson(json),
      statusCode: json['status_code'] as int? ?? 200,
    );
  }

  /// The response body: decoded JSON, a `String`, bytes, or the object built
  /// by `fromJson`/`decoder`.
  final T data;

  /// HTTP status code, e.g. `200`.
  final int statusCode;

  /// Response headers. Keys are lower-case.
  final Map<String, String> headers;

  /// The request that produced this response.
  final HtpioRequest? request;

  /// Status text sent by the server, e.g. `OK`.
  final String? reasonPhrase;

  /// `true` for status codes 200–299.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  String toString() => 'HtpioResponse($statusCode, data: $data)';
}
