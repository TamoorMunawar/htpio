import 'interceptor.dart';
import '../../htpio_request.dart';

class AuthTokenInterceptor extends HtpioInterceptor {
  String? _token;
  String _headerName;
  String _tokenPrefix;

  AuthTokenInterceptor({
    String? token,
    String headerName = 'Authorization',
    String tokenPrefix = 'Bearer',
  }) : _token = token,
       _headerName = headerName,
       _tokenPrefix = tokenPrefix;

  String? get token => _token;
  
  void setToken(String? token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    if (_token != null && _token!.isNotEmpty) {
      final tokenValue = _tokenPrefix.isNotEmpty ? '$_tokenPrefix $_token' : _token!;
      request.headers[_headerName] = tokenValue;
    }
    return request;
  }
}
