import 'dart:async';
import 'dart:io';

export 'dart:io' show File, NetworkInterface;

/// Whether the current platform can read and write files by path.
const bool supportsFileSystem = true;

/// Returns `true` when [host] resolves through DNS within [timeout].
Future<bool> lookupHost(String host, Duration timeout) async {
  try {
    final result = await InternetAddress.lookup(host).timeout(timeout);
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on Exception {
    return false;
  }
}

/// Lists non-loopback network interfaces, or an empty list on failure.
Future<List<NetworkInterface>> listNetworkInterfaces() async {
  try {
    return await NetworkInterface.list(includeLoopback: false);
  } on Exception {
    return const [];
  }
}

/// A sink that writes downloaded bytes to [path].
class FileTarget {
  FileTarget._(this.file, this._sink);

  /// The file being written.
  final File file;
  final IOSink _sink;

  /// Creates [path] (and its folders) for writing.
  static Future<FileTarget> open(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    return FileTarget._(file, file.openWrite());
  }

  /// Appends [bytes].
  void add(List<int> bytes) => _sink.add(bytes);

  /// Finishes writing.
  Future<void> close() => _sink.close();

  /// Closes the sink and removes the partial file.
  Future<void> discard() async {
    try {
      await _sink.close();
    } on Exception {
      // The sink may already be closed after a write error.
    }
    if (await file.exists()) await file.delete();
  }
}
