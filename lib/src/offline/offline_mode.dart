import 'dart:async';

import '../../htpio_error.dart';
import '../../htpio_middleware.dart';
import '../../htpio_request.dart';
import '../utils/connectivity_helper.dart';

/// Queues requests while the device is offline and sends them again when
/// the connection returns.
///
/// ```dart
/// final offline = OfflineMode();
/// htpio.use(offline);
///
/// offline.connectivityStream.listen((online) => print('online: $online'));
/// ```
///
/// While offline, requests fail fast with an `HtpioError` of type
/// `HtpioErrorType.offline`. Requests whose method is in [queueMethods] are
/// kept and replayed through the client (interceptors included) once
/// online. Results of replayed requests are reported on [replayResults].
class OfflineMode extends HtpioMiddleware {
  /// Starts watching connectivity right away.
  OfflineMode({
    this.checkInterval = const Duration(seconds: 5),
    Future<bool> Function()? connectivityChecker,
    this.queueMethods = const {'POST', 'PUT', 'PATCH', 'DELETE'},
    this.maxQueueSize = 100,
  }) : _check = connectivityChecker ?? ConnectivityHelper.isOnline {
    _timer = Timer.periodic(checkInterval, (_) => refresh());
    unawaited(refresh());
  }

  /// How often connectivity is checked.
  final Duration checkInterval;

  /// HTTP methods kept for replay. GET requests are usually just retried by
  /// the UI, so they are not queued by default.
  final Set<String> queueMethods;

  /// Requests beyond this many are not queued.
  final int maxQueueSize;

  final Future<bool> Function() _check;
  final List<HtpioRequest> _queue = [];
  final StreamController<bool> _connectivity = StreamController.broadcast();
  final StreamController<Object> _replays = StreamController.broadcast();
  Timer? _timer;
  bool _isOnline = true;
  bool _flushing = false;

  /// Emits `true` when the device comes back online and `false` when it
  /// goes offline.
  Stream<bool> get connectivityStream => _connectivity.stream;

  /// Emits the `HtpioResponse` or `HtpioError` of each replayed request.
  Stream<Object> get replayResults => _replays.stream;

  /// Result of the latest connectivity check.
  bool get isOnline => _isOnline;

  /// Number of requests waiting to be replayed.
  int get queuedRequestsCount => _queue.length;

  /// Checks connectivity now and replays the queue when back online.
  Future<void> refresh() async {
    final wasOnline = _isOnline;
    bool online;
    try {
      online = await _check();
    } catch (_) {
      online = false;
    }
    if (_connectivity.isClosed) return;
    _isOnline = online;
    if (!wasOnline && online) {
      _connectivity.add(true);
      await _flushQueue();
    } else if (wasOnline && !online) {
      _connectivity.add(false);
    }
  }

  @override
  Future<void> beforeRequest(HtpioRequest request) async {
    if (_isOnline) return;
    final queued = queueMethods.contains(request.method.toUpperCase()) &&
        _queue.length < maxQueueSize;
    if (queued) _queue.add(request);
    throw HtpioError(
      queued
          ? 'Device is offline - request queued for later execution'
          : 'Device is offline',
      type: HtpioErrorType.offline,
      request: request,
    );
  }

  Future<void> _flushQueue() async {
    final owner = client;
    if (_flushing || _queue.isEmpty || owner == null) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty && _isOnline) {
        final request = _queue.removeAt(0);
        if (request.isCancelled) continue;
        try {
          final response = await owner.send(request);
          if (!_replays.isClosed) _replays.add(response);
        } catch (e) {
          if (!_replays.isClosed) _replays.add(e);
        }
      }
    } finally {
      _flushing = false;
    }
  }

  /// Drops all queued requests.
  void clearQueue() => _queue.clear();

  /// Replays queued requests now if online.
  Future<void> retryQueuedRequests() async {
    if (_isOnline) await _flushQueue();
  }

  /// Stops checking connectivity and closes the streams.
  void dispose() {
    _timer?.cancel();
    _connectivity.close();
    _replays.close();
    _queue.clear();
  }
}
