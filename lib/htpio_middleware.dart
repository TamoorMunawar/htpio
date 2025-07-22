// File: lib/src/htpio_middleware.dart
import 'htpio_error.dart';
import 'htpio_request.dart';
import 'htpio_response.dart';

abstract class HtpioMiddleware {
  Future<void> beforeRequest(HtpioRequest request) async {}
  Future<void> afterResponse(HtpioResponse response) async {}
  Future<void> onError(HtpioError error) async {}
}
