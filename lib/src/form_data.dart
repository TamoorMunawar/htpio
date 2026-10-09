import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// A `multipart/form-data` body with text fields and files.
///
/// ```dart
/// final form = FormData.fromMap({
///   'name': 'avatar',
///   'file': HtpioMultipartFile.fromPath('/path/photo.jpg'),
/// });
/// await htpio.post('/upload', data: form);
/// ```
class FormData {
  /// Creates an empty form. Add to [fields] and [files], or use
  /// [FormData.fromMap].
  FormData();

  /// Builds a form from a map. [HtpioMultipartFile] values (or lists of them)
  /// become files; every other value is sent as text with `toString()`.
  factory FormData.fromMap(Map<String, dynamic> map) {
    final form = FormData();
    map.forEach((key, value) {
      if (value == null) return;
      if (value is HtpioMultipartFile) {
        form.files.add(MapEntry(key, value));
      } else if (value is Iterable &&
          value.every((v) => v is HtpioMultipartFile)) {
        for (final file in value) {
          form.files.add(MapEntry(key, file as HtpioMultipartFile));
        }
      } else {
        form.fields[key] = value.toString();
      }
    });
    return form;
  }

  /// Text fields.
  final Map<String, String> fields = {};

  /// Files, keyed by form field name. A field name may repeat.
  final List<MapEntry<String, HtpioMultipartFile>> files = [];

  /// Builds a fresh `http.MultipartRequest`-compatible file list. Files are
  /// re-read on each call, so the same [FormData] can be retried.
  Future<List<http.MultipartFile>> toMultipartFiles() {
    return Future.wait(files.map((e) => e.value.toMultipartFile(e.key)));
  }
}

/// A file to upload inside [FormData].
class HtpioMultipartFile {
  /// A file read from disk when the request is sent. Not available on web.
  HtpioMultipartFile.fromPath(String path, {this.filename, this.contentType})
      : _path = path,
        _bytes = null;

  /// A file built from bytes already in memory. Works on every platform.
  HtpioMultipartFile.fromBytes(List<int> bytes,
      {this.filename, this.contentType})
      : _bytes = bytes,
        _path = null;

  /// A text file.
  HtpioMultipartFile.fromString(String value, {this.filename, this.contentType})
      : _bytes = utf8.encode(value),
        _path = null;

  final String? _path;
  final List<int>? _bytes;

  /// File name sent to the server. Defaults to the path's base name.
  final String? filename;

  /// MIME type, e.g. `image/png`.
  final String? contentType;

  /// Converts this file to an `http.MultipartFile` for the form [field].
  Future<http.MultipartFile> toMultipartFile(String field) async {
    final type = contentType == null ? null : MediaType.parse(contentType!);
    if (_path != null) {
      return http.MultipartFile.fromPath(
        field,
        _path,
        filename: filename,
        contentType: type,
      );
    }
    return http.MultipartFile.fromBytes(
      field,
      _bytes!,
      filename: filename,
      contentType: type,
    );
  }
}
