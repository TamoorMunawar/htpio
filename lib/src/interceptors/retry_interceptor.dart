// File: lib/src/interceptors/retry_interceptor.dart
import 'dart:async';
import 'package:htpio/htpio_error.dart';
import 'package:htpio/htpio_request.dart';
import 'package:htpio/htpio_response.dart';

import 'interceptor.dart';

class RetryInterceptor extends HtpioInterceptor {
  final int maxRetries;
  final Duration delay;

  RetryInterceptor(
      {this.maxRetries = 3, this.delay = const Duration(seconds: 1)});

  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      await Future.delayed(delay * attempt);
      try {
        return await request.execute();
      } catch (_) {}
    }
    throw error;
  }
}
