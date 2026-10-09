import '../../htpio_client.dart';
import '../../htpio_error.dart';
import '../../htpio_request.dart';
import '../../htpio_response.dart';

/// Changes requests and responses, or recovers from errors.
///
/// * [onRequest] runs before sending, in the order interceptors were added.
/// * [onResponse] runs after a successful response, in reverse order.
/// * [onError] runs when a request fails. Return a response to recover, or
///   throw (the default) to pass the error on to the next interceptor.
///
/// ```dart
/// class ApiKeyInterceptor extends HtpioInterceptor {
///   @override
///   Future<HtpioRequest> onRequest(HtpioRequest request) async {
///     request.headers['x-api-key'] = 'secret';
///     return request;
///   }
/// }
/// ```
abstract class HtpioInterceptor {
  /// The client this interceptor was added to. Set by
  /// `HtpioClient.addInterceptor`; use it to re-send a request.
  HtpioClient? client;

  /// Called before the request is sent. Change and return [request].
  Future<HtpioRequest> onRequest(HtpioRequest request) async => request;

  /// Called with each successful response. Change and return [response].
  Future<HtpioResponse> onResponse(HtpioResponse response) async => response;

  /// Called when the request fails. Return a response to recover, or throw
  /// to pass the error on.
  Future<HtpioResponse> onError(HtpioError error, HtpioRequest request) async =>
      throw error;
}
