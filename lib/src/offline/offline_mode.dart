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

  void _flushQueue() async {
    final queue = List<HtpioRequest>.from(_queue);
    _queue.clear();
    for (final request in queue) {
      await request.execute();
    }
  }

  @override
  Future<void> beforeRequest(HtpioRequest request) async {
    if (!_isOnline) {
      _queue.add(request);
      throw Exception('Offline — request queued');
    }
  }

  void dispose() => _subscription.cancel();
}
