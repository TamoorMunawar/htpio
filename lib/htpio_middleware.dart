import 'htpio_client.dart';
import 'htpio_error.dart';
import 'htpio_request.dart';
import 'htpio_response.dart';

/// Hooks that observe every request: logging, timing, analytics, offline
/// checks. Throwing from [beforeRequest] stops the request.
///
/// Use an `HtpioInterceptor` instead when you need to change the request or
/// response.
///
/// ```dart
/// class TimingMiddleware extends HtpioMiddleware {
///   final _watch = Stopwatch();
///   @override
///   Future<void> beforeRequest(HtpioRequest request) async => _watch..reset()..start();
///   @override
///   Future<void> afterResponse(HtpioResponse response) async =>
///       print('took ${_watch.elapsedMilliseconds} ms');
/// }
///
/// htpio.use(TimingMiddleware());
/// ```
abstract class HtpioMiddleware {
  /// The client this middleware was added to. Set by `HtpioClient.use`.
  HtpioClient? client;

  /// Called before each request is sent. Throw to stop the request.
  Future<void> beforeRequest(HtpioRequest request) async {}

  /// Called after each successful response.
  Future<void> afterResponse(HtpioResponse response) async {}

  /// Called once a request has finally failed (after interceptors).
  Future<void> onError(HtpioError error) async {}
}
