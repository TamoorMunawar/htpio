# Patterns

- **Platform split**: `lib/src/platform/platform.dart` conditionally exports `platform_io.dart` / `platform_web.dart`. Any `dart:io` need goes there, nowhere else.
- **Testing without network**: inject `MockClient` from `package:http/testing.dart` via `HtpioClient(httpClient: ...)`.
- **Re-sending a request** from an interceptor/middleware: `client!.send(request.copyWith(...))`.
- **Errors**: always `throw HtpioError(msg, type: ..., request: ..., response: ...)`; wrap unknowns with `HtpioError.from(e, st)`.
- **Re-sends must set** `HtpioClient.resendKey: true` in `extra` so middleware `onError` reports once.
- **Typed results through interceptors**: the client re-types untyped responses (`_retype`); interceptors may return `HtpioResponse<dynamic>` safely.
- **Ownership**: only close an `http.Client` you created (see `HtpioDownloadManager._ownsClient`).
