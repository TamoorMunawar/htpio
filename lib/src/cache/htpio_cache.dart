// File: lib/src/cache/htpio_cache.dart

import 'package:htpio/htpio_response.dart';

class HtpioCache {
  final Map<String, HtpioResponse> _memoryCache = {};

  HtpioResponse<T>? get<T>(String key) {
    final res = _memoryCache[key];
    if (res is HtpioResponse<T>) return res;
    return null;
  }

  void set<T>(String key, HtpioResponse<T> response) {
    _memoryCache[key] = response;
  }

  void clear() => _memoryCache.clear();
}
