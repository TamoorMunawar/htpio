// File: lib/src/interceptors/interceptor.dart
import 'package:htpio/htpio_error.dart';
import 'package:htpio/htpio_request.dart';
import 'package:htpio/htpio_response.dart';

abstract class HtpioInterceptor {
  Future<HtpioRequest> onRequest(HtpioRequest request) async => request;
  Future<HtpioResponse> onResponse(HtpioResponse response) async => response;
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async =>
      throw error;
}
