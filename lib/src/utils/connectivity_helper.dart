// File: lib/src/utils/connectivity_helper.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  /// Check if the device is connected to the internet
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    // Correctly comparing single ConnectivityResult values
    return result != ConnectivityResult.none;
  }

  /// Stream that emits online/offline status changes
  static Stream<bool> get onStatusChange async* {
    // Listen for connectivity status changes and yield the appropriate boolean
    yield* Connectivity().onConnectivityChanged.map((result) {
      // Ensure we're comparing a single ConnectivityResult value, not a list
      return result != ConnectivityResult.none;
    });
  }
}
