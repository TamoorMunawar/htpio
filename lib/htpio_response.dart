class HtpioResponse<T> {
  final T data;
  final int statusCode;
  final Map<String, String>? headers;

  HtpioResponse({
    required this.data,
    required this.statusCode,
    this.headers,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  
  factory HtpioResponse.fromJson(
    Map<String, dynamic> json, 
    T Function(Map<String, dynamic>) fromJson
  ) {
    return HtpioResponse<T>(
      data: fromJson(json),
      statusCode: json['status_code'] ?? 200,
    );
  }
}
