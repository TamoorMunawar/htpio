# Changelog

## [1.1.9]
- Fix incorrect androidPackage and pluginClass path.

### Added
- Initial release of `htpio` with the following features:
  - **Modular Middleware System**: Chainable and composable middleware for request/response logic.
  - **Typed Request/Response**: Type-safe handling for API responses.
  - **Smart Offline Mode**: Automatically queues requests when offline, ensuring resilience in mobile environments.
  - **File Download (Pause/Resume)**: Supports large file downloads with pause/resume functionality.
  - **Mock API Mode**: Enables mocking responses for testing without network requests.
  - **Global Interceptors**: Intercept and modify global requests/responses.
  - **Retry Policy**: Implements intelligent retry with exponential backoff to handle mobile network instability.
  - **Caching**: Lightweight in-memory or persistent caching with TTL (Time-to-Live) support for improved performance.
  - **Timeout and Cancellation**: Full support for request timeouts and cancellation using `CancelToken`.
  - **Mobile-Friendly Error Handling**: Displays mobile-friendly error messages, improving the developer experience.

## [1.1.0] - 2025-08-01 (Upcoming)
### Added
- **GraphQL Support**: Initial support for GraphQL queries.
- **Request/Response Recording**: For replaying network requests and responses.
- **VS Code/Flutter DevTools Plugin**: Integration for better debugging and network inspection.

### Fixed
- **Bug Fixes**: Fixed an issue where requests were not properly retrying after a network drop in certain conditions.

### Changed
- **API Changes**: Improved the retry mechanism to handle edge cases more reliably on unstable networks.

---

