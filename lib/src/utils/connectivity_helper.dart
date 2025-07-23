import 'dart:io';
import 'dart:async';

class ConnectivityHelper {
  static const Duration _defaultTimeout = Duration(seconds: 5);
  static const String _defaultHost = 'google.com';
  static const int _defaultPort = 53;

  /// Check if the device is connected to the internet
  static Future<bool> isOnline({
    String host = _defaultHost,
    int port = _defaultPort,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Check connectivity with multiple hosts for better reliability
  static Future<bool> isOnlineReliable({
    List<String> hosts = const ['google.com', 'cloudflare.com', '8.8.8.8'],
    Duration timeout = _defaultTimeout,
  }) async {
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host).timeout(timeout);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }

  /// Stream that emits online/offline status changes
  static Stream<bool> get onStatusChange {
    return Stream.periodic(
      const Duration(seconds: 5),
      (_) => isOnline(),
    ).asyncMap((future) => future).distinct();
  }

  /// Get network interface information
  static Future<List<NetworkInterface>> getNetworkInterfaces() async {
    try {
      return await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );
    } catch (_) {
      return [];
    }
  }

  /// Check if connected to WiFi (basic check)
  static Future<bool> isWiFiConnected() async {
    try {
      final interfaces = await getNetworkInterfaces();
      return interfaces.any((interface) => 
        interface.name.toLowerCase().contains('wlan') ||
        interface.name.toLowerCase().contains('wifi') ||
        interface.name.toLowerCase().contains('en0')
      );
    } catch (_) {
      return false;
    }
  }
}
