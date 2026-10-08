import 'dart:async';

/// Cancels one or more in-flight requests.
///
/// ```dart
/// final token = CancelToken();
/// htpio.get('/search', queryParameters: {'q': 'dart'}, cancelToken: token);
/// token.cancel('user typed again');
/// ```
class CancelToken {
  final Completer<void> _completer = Completer<void>();

  Object? _reason;

  /// Whether [cancel] has been called.
  bool get isCancelled => _completer.isCompleted;

  /// The value passed to [cancel].
  Object? get reason => _reason;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _completer.future;

  /// Aborts every request using this token. Calling it twice has no effect.
  void cancel([Object? reason]) {
    if (isCancelled) return;
    _reason = reason;
    _completer.complete();
  }
}
