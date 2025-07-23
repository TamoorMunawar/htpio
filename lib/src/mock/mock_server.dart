// File: lib/src/mock/mock_server.dart

import '../../htpio_response.dart';
import '../../htpio_request.dart';


class MockServer {
  final Map<String, MockResponse> _mocks = {};
  final Map<String, List<MockResponse>> _sequentialMocks = {};
  final Map<String, int> _callCounts = {};
  bool _isEnabled = false;

  void enable() => _isEnabled = true;
  void disable() => _isEnabled = false;
  bool get isEnabled => _isEnabled;

  void registerMock(
    String url, 
    dynamic data, {
    int statusCode = 200,
    Map<String, String>? headers,
    Duration? delay,
    String method = 'GET',
  }) {
    final key = _createKey(method, url);
    _mocks[key] = MockResponse(
      data: data,
      statusCode: statusCode,
      headers: headers ?? {},
      delay: delay,
    );
  }

  void registerSequentialMocks(
    String url,
    List<MockResponse> responses, {
    String method = 'GET',
  }) {
    final key = _createKey(method, url);
    _sequentialMocks[key] = List.from(responses);
    _callCounts[key] = 0;
  }

  Future<HtpioResponse<T>?> getMockResponse<T>(
    HtpioRequest<T> request
  ) async {
    if (!_isEnabled) return null;
    
    final key = _createKey(request.method, request.url);
    
    // Check sequential mocks first
    if (_sequentialMocks.containsKey(key)) {
      final responses = _sequentialMocks[key]!;
      final callCount = _callCounts[key] ?? 0;
      
      if (callCount < responses.length) {
        _callCounts[key] = callCount + 1;
        final mockResponse = responses[callCount];
        
        if (mockResponse.delay != null) {
          await Future.delayed(mockResponse.delay!);
        }
        
        T parsedData;
        if (request.fromJson != null) {
          if (mockResponse.data is Map<String, dynamic>) {
            parsedData = request.fromJson!(mockResponse.data);
          } else {
            parsedData = request.fromJson!({'data': mockResponse.data});
          }
        } else {
          parsedData = mockResponse.data as T;
        }
        
        return HtpioResponse<T>(
          data: parsedData,
          statusCode: mockResponse.statusCode,
          headers: mockResponse.headers,
        );
      }
    }
    
    // Check regular mocks
    final mockResponse = _mocks[key];
    if (mockResponse != null) {
      if (mockResponse.delay != null) {
        await Future.delayed(mockResponse.delay!);
      }
      
      T parsedData;
      if (request.fromJson != null) {
        if (mockResponse.data is Map<String, dynamic>) {
          parsedData = request.fromJson!(mockResponse.data);
        } else {
          parsedData = request.fromJson!({'data': mockResponse.data});
        }
      } else {
        parsedData = mockResponse.data as T;
      }
      
      return HtpioResponse<T>(
        data: parsedData,
        statusCode: mockResponse.statusCode,
        headers: mockResponse.headers,
      );
    }
    
    return null;
  }

  void clearMocks() {
    _mocks.clear();
    _sequentialMocks.clear();
    _callCounts.clear();
  }

  void removeMock(String url, {String method = 'GET'}) {
    final key = _createKey(method, url);
    _mocks.remove(key);
    _sequentialMocks.remove(key);
    _callCounts.remove(key);
  }

  String _createKey(String method, String url) => '${method.toUpperCase()}:$url';
}

class MockResponse {
  final dynamic data;
  final int statusCode;
  final Map<String, String> headers;
  final Duration? delay;

  MockResponse({
    required this.data,
    this.statusCode = 200,
    this.headers = const {},
    this.delay,
  });
}
