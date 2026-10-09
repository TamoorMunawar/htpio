import '../../htpio_response.dart';

/// In-memory response cache with a time-to-live.
///
/// ```dart
/// final htpio = HtpioClient(cache: HtpioCache(defaultTtl: Duration(minutes: 5)));
/// await htpio.get('/products', cache: true); // network
/// await htpio.get('/products', cache: true); // served from memory
/// ```
class HtpioCache {
  /// Creates a cache. Entries live for [defaultTtl] unless `set` is given a
  /// `ttl`.
  HtpioCache({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxEntries = 100,
  });

  /// How long entries live when `set` is called without a `ttl`.
  final Duration defaultTtl;

  /// Oldest entries are evicted beyond this size.
  final int maxEntries;

  final Map<String, _Entry> _entries = {};

  /// Returns the cached response for [key], or `null` when missing, expired
  /// or of another type.
  HtpioResponse<T>? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    final response = entry.response;
    return response is HtpioResponse<T> ? response : null;
  }

  /// Stores [response] under [key] for [ttl] (or [defaultTtl]).
  void set<T>(String key, HtpioResponse<T> response, {Duration? ttl}) {
    _entries.remove(key);
    _entries[key] = _Entry(response, DateTime.now().add(ttl ?? defaultTtl));
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes the entry for [key].
  void remove(String key) => _entries.remove(key);

  /// Removes every entry.
  void clear() => _entries.clear();

  /// Whether [key] has an entry that has not expired.
  bool containsKey(String key) {
    final entry = _entries[key];
    return entry != null && !DateTime.now().isAfter(entry.expiresAt);
  }

  /// Number of stored entries, including expired ones not yet removed.
  int get size => _entries.length;
}

class _Entry {
  _Entry(this.response, this.expiresAt);

  final HtpioResponse response;
  final DateTime expiresAt;
}
