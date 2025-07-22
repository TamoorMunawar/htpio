// File: lib/src/htpio_response.dart
class HtpioResponse<T> {
  final T data;
  final int statusCode;

  HtpioResponse({required this.data, required this.statusCode});
}
