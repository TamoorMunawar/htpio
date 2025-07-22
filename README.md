
# htpio ✨

`htpio` is the next-gen HTTP client for Flutter mobile apps and cross-platform Dart — designed to simplify networking, handle mobile-specific challenges, and boost developer productivity with a smile 😊

## 🌟 Features
- **Modular Middleware System**
- **In-App Debug Console** — like DevTools, but mobile
- **Smart Offline Mode** for flaky networks
- **Pause/Resume File Downloads**
- **Auto Auth Token Handling** — plug & play
- **Mobile-Friendly Error Middleware**
- **Typed Requests & Responses** ✅
- **Mock API Mode** for instant testing
- **Intelligent Retry with Backoff**
- **Caching, Timeout & Cancel**
- Built for Flutter — light, fast, joyful

## 🧠 Why `htpio`?

Other packages are great for basic requests, but `htpio` goes beyond:

- Designed for mobile realities (offline, errors, retries)
- Great DX with emoji-friendly debug UI
- Mock & test with ease

## 💻 Compatibility
- Flutter (iOS & Android)
- Dart CLI & Server

---

## 🌐 Example Code

### 1. API Request
```dart
htpio.config(
  baseUrl: 'https://api.coolapp.dev',
  headers: {'Accept': 'application/json'},
);

htpio.use(AuthTokenMiddleware());
htpio.use(DebugConsoleMiddleware());
````

### 2.1 Typed Request/Response

```dart
final result = await htpio.get<User>(
  '/profile',
  fromJson: (json) => User.fromJson(json),
);
```

### 2.2 Middleware System

Chainable and composable middlewares to inject logic before and after requests:

```dart
htpio.use(AuthTokenMiddleware());
htpio.use(RetryMiddleware(maxRetries: 3));
```

### 2.3 Smart Offline Mode

Automatically detects mobile network issues and queues requests for later if offline.

### 2.4 In-App Debug Console

Overlays HTTP logs directly in-app for real-time inspection:

```dart
DebugConsoleOverlay().attach(context);
```

### 2.5 File Download (Pause/Resume)

```dart
final downloader = htpio.download(
  url: 'https://example.com/largefile.zip',
  onProgress: (received, total) => print('$received / $total'),
);

await downloader.pause();
await downloader.resume();
```

### 2.6 Mock API Mode

```dart
htpio.enableMockMode({
  '/user': MockResponse(200, body: jsonEncode(mockUser)),
});
```

### 2.7 Global Interceptors

```dart
htpio.interceptors.add(RequestInterceptor(...));
htpio.interceptors.add(ResponseInterceptor(...));
```

### 2.8 Retry Policy

Supports exponential backoff with jitter for mobile network instability.

### 2.9 Timeout and Cancellation

```dart
final controller = CancelToken();
htpio.get('/long-request', cancelToken: controller);
controller.cancel();
```

### 2.10 Lightweight Caching

In-memory or persistent caching with TTL (Time-to-Live) support:

```dart
htpio.use(CachingMiddleware(ttl: Duration(minutes: 5)));
```

### 2.11 Mobile-Friendly Error Handling

```dart
htpio.use(ErrorHandlerMiddleware(onError: (e) => showErrorDialog(context, e.message)));
```

---

## 4. Package Description and Keywords

**Description:**

> `htpio` is a next-generation HTTP client tailored for Flutter and Dart. With smart offline support, mobile-optimized error handling, debug console, token automation, typed requests, and pause/resume downloads, `htpio` reimagines network communication for mobile.

**Tags / Keywords:**
`flutter`, `http`, `network`, `mobile`, `offline`, `debug`, `middleware`, `dio`, `typed`, `rest`, `auth`, `mock`, `file download`, `retry`, `dart`, `connectivity`, `caching`, `interceptor`

---

## 5. Developer Experience Goals

* Emoji-supported debug logging: `✈️ Request sent | ✅ 200 OK`
* Consistent builder syntax
* Safe and simple generics for JSON parsing
* Intuitive error messages like:

  > "🚫 Offline! We'll retry once you're back."
* UI integration (progress bars, file downloads)

---

## 6. Cross-Platform Compatibility

* Flutter SDK >= 3.10
* Dart SDK >= 3.0
* No native dependencies

---

## 7. Performance Considerations

* Zero-heavy dependencies
* Lazy initialization
* Efficient JSON parsing
* Queue system for offline retries
* Fine-grained caching controls

---

## 8. Future Roadmap

* GraphQL support
* Request/response recording for replay
* Auth providers (OAuth2, Firebase, etc)
* VS Code/Flutter DevTools plugin
* Network speed simulator for testing

---

## 9. License

MIT

---

## 10. Final Words

Your HTTP experience, reinvented. For mobile. With ❤️.

```dart
// One-liner for happiness
await htpio.get<User>('/user');
```

---



