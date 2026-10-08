import 'dart:async';

import '../../htpio_client.dart';
import '../../htpio_error.dart';
import '../../htpio_request.dart';
import '../../htpio_response.dart';
import 'interceptor.dart';

/// Adds an auth header to every request and, optionally, refreshes an
/// expired token on `401` and retries once.
///
/// ```dart
/// final auth = AuthTokenInterceptor(
///   token: savedToken,
///   onRefreshToken: () async => (await api.refresh()).accessToken,
/// );
/// htpio.addInterceptor(auth);
///
/// auth.setToken(newToken); // after login
/// auth.clearToken();       // after logout
/// ```
class AuthTokenInterceptor extends HtpioInterceptor {
  AuthTokenInterceptor({
    String? token,
    String headerName = 'Authorization',
    String tokenPrefix = 'Bearer',
    this.tokenProvider,
    this.onRefreshToken,
    this.refreshStatusCodes = const [401],
  })  : _token = token,
        _headerName = headerName,
        _tokenPrefix = tokenPrefix;

  String? _token;
  final String _headerName;
  final String _tokenPrefix;

  /// Reads the token for each request, e.g. from secure storage. Used when
  /// no token was set with [setToken].
  final FutureOr<String?> Function()? tokenProvider;

  /// Returns a new token after the server rejected the current one. Return
  /// `null` to give up (the original error is thrown).
  final Future<String?> Function()? onRefreshToken;

  final List<int> refreshStatusCodes;

  static const _retriedKey = 'htpio_auth_retried';
  Future<String?>? _refreshing;

  String? get token => _token;

  void setToken(String? token) => _token = token;

  void clearToken() => _token = null;

  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    final value = _token ?? await tokenProvider?.call();
    if (value != null && value.isNotEmpty) {
      request.headers[_headerName] =
          _tokenPrefix.isNotEmpty ? '$_tokenPrefix $value' : value;
    }
    return request;
  }

  @override
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async {
    final owner = client;
    if (owner == null ||
        onRefreshToken == null ||
        request.extra[_retriedKey] == true ||
        !refreshStatusCodes.contains(error.statusCode)) {
      throw error;
    }

    // Share one refresh between requests that fail at the same time.
    final refresh = _refreshing ??= onRefreshToken!().whenComplete(() {
      _refreshing = null;
    });
    final newToken = await refresh;
    if (newToken == null || newToken.isEmpty) throw error;
    _token = newToken;

    return owner.send(
      request.copyWith(extra: {
        ...request.extra,
        _retriedKey: true,
        HtpioClient.resendKey: true,
      }),
    );
  }
}
