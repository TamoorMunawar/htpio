import 'package:flutter/material.dart';

class DebugConsole {
  static final List<String> _logs = [];

  void log(String message) => _logs.add('🧪 $message');
  List<String> getLogs() => List.unmodifiable(_logs);

  /// Overlay widget that you can drop into your app for live debugging.
  Widget overlay() {
    return Positioned(
      bottom: 20,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _logs.reversed.take(5).map((log) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                log,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
