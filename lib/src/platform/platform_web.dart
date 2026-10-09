import 'dart:async';
import 'dart:js_interop';

/// Whether the current platform can read and write files by path.
const bool supportsFileSystem = false;

@JS('navigator.onLine')
external bool get _navigatorOnLine;

/// On the web there is no DNS API, so the browser's online flag is used.
Future<bool> lookupHost(String host, Duration timeout) async {
  try {
    return _navigatorOnLine;
  } catch (_) {
    return true;
  }
}

/// Network interfaces are not visible to browser code.
Future<List<NetworkInterface>> listNetworkInterfaces() async => const [];

/// Web placeholder for `dart:io` `File`. Paths cannot be read on the web.
class File {
  File(this.path);

  final String path;
}

/// Web placeholder for `dart:io` `NetworkInterface`.
abstract class NetworkInterface {
  String get name;
}

/// Downloading to a file path is not possible on the web.
class FileTarget {
  FileTarget._();

  File get file => throw UnsupportedError(_message);

  static Future<FileTarget> open(String path) async =>
      throw UnsupportedError(_message);

  void add(List<int> bytes) => throw UnsupportedError(_message);

  Future<void> close() async {}

  Future<void> discard() async {}

  static const _message = 'Saving files to a path is not supported on the web. '
      'Use HtpioClient.get with responseType: ResponseType.bytes instead.';
}
