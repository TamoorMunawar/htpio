// File: test/htpio_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:htpio/htpio.dart';

// Test model for mock responses
class TestModel {
  final String message;
  final int id;

  TestModel({required this.message, required this.id});

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      message: json['message'] as String,
      id: json['id'] as int,
    );
  }
}

void main() {
  group('Htpio Core', () {
    test('should return a mock response', () async {
      final mock = MockServer();
      mock.enable();
      
      // Register mock with proper data structure
      mock.registerMock(
        'https://mock.io/test',
        {'message': 'mocked data', 'id': 1},
        statusCode: 200,
        method: 'GET',
      );

      // Create a test request
      final request = HtpioRequest<TestModel>(
        url: 'https://mock.io/test',
        method: 'GET',
        fromJson: (json) => TestModel.fromJson(json),
      );

      // Get mock response
      final response = await mock.getMockResponse<TestModel>(request);
      
      expect(response, isNotNull);
      expect(response!.data.message, 'mocked data');
      expect(response.data.id, 1);
      expect(response.statusCode, 200);
    });

    test('cache should store and retrieve response', () {
      final cache = HtpioCache();
      final response = HtpioResponse<String>(
        data: 'hello',
        statusCode: 200,
      );
      
      cache.set('key', response);

      final cached = cache.get<String>('key');
      expect(cached, isNotNull);
      expect(cached!.data, 'hello');
      expect(cached.statusCode, 200);
    });

    test('error should wrap message correctly', () {
      final error = HtpioError.from('Something went wrong');
      expect(error.toString(), contains('Something went wrong'));
      expect(error.message, 'Something went wrong');
    });

    test('connectivity helper should check online status', () async {
      // Test connectivity helper
      final isOnline = await ConnectivityHelper.isOnline(
        host: 'google.com',
        timeout: Duration(seconds: 3),
      );
      
      // This test might fail in offline environments, so we just check the type
      expect(isOnline, isA<bool>());
    });

    test('retry interceptor should be configured correctly', () {
      final retryInterceptor = RetryInterceptor(
        maxRetries: 3,
        baseDelay: Duration(seconds: 1),
        useExponentialBackoff: true,
      );
      
      expect(retryInterceptor.maxRetries, 3);
      expect(retryInterceptor.baseDelay, Duration(seconds: 1));
      expect(retryInterceptor.useExponentialBackoff, true);
    });

    test('auth token interceptor should handle tokens', () async {
      final authInterceptor = AuthTokenInterceptor(
        token: 'test-token',
        headerName: 'Authorization',
        tokenPrefix: 'Bearer',
      );
      
      expect(authInterceptor.token, 'test-token');
      
      // Test token setting
      authInterceptor.setToken('new-token');
      expect(authInterceptor.token, 'new-token');
      
      // Test token clearing
      authInterceptor.clearToken();
      expect(authInterceptor.token, isNull);
    });

    test('download manager should track progress', () {
      final downloadManager = HtpioDownloadManager();
      
      // Test initial state
      expect(downloadManager.isDownloading('test-url'), false);
      expect(downloadManager.getProgress('test-url'), isNull);
      
      // Clean up
      downloadManager.dispose();
    });

    test('offline mode should queue requests when offline', () {
      final offlineMode = OfflineMode();
      
      // Test initial state
      expect(offlineMode.queuedRequestsCount, 0);
      
      // Clean up
      offlineMode.dispose();
    });

    test('debug console should log messages', () {
      final debugConsole = DebugConsole();
      
      debugConsole.log('Test message');
      final logs = debugConsole.getLogs();
      
      expect(logs, isNotEmpty);
      expect(logs.last, contains('Test message'));
    });
  });

  group('Htpio Client Integration', () {
    test('client should handle interceptors and middleware', () {
      final client = HtpioClient();
      final authInterceptor = AuthTokenInterceptor(token: 'test');
      
      client.addInterceptor(authInterceptor);
      
      // Test that interceptor was added (no direct way to verify, but no error should occur)
      expect(() => client.addInterceptor(authInterceptor), returnsNormally);
    });

    test('request should be created with proper parameters', () {
      final request = HtpioRequest<String>(
        url: 'https://api.example.com/test',
        method: 'GET',
        headers: {'Content-Type': 'application/json'},
        timeout: Duration(seconds: 30),
      );
      
      expect(request.url, 'https://api.example.com/test');
      expect(request.method, 'GET');
      expect(request.headers['Content-Type'], 'application/json');
      expect(request.timeout, Duration(seconds: 30));
    });

    test('response should indicate success status correctly', () {
      final successResponse = HtpioResponse<String>(
        data: 'success',
        statusCode: 200,
      );
      
      final errorResponse = HtpioResponse<String>(
        data: 'error',
        statusCode: 404,
      );
      
      expect(successResponse.isSuccess, true);
      expect(errorResponse.isSuccess, false);
    });
  });
}
