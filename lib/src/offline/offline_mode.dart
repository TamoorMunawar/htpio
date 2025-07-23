import 'dart:async';
import 'dart:io';
import '../../htpio_middleware.dart';
import '../../htpio_request.dart';
import '../../htpio_error.dart';

class OfflineMode extends HtpioMiddleware {
  final List<HtpioRequest> _queue = [];
  final StreamController<bool> _connectivityController = StreamController.broadcast();
  Timer? _connectivityTimer;
  bool _isOnline = true;
  final Duration checkInterval;

  OfflineMode({this.checkInterval = const Duration(seconds: 5)}) {
    _startConnectivityCheck();
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;
  int get queuedRequestsCount => _queue.length;

  void _startConnectivityCheck() {
    _connectivityTimer = Timer.periodic(checkInterval, (_) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkConnectivity();
      
      if (!wasOnline && _isOnline) {
        // Just came back online
        _connectivityController.add(true);
        await _flushQueue();
      } else if (wasOnline && !_isOnline) {
        // Just went offline
        _connectivityController.add(false);
      }
    });
  }

  Future<bool> _checkConnectivity() async {
    try {
      // Try to connect to a reliable host
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _flushQueue() async {
    if (_queue.isEmpty) return;
    
    final queue = List<HtpioRequest>.from(_queue);
    _queue.clear();
    
    for (final request in queue) {
      try {
        await request.execute();
      } catch (e) {

      }
    }
  }

  @override
  Future<void> beforeRequest(HtpioRequest request) async {
    if (!_isOnline) {
      _queue.add(request);
      throw HtpioError('Device is offline - request queued for later execution');
    }
  }

  void clearQueue() {
    _queue.clear();
  }

  Future<void> retryQueuedRequests() async {
    if (_isOnline) {
      await _flushQueue();
    }
  }

  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
    _queue.clear();
  }
}
