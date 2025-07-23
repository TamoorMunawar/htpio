import 'dart:async';
import 'dart:math';
import '../../htpio_error.dart';
import '../../htpio_request.dart';
import '../../htpio_response.dart';
import 'interceptor.dart';

class RetryInterceptor extends HtpioInterceptor {
  final int maxRetries;
  final Duration baseDelay;
  final bool useExponentialBackoff;
  final List<int> retryableStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.useExponentialBackoff = true,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async {
    // Only retry for specific error conditions
    if (!_shouldRetry(error)) {
      throw error;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final delay = _calculateDelay(attempt);
      await Future.delayed(delay);
      
      try {
        return await request.execute();
      } catch (e) {
        if (attempt == maxRetries) {
          throw HtpioError(
            'Request failed after $maxRetries retries: ${e.toString()}',
            originalError: e,
          );
        }
        // Continue to next retry attempt
      }
    }
    
    throw error;
  }

  bool _shouldRetry(HtpioError error) {
    // Retry on network errors or specific status codes
    if (error.statusCode != null) {
      return retryableStatusCodes.contains(error.statusCode);
    }
    
    // Retry on connection errors
    final message = error.message.toLowerCase();
    return message.contains('connection') ||
           message.contains('timeout') ||
           message.contains('network');
  }

  Duration _calculateDelay(int attempt) {
    if (useExponentialBackoff) {
      final exponentialDelay = baseDelay * pow(2, attempt - 1);
      // Add some jitter to prevent thundering herd
      final jitter = Random().nextDouble() * 0.1 * exponentialDelay.inMilliseconds;
      return Duration(milliseconds: exponentialDelay.inMilliseconds + jitter.round());
    }
    return baseDelay * attempt;
  }
}
