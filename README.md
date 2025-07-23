
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


# Tasks You Can Perform with the htpio Package

## 1. Basic HTTP Requests

You can perform all standard HTTP requests (GET, POST, PUT, DELETE) with type-safe responses:

```dart
// GET request example
final client = HtpioClient();
final response = await client.getRequest<List<Product>>(
  endpoint: 'https://api.example.com/products',
  fromJson: (json) => (json['data'] as List)
      .map((item) => Product.fromJson(item))
      .toList(),
);

// POST request example
final response = await client.postRequest<User>(
  endpoint: 'https://api.example.com/users',
  data: {'name': 'John', 'email': 'john@example.com'},
  fromJson: (json) => User.fromJson(json),
);
```

## 2. Authentication

You can handle authentication using the built-in token interceptor:

```dart
final authInterceptor = AuthTokenInterceptor(
  token: 'your-auth-token',  // Initial token
  headerName: 'Authorization',
  tokenPrefix: 'Bearer',
);

final client = HtpioClient();
client.addInterceptor(authInterceptor);

// Later, update the token
authInterceptor.setToken('new-token');

// Or clear it
authInterceptor.clearToken();
```

## 3. Request/Response Interception

You can intercept and modify requests and responses using interceptors:

```dart
class LoggingInterceptor extends HtpioInterceptor {
  @override
  Future<HtpioRequest> onRequest(HtpioRequest request) async {
    print('🚀 Request: ${request.method} ${request.url}');
    return request;
  }

  @override
  Future<HtpioResponse> onResponse(HtpioResponse response) async {
    print('✅ Response: ${response.statusCode}');
    return response;
  }
}

final client = HtpioClient();
client.addInterceptor(LoggingInterceptor());
```

## 4. Middleware for Request Processing

You can use middleware to process requests and responses:

```dart
class TimingMiddleware extends HtpioMiddleware {
  late DateTime _startTime;
  
  @override
  Future<void> beforeRequest(HtpioRequest request) async {
    _startTime = DateTime.now();
  }
  
  @override
  Future<void> afterResponse(HtpioResponse response) async {
    final duration = DateTime.now().difference(_startTime);
    print('Request took ${duration.inMilliseconds}ms');
  }
}

final client = HtpioClient();
client.use(TimingMiddleware());
```

## 5. Automatic Retry on Failure

You can automatically retry failed requests using the RetryInterceptor:

```dart
final retryInterceptor = RetryInterceptor(
  maxRetries: 3,
  baseDelay: Duration(seconds: 1),
  useExponentialBackoff: true,
  retryableStatusCodes: [408, 429, 500, 502, 503, 504],
);

final client = HtpioClient();
client.addInterceptor(retryInterceptor);
```

## 6. Response Caching

You can cache responses to reduce network requests:

```dart
final cache = HtpioCache(defaultTtl: Duration(minutes: 10));

// Check cache before making a request
String cacheKey = 'GET:https://api.example.com/data';
final cachedResponse = cache.get<MyData>(cacheKey);

if (cachedResponse != null) {
  return cachedResponse;
} else {
  final response = await client.getRequest<MyData>(...);
  cache.set(cacheKey, response);
  return response;
}
```

## 7. File Downloads with Progress Tracking

You can download files with progress tracking:

```dart
final downloadManager = HtpioDownloadManager();

// Listen to download progress
downloadManager.progressStream.listen((progress) {
  print('Download progress: ${(progress.progress * 100).toStringAsFixed(1)}%');
});

// Start a download
final file = await downloadManager.downloadFile(
  url: 'https://example.com/large-file.zip',
  savePath: '/path/to/save/file.zip',
  headers: {'Authorization': 'Bearer token'},
  onProgress: (progress) {
    // Update UI with progress
    setState(() {
      downloadProgress = progress;
    });
  },
);

// Pause, resume, or cancel downloads
downloadManager.pauseDownload('https://example.com/large-file.zip');
downloadManager.resumeDownload('https://example.com/large-file.zip');
downloadManager.cancelDownload('https://example.com/large-file.zip');
```

## 8. Mock Server for Testing

You can create mock responses for testing without actual network requests:

```dart
final mockServer = MockServer();
mockServer.enable();

// Register a mock response
mockServer.registerMock(
  'https://api.example.com/users',
  {'id': 1, 'name': 'Test User'},
  statusCode: 200,
  method: 'GET',
  delay: Duration(milliseconds: 300), // Simulate network delay
);

// Register sequential responses
mockServer.registerSequentialMocks(
  'https://api.example.com/status',
  [
    MockResponse(data: {'status': 'pending'}, statusCode: 200),
    MockResponse(data: {'status': 'processing'}, statusCode: 200),
    MockResponse(data: {'status': 'completed'}, statusCode: 200),
  ],
);
```

## 9. Offline Mode Support

You can queue requests when offline and execute them when back online:

```dart
final offlineMode = OfflineMode(checkInterval: Duration(seconds: 10));
final client = HtpioClient();
client.use(offlineMode);

// Listen to connectivity changes
offlineMode.connectivityStream.listen((isOnline) {
  print('Device is ${isOnline ? 'online' : 'offline'}');
});

// Check current status
if (offlineMode.isOnline) {
  print('Device is currently online');
} else {
  print('Device is currently offline');
  print('Queued requests: ${offlineMode.queuedRequestsCount}');
}

// Manually retry queued requests
await offlineMode.retryQueuedRequests();
```

## 10. Connectivity Monitoring

You can monitor network connectivity:

```dart
// Check if device is online
final isOnline = await ConnectivityHelper.isOnline();

// More reliable check with multiple hosts
final isReliablyOnline = await ConnectivityHelper.isOnlineReliable(
  hosts: ['google.com', 'cloudflare.com', '8.8.8.8'],
  timeout: Duration(seconds: 3),
);

// Listen to connectivity changes
ConnectivityHelper.onStatusChange.listen((isOnline) {
  print('Connection status changed: ${isOnline ? 'online' : 'offline'}');
});

// Check if connected to WiFi
final isWiFi = await ConnectivityHelper.isWiFiConnected();
```

## 11. Debugging Support

You can debug network requests with a visual console overlay:

```dart
final debugConsole = DebugConsole();
debugConsole.log('Starting network request...');

// In your Flutter widget tree
Overlay(
  initialEntries: [
    OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Your app UI
          YourAppWidget(),
          // Debug overlay
          debugConsole.overlay(),
        ],
      ),
    ),
  ],
)
```

## 12. File Uploads

You can upload files with additional form data:

```dart
final response = await client.postSingleFileWithDataRequest<UploadResult>(
  endpoint: 'https://api.example.com/upload',
  fileJsonKey: 'file',
  file: File('/path/to/image.jpg'),
  data: {'description': 'Profile picture'},
  fromJson: (json) => UploadResult.fromJson(json),
);

// Upload multiple files
final response = await client.postFilesWithDataRequest<UploadResult>(
  endpoint: 'https://api.example.com/upload-multiple',
  fileJsonKey: 'files',
  files: [File('/path/to/file1.jpg'), File('/path/to/file2.jpg')],
  data: {'album': 'Vacation 2023'},
  fromJson: (json) => UploadResult.fromJson(json),
);
```

The htpio package provides a comprehensive set of tools for handling HTTP requests in Dart and Flutter applications, with features comparable to popular packages like http and dio, but with additional functionality for caching, offline support, mocking, and debugging.
        