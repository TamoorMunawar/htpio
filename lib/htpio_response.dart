import 'htpio_request.dart';

/// A completed HTTP response.
class HtpioResponse<T> {
  HtpioResponse({
    required this.data,
    required this.statusCode,
    Map<String, String>? headers,
    this.request,
    this.reasonPhrase,
  }) : headers = headers ?? const {};

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
