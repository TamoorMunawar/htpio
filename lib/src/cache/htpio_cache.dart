import '../../htpio_response.dart';

class HtpioCache {
  final Map<String, HtpioResponse> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration defaultTtl;

  HtpioCache({this.defaultTtl = const Duration(minutes: 5)});

  HtpioResponse<T>? get<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) > defaultTtl) {
      // Cache expired
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    final res = _memoryCache[key];
    if (res is HtpioResponse<T>) return res;
    return null;
  }

  void set<T>(String key, HtpioResponse<T> response, {Duration? ttl}) {
    _memoryCache[key] = response;
    _cacheTimestamps[key] = DateTime.now();
  }

  void remove(String key) {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  void clear() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  bool containsKey(String key) => _memoryCache.containsKey(key);
  
  int get size => _memoryCache.length;
}
