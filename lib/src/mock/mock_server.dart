// File: lib/src/mock/mock_server.dart

import '../../htpio_response.dart';

class MockServer {
  final Map<String, HtpioResponse> _mocks = {};

  void registerMock(String url, dynamic data, {int statusCode = 200}) {
    _mocks[url] = HtpioResponse(data: data, statusCode: statusCode);
  }

  HtpioResponse? getMock(String url) => _mocks[url];
}
