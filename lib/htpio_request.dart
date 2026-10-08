import 'htpio_client.dart';
import 'htpio_response.dart';
import 'src/cancel_token.dart';
import 'src/platform/platform.dart';

/// How the response body is decoded into `HtpioResponse.data`.
enum ResponseType {
  /// Decode JSON when possible, otherwise return the text. (default)
  json,

  /// Always return the body as a `String`.
  plain,

  /// Return the raw bytes as a `Uint8List`.
  bytes,
}

/// A single HTTP request. Usually created for you by `HtpioClient.get`,
/// `post` and friends; build one yourself only when calling `send`.
class HtpioRequest<T> {
  HtpioRequest({
    required this.url,
    this.method = 'GET',
    this.body,
    this.cacheEnabled = false,
    this.timeout,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    this.fromJson,
    this.decoder,
    this.file,
    this.files,
    this.fileField = 'file',
    this.responseType = ResponseType.json,
    CancelToken? cancelToken,
    this.validateStatus,
    Map<String, dynamic>? extra,
  })  : headers = headers ?? {},
        queryParameters = queryParameters ?? {},
        extra = extra ?? {},
        _cancelToken = cancelToken;

  /// Absolute URL, or a path that is joined to the client's `baseUrl`.
  final String url;

  /// HTTP method in upper case: GET, POST, PUT, PATCH, DELETE, HEAD…
  final String method;

  /// Request body. `Map`/`List`/objects with `toJson` are sent as JSON,
  /// `FormData` as multipart, `String` as text and `List<int>` as bytes.
  final dynamic body;

  /// Serve this GET from the client's `HtpioCache` when possible.
  final bool cacheEnabled;

  /// Total time allowed for this request. Overrides the client's timeout.
  Duration? timeout;

  /// Request headers. Interceptors may modify this map.
  final Map<String, String> headers;

  /// Query parameters appended to [url]. `Iterable` values repeat the key.
  final Map<String, dynamic> queryParameters;

  /// Builds `T` from a JSON object. A JSON array or primitive is passed as
  /// `{'data': value}`. Prefer [decoder] for lists.
  final T Function(Map<String, dynamic>)? fromJson;

  /// Builds `T` from the decoded body (`Map`, `List`, `String`…).
  final T Function(dynamic data)? decoder;

  /// Legacy single-file upload. Prefer `FormData`.
  final File? file;

  /// Legacy multi-file upload. Prefer `FormData`.
  final List<File>? files;

  /// Form field name used for [file] and [files].
  final String fileField;

  final ResponseType responseType;

  /// Accepts or rejects a status code. Rejected codes throw an `HtpioError`
  /// of type `badResponse`. Defaults to the client's rule (200–299).
  final bool Function(int statusCode)? validateStatus;

  /// Free-form values that travel with the request, for interceptors.
  final Map<String, dynamic> extra;

  CancelToken? _cancelToken;

  /// Token that aborts this request. Created on first access when none was
  /// passed in.
  CancelToken get cancelToken => _cancelToken ??= CancelToken();

  /// Whether [cancel] (or the token) cancelled this request.
  bool get isCancelled => _cancelToken?.isCancelled ?? false;

  /// The final URI including [queryParameters].
  Uri get uri {
    final base = Uri.parse(url);
    if (queryParameters.isEmpty) return base;
    final merged = <String, dynamic>{...base.queryParametersAll};
    queryParameters.forEach((key, value) {
      if (value == null) return;
      merged[key] = value is Iterable
          ? value.map((v) => v.toString()).toList()
          : value.toString();
    });
    return base.replace(queryParameters: merged);
  }

  /// Cancels the request.
  void cancel() => cancelToken.cancel();

  /// Sends this request with a temporary [HtpioClient].
  @Deprecated('Use HtpioClient().send(request). Will be removed in 2.0.0.')
  Future<HtpioResponse<T>> execute() async {
    final client = HtpioClient();
    try {
      return await client.send(this);
    } finally {
      client.close();
    }
  }

  /// Returns a copy with the given fields replaced. The cancel token is shared.
  HtpioRequest<T> copyWith({
    String? url,
    String? method,
    dynamic body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    Map<String, dynamic>? extra,
  }) {
    return HtpioRequest<T>(
      url: url ?? this.url,
      method: method ?? this.method,
      body: body ?? this.body,
      cacheEnabled: cacheEnabled,
      timeout: timeout ?? this.timeout,
      headers: {...(headers ?? this.headers)},
      queryParameters: {...(queryParameters ?? this.queryParameters)},
      fromJson: fromJson,
      decoder: decoder,
      file: file,
      files: files,
      fileField: fileField,
      responseType: responseType,
      cancelToken: cancelToken,
      validateStatus: validateStatus,
      extra: {...(extra ?? this.extra)},
    );
  }

  @override
  String toString() => 'HtpioRequest($method $url)';
}
