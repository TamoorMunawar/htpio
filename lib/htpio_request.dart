// File: lib/src/htpio_request.dart
import 'htpio_response.dart';
import 'htpio_error.dart';

class HtpioRequest<T> {
  final String url;
  final String method;
  final dynamic body;
  final bool cacheEnabled;
  final Map<String, String> headers = {};
  Duration? timeout;
  bool _cancelled = false;

  HtpioRequest({
    required this.url,
    this.method = 'GET',
    this.body,
    this.cacheEnabled = false,
    this.timeout,
  });

  Future<HtpioResponse<T>> execute() async {
    if (_cancelled) throw HtpioError('Request was cancelled');

    final simulated = Future.delayed(Duration(milliseconds: 300), () {
      if (_cancelled) throw HtpioError('Request was cancelled');
      return HtpioResponse<T>(
        data: 'Simulated response for $url' as T,
        statusCode: 200,
      );
    });

    return timeout != null
        ? simulated.timeout(timeout!,
            onTimeout: () => throw HtpioError(
                'Request to $url timed out after ${timeout!.inSeconds}s'))
        : simulated;
  }

  void cancel() => _cancelled = true;
}
