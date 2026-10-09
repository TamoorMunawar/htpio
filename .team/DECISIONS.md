# Decisions

| # | Date | Decision | Reason | Owner |
|---|---|---|---|---|
| D-1 | 2026-10-08 | Transport = `package:http` (`http.Client`, injectable). Pure Flutter package: no `plugin:` block, no app platform folders. `dart:io` only behind conditional import `src/platform/`. | Runs on all 6 platforms incl. web; pub.dev tagged Android/iOS only before. | Senior A |
| D-2 | 2026-10-08 | Public API is dio-style: `HtpioClient(baseUrl:, headers:, timeout:)` + `get/post/put/patch/delete/head/request`. Legacy `getRequest`…`postSingleFileWithDataRequest` kept, `@Deprecated`. Release 1.2.0 (minor). | Easy adoption without breaking existing users. | Lead |
| D-3 | 2026-10-08 | Body encoding: `Map`/`List` → JSON; `FormData` → multipart; `String` → text; `List<int>` → bytes; form-urlencoded if that content-type is set. | Same rules users know from dio. | Lead |
| D-4 | 2026-10-08 | All failures throw `HtpioError` with `type` (`HtpioErrorType`), `statusCode`, `request`, `response`. Non-2xx throws `badResponse` unless `validateStatus` says otherwise. | Predictable error handling; retry needs status codes. | Lead |
| D-5 | 2026-10-08 | Interceptors/middleware get `client` set on `addInterceptor`/`use`. `onError` chain runs on every failure; returning a response recovers. Retry re-sends via `client.send` with attempt count in `request.extra`. | Retry/offline replay must go through the full pipeline. | Senior A |
| D-6 | 2026-10-08 | `HtpioClient(cache:, mockServer:)`. Cache used for GET when `cache: true` on the call. Mock short-circuits the network when enabled. | Features existed but were never connected. | Senior A |
| D-7 | 2026-10-08 | `CancelToken` aborts in-flight requests via `http.AbortableRequest` (http ≥1.5). | Real cancellation, not a flag. | Senior B |
| D-8 | 2026-10-08 | `OfflineMode` takes injectable `connectivityChecker`; queued requests replay through the client. | Testable; replays keep auth/interceptors. | Senior B |
