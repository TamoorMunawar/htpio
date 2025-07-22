// File: lib/src/htpio_error.dart
class HtpioError implements Exception {
  final String message;
  final StackTrace? stackTrace;

  HtpioError(this.message, [this.stackTrace]);

  factory HtpioError.from(dynamic error) {
    if (error is HtpioError) return error;
    return HtpioError(error.toString());
  }

  @override
  String toString() => 'HtpioError: $message';
}
