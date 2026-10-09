// Platform abstraction. Everything that needs `dart:io` lives behind this
// conditional export so the rest of htpio compiles on the web.
export 'platform_io.dart' if (dart.library.js_interop) 'platform_web.dart';
