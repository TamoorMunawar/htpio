// File: lib/src/htpio_error.dart
class HtpioError implements Exception {
  final String message;
  final int? statusCode;
  final StackTrace? stackTrace;
  final dynamic originalError;

  HtpioError(
    this.message, {
    this.statusCode,
    this.stackTrace,
    this.originalError,
  });

  factory HtpioError.from(dynamic error) {
    if (error is HtpioError) return error;
    return HtpioError(
      error.toString(),
      originalError: error,
    );
  }

  @override
  String toString() => 'HtpioError: $message';
}
