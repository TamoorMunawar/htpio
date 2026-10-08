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

  Future<void> beforeRequest(HtpioRequest request) async {}

  Future<void> afterResponse(HtpioResponse response) async {}

  /// Called once a request has finally failed (after interceptors).
  Future<void> onError(HtpioError error) async {}
}
