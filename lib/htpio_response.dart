// File: lib/src/htpio_response.dart
class HtpioResponse<T> {
  final T data;
  final int statusCode;

  HtpioResponse({required this.data, required this.statusCode});

  // Add the fromJson method for deserialization
  factory HtpioResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return HtpioResponse<T>(
      data: fromJson(json),  // Deserialize data using the passed fromJson function
      statusCode: json['status_code'] ?? 200,  // Assuming status_code is in the JSON response
    );
  }
}
