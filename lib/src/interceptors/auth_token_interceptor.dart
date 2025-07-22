// File: lib/src/interceptors/auth_token_interceptor.dart
import 'interceptor.dart';
import 'package:htpio/htpio_request.dart';

class AuthTokenInterceptor extends HtpioInterceptor {
  String? token;

  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }
}
