import 'package:flutter/material.dart';

/// Keeps the latest htpio log lines and shows them in an on-screen overlay.
///
/// Every `HtpioClient` writes its requests and errors here (never headers or
/// bodies, so no tokens leak).
///
/// ```dart
/// Stack(children: [MyApp(), DebugConsole().overlay()]);
/// ```
class DebugConsole {
  /// Lines kept in memory; older ones are dropped.
  static int maxLogs = 200;

  static final List<String> _logs = [];
  static final ValueNotifier<int> _version = ValueNotifier(0);

  void log(String message) {
    _logs.add('🧪 $message');
    if (_logs.length > maxLogs) _logs.removeRange(0, _logs.length - maxLogs);
    _version.value++;
  }

  List<String> getLogs() => List.unmodifiable(_logs);

  void clear() {
    _logs.clear();
    _version.value++;
  }

  /// A live overlay with the last [lines] log lines. Place it inside a
  /// `Stack`.
  Widget overlay({int lines = 5}) {
    return Positioned(
      bottom: 20,
      left: 10,
      right: 10,
      child: IgnorePointer(
        child: ValueListenableBuilder<int>(
          valueListenable: _version,
          builder: (context, _, __) => Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in _logs.reversed.take(lines))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      line,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
