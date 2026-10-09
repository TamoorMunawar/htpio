# Changelog

## 1.2.0

A big quality release. The API is easier, every advertised feature now works, and htpio runs on all six Flutter platforms. Existing 1.1.x code keeps compiling; see "Upgrading" in the README.

### Added
- Simple verbs: `get`, `post`, `put`, `patch`, `delete`, `head`, `request`.
- `HtpioClient(baseUrl:, headers:, queryParameters:, timeout:, validateStatus:, interceptors:, cache:, mockServer:, httpClient:)`.
- `queryParameters` on every request (lists repeat the key).
- Automatic body encoding: JSON, `FormData` multipart, text, bytes, form-urlencoded.
- `FormData` and `HtpioMultipartFile` (`fromPath`, `fromBytes`, `fromString`).
- `decoder` for lists or any response shape; `ResponseType.json` / `plain` / `bytes`.
- `CancelToken` that really aborts in-flight requests.
- `HtpioErrorType` on `HtpioError`, plus `error.request` and `error.response` (with the server's error body).
- `AuthTokenInterceptor`: `tokenProvider` and `onRefreshToken` (refresh on 401, retry once, shared refresh).
- `HtpioLogInterceptor` that hides `Authorization` and cookie headers.
- `RetryInterceptor`: `retryMethods` and `retryIf`.
- `OfflineMode`: `connectivityChecker`, `queueMethods`, `replayResults`, `refresh()`.
- `HtpioCache`: per-entry `ttl` and `maxEntries`.
- Web support (JS and WASM), plus macOS, Windows and Linux.

### Fixed
- 4xx and 5xx responses now throw `HtpioError` (type `badResponse`, with `statusCode`). Before, they returned as success.
- `RetryInterceptor` never ran, because interceptor `onError` was never called. Retries now go through the full pipeline.
- Middleware `onError` was never called.
- File uploads never sent the files, and set a `Content-Type` without a boundary.
- `HtpioCache` ignored the `ttl` argument.
- `HtpioCache` and `MockServer` were not connected to the client.
- Non-JSON responses crashed with a `FormatException`.
- Response headers were never filled in.
- `timeout` only limited connecting, not the whole request.
- The client logged request headers, including bearer tokens, to the console.
- `DebugConsole` kept logs forever. It now keeps the last `maxLogs` (200), and the overlay updates live.
- Download manager: cancelling left `downloadFile` waiting forever, errors could escape as unhandled exceptions, and partial files were not removed.
- `OfflineMode` replayed queued requests outside the client (no auth, results lost).

### Changed
- htpio is now a regular package instead of a plugin with no native code. The Android/iOS plugin stubs and example-app platform folders were removed.
- `RetryInterceptor` retries only idempotent methods by default (`GET, HEAD, PUT, DELETE, OPTIONS`). Add `'POST'` to `retryMethods` to retry posts.
- `OfflineMode` queues only `POST, PUT, PATCH, DELETE` by default, and other requests fail fast with `HtpioErrorType.offline`.
- `HtpioResponse.headers` is never null.
- `HtpioInterceptor` and `HtpioMiddleware` have a `client` field. Classes that `extends` them need no change; classes that `implements` them must add it.
- Uses `package:http` as the transport.

### Deprecated (removed in 2.0.0)
- `getRequest`, `postRequest`, `putRequest`, `deleteRequest`, `postFilesWithDataRequest`, `postSingleFileWithDataRequest`.
- `HtpioRequest.execute()`.

## 1.1.13
- Fix incorrect androidPackage and pluginClass path.

## 1.1.0 – 1.1.12
- Middleware, interceptors, offline mode, downloads, auth token, retry, cache, mock server and debug console.

## 1.0.0
- Initial release.
