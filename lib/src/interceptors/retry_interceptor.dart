import 'dart:async';
import 'dart:math';

import '../../htpio_client.dart';
import '../../htpio_error.dart';
import '../../htpio_request.dart';
import '../../htpio_response.dart';
import 'interceptor.dart';

/// Retries failed requests with exponential backoff.
///
/// Retries timeouts, connection errors and the [retryableStatusCodes].
/// Only [retryMethods] are retried (idempotent methods by default) so a POST
/// is never sent twice unless you allow it.
///
/// ```dart
/// htpio.addInterceptor(RetryInterceptor(maxRetries: 3));
/// ```
class RetryInterceptor extends HtpioInterceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.useExponentialBackoff = true,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryMethods = const {'GET', 'HEAD', 'PUT', 'DELETE', 'OPTIONS'},
    this.retryIf,
  });

  final int maxRetries;

  /// Wait before the first retry. Doubles each attempt when
  /// [useExponentialBackoff] is `true`.
  final Duration baseDelay;

  final bool useExponentialBackoff;

  final List<int> retryableStatusCodes;

  /// HTTP methods that may be retried. Add `'POST'` only for idempotent APIs.
  final Set<String> retryMethods;

  /// Custom rule. When set, it replaces the built-in checks.
  final bool Function(HtpioError error)? retryIf;

  static const _attemptKey = 'htpio_retry_attempt';
  final Random _random = Random();

  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async {
    final attempt = (request.extra[_attemptKey] as int?) ?? 0;
    final owner = client;
    if (owner == null ||
        attempt >= maxRetries ||
        !shouldRetry(error, request)) {
      throw error;
    }

    await Future<void>.delayed(delayFor(attempt + 1));
    if (request.isCancelled) throw error;

    return owner.send(
      request.copyWith(extra: {
        ...request.extra,
        _attemptKey: attempt + 1,
        HtpioClient.resendKey: true,
      }),
    );
  }

  /// Whether [error] for [request] should be retried.
  bool shouldRetry(HtpioError error, HtpioRequest request) {
    if (error.type == HtpioErrorType.cancel) return false;
    if (!retryMethods.contains(request.method.toUpperCase())) return false;
    if (retryIf != null) return retryIf!(error);
    switch (error.type) {
      case HtpioErrorType.timeout:
      case HtpioErrorType.connectionError:
        return true;
      case HtpioErrorType.badResponse:
        return retryableStatusCodes.contains(error.statusCode);
      default:
        return false;
    }
  }

  /// Wait time before retry number [attempt] (1-based).
  Duration delayFor(int attempt) {
    if (!useExponentialBackoff) return baseDelay * attempt;
    final ms = baseDelay.inMilliseconds * pow(2, attempt - 1);
    final jitter = _random.nextDouble() * 0.1 * ms;
    return Duration(milliseconds: (ms + jitter).round());
  }
}
