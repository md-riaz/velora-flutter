# Auth

Velora targets Laravel Sanctum bearer tokens. `AuthService` is a `GetxService` and owns session state, the current user, and token persistence.

Default endpoints are configurable through `VeloraAuthConfig` and default to `/auth/login`, `/auth/logout`, and `/auth/me`.

```dart
await Velora.auth.login(email: email, password: password);
Velora.auth.check;
Velora.auth.user;
await Velora.auth.logout();
```

The starter app includes a mock mode for UI/API testing without a Laravel backend: demo login stores a Sanctum-like token plus user roles, permissions, and features, then reboots Velora services. Real apps should replace that with the Laravel Sanctum login endpoint.

## Logout Safety Contract

Logout is a lifecycle transaction, not a plain token clear. It must be idempotent and run through a core `LogoutCoordinator` so double taps or repeated calls do not start parallel teardown.

Safe order:

1. `AuthService.logout()` delegates to `LogoutCoordinator.run()`.
2. Coordinator locks logout and sets `SessionState.loggingOut` before teardown.
3. Stop incoming user event sources: sockets, notification streams, timers, polling jobs, uploads, background sync, and user stream subscriptions.
4. Call Laravel `/auth/logout` while the bearer token and API client still exist.
5. Continue local logout even if remote logout fails.
6. Navigate to a safe unauthenticated route such as `/login` or `/goodbye`.
7. Wait one Flutter frame after navigation so feature widgets/controllers can dispose.
8. Clear token, user, permissions, enabled features, and private user cache.
9. Dispose user-scope and feature-scope dependencies.
10. Return session state to `SessionState.guest`.

Never delete feature dependencies while current feature widgets are still mounted. Navigate away first, wait one frame, then dispose scopes.

### Session state and route guards

Auth state must distinguish logout from guest/authenticated states:

```dart
enum SessionState {
  guest,
  authenticating,
  authenticated,
  loggingOut,
}
```

`AuthService.check` should only be true when state is `authenticated`. During `loggingOut`, route guards and middleware must redirect to a safe unauthenticated route and avoid reading half-cleared token, user, permission, or feature state.

### Coordinator rules

`LogoutCoordinator` owns ordering:

```dart
await remoteLogout();              // token still available
await Velora.nav.offAll('/login');
await Future<void>.delayed(Duration.zero); // next frame
await localTeardown();
```

Remote logout uses the current bearer token. Do not clear storage first:

```dart
await authRepository.logout();
await Velora.storage.clearToken();
```

Remote failure must be caught inside the coordinator or logout flow. Local logout is security-critical and must finish offline or with an expired token.

### Request cancellation and lifecycle hooks

User-scoped API requests must be cancellable, for example with Dio `CancelToken`. Cancel ordinary user requests during logout, but do not cancel the logout request itself unless it uses a separate token.

Services that emit late events should implement logout-aware hooks:

- `beforeLogout`: stop listeners, sockets, timers, polling, notification streams, uploads, and background workers.
- `afterLogoutNavigation`: run work that requires feature UI to be gone.
- `onLogoutDispose`: clear private user data before dependency disposal.

Async callbacks in controllers/services must check they are still alive before mutating reactive or widget state after `await`.

### Dependency scopes

Keep core services alive during normal logout: `AuthService`, `ApiService`, `StorageService`, `NavigationService`, `ToastService`, `LogoutCoordinator`, `FeatureService`, and `PermissionService`.

Clear user scope: notification, tenant, profile, and user preference services.

Dispose feature scope through generated feature disposers, not broad reflection deletes. Feature scope includes feature services, repositories, data sources, and controllers. Disabled or lazy-loaded features must be safe to skip when not registered.
