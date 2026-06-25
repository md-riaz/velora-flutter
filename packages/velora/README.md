# Velora

Laravel-inspired productivity for Flutter apps — works with **any JSON API**.

Velora is a batteries-included DX framework that gives Flutter apps the same
convention-over-configuration feel that makes Laravel enjoyable on the backend.
It wires up auth, routing, storage, permissions, notifications, HTTP, and media
attachments with sensible defaults — but every default is overridable.

---

## Features

- **Auth** — bearer-token login/logout with reactive session state, persistent
  storage, and safe concurrent-logout coordination
- **HTTP** — Dio-backed API service with automatic Bearer token injection,
  composable interceptors, retry logic, and normalised error handling
- **Response parsing** — configurable JSON envelope keys so you can match any
  backend's response shape, not just a specific one
- **Routing guards** — `Velora.authOnly` / `Velora.guestOnly` middleware
  shorthands for GetX routes; bring your own guard logic via `VeloraRouteGuard`
- **Permissions** — reactive role/permission helpers backed by whatever your
  server returns in the user payload
- **Features** — runtime feature-flag toggling, permission-gated menu items,
  per-user scope flushing on logout
- **Notifications** — push (FCM or custom adapter), local, and in-app
  notification centre with a no-op adapter for dev/testing
- **Media attachments** — pick → upload → submit flow with progress, retry, and
  a built-in `MultipartUploadAdapter` for any multipart endpoint
- **Theme** — `ThemeService` for light/dark/system toggle with persistence
- **Storage** — `VeloraStorageService` wrapping `SharedPreferences` and
  `FlutterSecureStorage` with typed JSON helpers
- **Validation** — `VeloraValidator` rule set for forms
- **Responsive** — breakpoint helpers and layout utilities

---

## Getting started

```yaml
dependencies:
  velora:
    path: packages/velora   # local monorepo reference
```

Boot Velora once in `main.dart` before `runApp`:

```dart
await Velora.boot(
  config: VeloraConfig(
    appName: 'My App',
    apiBaseUrl: 'https://api.example.com',
    auth: VeloraAuthConfig(
      loginEndpoint: '/auth/login',
      logoutEndpoint: '/auth/logout',
      meEndpoint: '/auth/me',
    ),
  ),
);
```

## Auth

```dart
// Any credential shape — email/password, username/OTP, SSO token, etc.
await Velora.login({'email': email, 'password': password});
await Velora.login({'username': username, 'otp': otp});

// Reactive state
Velora.auth.check;           // bool
Velora.auth.user;            // AuthUser?
Velora.auth.isAuthenticated; // RxBool

await Velora.logout();
```

---

## Adapting to your API's response shape

Velora uses a `{success, data, message, errors}` envelope by default. Override
any key via `VeloraResponseConfig`:

```dart
VeloraConfig(
  apiBaseUrl: 'https://api.example.com',
  // Backend returns: {"ok": true, "payload": {...}, "error": "..."}
  response: VeloraResponseConfig(
    successKey: 'ok',
    dataKey: 'payload',
    messageKey: 'error',
  ),
)
```

### Custom login response shape

If your API returns the token or user under different keys:

```dart
VeloraAuthConfig(
  tokenExtractor: (payload) => payload['jwt']?.toString(),
  userExtractor: (payload) => payload['account'] as Map<String, dynamic>?,
)
```

### Custom pagination shape

`PaginatedData.fromJson` accepts named key overrides:

```dart
// Django REST Framework: {"count": 73, "results": [...]}
PaginatedData.fromJson(
  json,
  parser,
  dataKey: 'results',
  metaKey: null,          // meta fields are top-level
  totalKey: 'count',
  currentPageKey: 'page',
  lastPageKey: 'total_pages',
  perPageKey: 'page_size',
)
```

---

## Route guards

```dart
GetPage(
  name: '/dashboard',
  page: () => DashboardPage(),
  middlewares: Velora.authOnly,        // redirect unauthenticated users
),
GetPage(
  name: '/login',
  page: () => LoginPage(),
  middlewares: Velora.guestOnly(),     // redirect already-authenticated users
),
```

---

## HTTP interceptors

```dart
await Velora.boot(
  config: config,
  interceptors: [
    VeloraLogInterceptor(),
    VeloraRetryInterceptor(maxAttempts: 3),
  ],
);
```

Implement `VeloraApiInterceptor` for custom logic:

```dart
class MyInterceptor extends VeloraApiInterceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-App-Version'] = '1.0.0';
    handler.next(options);
  }
}
```

---

## File attachments

```dart
class PostController extends VeloraController with VeloraAttachmentsMixin {
  @override
  VeloraUploadAdapter get uploadAdapter => MultipartUploadAdapter(
    endpoint: '/api/uploads',
  );

  Future<void> submit() async {
    await uploadAll();
    await Velora.api.post('/posts', data: {
      'body': body.value,
      'attachment_ids': mediaIds,
    });
  }
}
```

---

## Typed config extensions

Attach your own configuration without untyped maps:

```dart
class AnalyticsConfig extends VeloraConfigExtension {
  final String writeKey;
  const AnalyticsConfig({required this.writeKey});
}

final config = VeloraConfig(
  appName: 'My App',
  apiBaseUrl: 'https://api.example.com',
  extensions: [const AnalyticsConfig(writeKey: 'abc123')],
);

// Access anywhere:
final analytics = Velora.config.extension<AnalyticsConfig>();
```
