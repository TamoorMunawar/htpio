import 'dart:async';

import '../platform/platform.dart';

/// Simple internet checks. On mobile and desktop a DNS lookup is used; on
/// the web the browser's online flag is used.
class ConnectivityHelper {
  static const Duration _defaultTimeout = Duration(seconds: 5);
  static const String _defaultHost = 'google.com';

  /// Whether the device can reach the internet.
  static Future<bool> isOnline({
    String host = _defaultHost,
    @Deprecated('Unused. Will be removed in 2.0.0.') int port = 53,
    Duration timeout = _defaultTimeout,
  }) {
    return lookupHost(host, timeout);
  }

  /// Like [isOnline] but tries several hosts.
  static Future<bool> isOnlineReliable({
    List<String> hosts = const [
      'google.com',
      'cloudflare.com',
      'one.one.one.one'
    ],
    Duration timeout = _defaultTimeout,
  }) async {
    for (final host in hosts) {
      if (await lookupHost(host, timeout)) return true;
    }
    return false;
  }

  /// Emits `true`/`false` whenever the online status changes, checking
  /// every [interval].
  static Stream<bool> watch({Duration interval = _defaultTimeout}) {
    return Stream<void>.periodic(interval)
        .asyncMap((_) => isOnline())
        .distinct();
  }

  /// Same as [watch] with a 5 second interval.
  static Stream<bool> get onStatusChange => watch();

  /// Network interfaces (empty on the web).
  static Future<List<NetworkInterface>> getNetworkInterfaces() =>
      listNetworkInterfaces();

  /// Rough Wi-Fi check based on interface names. Use the
  /// `connectivity_plus` package if you need an exact answer.
  static Future<bool> isWiFiConnected() async {
    final interfaces = await listNetworkInterfaces();
    return interfaces.any((i) {
      final name = i.name.toLowerCase();
      return name.contains('wlan') || name.contains('wifi') || name == 'en0';
    });
  }
}
