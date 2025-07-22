// File: test/htpio_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:htpio/htpio.dart';

void main() {
  group('Htpio Core', () {
    test('should return a mock response', () async {
      final mock = MockServer();
      mock.registerMock('https://mock.io/test', 'mocked data');

      final response = mock.getMock('https://mock.io/test');
      expect(response?.data, 'mocked data');
    });

    test('cache should store and retrieve response', () {
      final cache = HtpioCache();
      final response = HtpioResponse(data: 'hello', statusCode: 200);
      cache.set('key', response);

      final cached = cache.get<String>('key');
      expect(cached?.data, 'hello');
    });

    test('error should wrap message correctly', () {
      final error = HtpioError.from('Something went wrong');
      expect(error.toString(), contains('Something went wrong'));
    });
  });
}
