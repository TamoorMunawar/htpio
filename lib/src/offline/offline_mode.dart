// File: lib/src/offline/offline_mode.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:htpio/htpio_middleware.dart';
import 'package:htpio/htpio_request.dart';

class OfflineMode extends HtpioMiddleware {
  final List<HtpioRequest> _queue = [];
  late final StreamSubscription _subscription;
  bool _isOnline = true;

  OfflineMode() {
    _subscription = Connectivity().onConnectivityChanged.listen((status) {
      _isOnline = status != ConnectivityResult.none;
      if (_isOnline) _flushQueue();
    });
  }

  // Flush the queued requests when the network is back
  void _flushQueue() async {
    final queue = List<HtpioRequest>.from(_queue);
    _queue.clear();
    for (final request in queue) {
      // Execute the request, the `fromJson` function is already part of the request
      await request.execute();  // No need to pass `fromJson` here
    }
  }

  // Queue requests when offline
  @override
  Future<void> beforeRequest(HtpioRequest request) async {
    if (!_isOnline) {
      _queue.add(request);
      throw Exception('Offline — request queued');
    }
  }

  // Dispose of the subscription when done
  void dispose() => _subscription.cancel();
}
