import 'htpio_request.dart';
import 'htpio_response.dart';

/// What went wrong with a request.
enum HtpioErrorType {
  /// The request did not finish within its `timeout`.
  timeout,

  /// The server answered with a status code rejected by `validateStatus`
  /// (by default anything outside 200–299). See [HtpioError.response].
  badResponse,

  /// The request was cancelled with a `CancelToken`.
  cancel,

  /// The server could not be reached (DNS, socket, TLS or similar failure).
  connectionError,

  /// The device is offline and the request was queued by `OfflineMode`.
  offline,

  /// The response body could not be converted with `fromJson`/`decoder`.
  parse,

  /// Anything else. Check [HtpioError.originalError].
  unknown,
}

/// The only exception type thrown by htpio.
///
/// ```dart
/// try {
///   await htpio.get('/users/1');
/// } on HtpioError catch (e) {
///   print(e.type);          // HtpioErrorType.badResponse
///   print(e.statusCode);    // 404
///   print(e.response?.data); // error body sent by the server
/// }
/// ```
class HtpioError implements Exception {
  HtpioError(
    this.message, {
    this.statusCode,
    this.stackTrace,
    this.originalError,
    this.type = HtpioErrorType.unknown,
    this.request,
    this.response,
  });

  /// Wraps any thrown object in an [HtpioError]. Returns [error] unchanged
  /// when it already is one.
  factory HtpioError.from(Object? error, [StackTrace? stackTrace]) {
    if (error is HtpioError) return error;
    return HtpioError(
      error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Human readable description.
  final String message;

  /// HTTP status code, when the server answered.
  final int? statusCode;

  final StackTrace? stackTrace;

  /// The underlying exception, if any.
  final dynamic originalError;

  /// The category of this error.
  final HtpioErrorType type;

  /// The request that failed.
  final HtpioRequest? request;

  /// The server response for [HtpioErrorType.badResponse]. `data` holds the
  /// decoded error body.
  final HtpioResponse? response;

  /// Returns a copy with the given fields replaced.
  HtpioError copyWith({HtpioRequest? request, HtpioResponse? response}) {
    return HtpioError(
      message,
      statusCode: statusCode,
      stackTrace: stackTrace,
      originalError: originalError,
      type: type,
      request: request ?? this.request,
      response: response ?? this.response,
    );
  }

  @override
  String toString() {
    final status = statusCode != null ? ' [$statusCode]' : '';
    return 'HtpioError(${type.name})$status: $message';
  }
}
