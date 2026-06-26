# 3 — Auth

**What you'll do:** Wire a login screen to `Velora.auth`, protect routes with a guard, read session state anywhere in the app, and implement safe logout.

---

## Configure auth endpoints

`AuthService` works with any bearer-token API. Override the defaults in `VeloraConfig` if your Laravel routes differ:

```dart
await Velora.boot(
  config: const VeloraConfig(
    appName: 'My App',
    apiBaseUrl: 'https://api.example.com/api',
    auth: VeloraAuthConfig(
      loginPath: '/auth/login',    // default
      logoutPath: '/auth/logout',  // default
      mePath: '/auth/me',          // default
    ),
  ),
);
```

For a standard Laravel Sanctum setup the defaults work with no overrides.

## Login

Pass credentials to `Velora.auth.login()`. It POSTs to your login endpoint, stores the returned token, and fetches the current user via `/auth/me`:

```dart
class LoginController extends VeloraController {
  Future<void> submit(String email, String password) async {
    await run(() async {
      await Velora.auth.login({'email': email, 'password': password});
    });
    if (error.value.isNotEmpty) return; // UI shows error.value reactively
    Velora.nav.offAll('/home');
  }
}
```

`run()` catches exceptions and writes them to `error.value` — your login form reads `controller.error` reactively and displays the message without any try/catch in the controller.

## Reading session state

Once logged in, session state is available from anywhere:

```dart
Velora.auth.check;         // bool — true when authenticated
Velora.auth.user;          // VeloraUser? — current user
Velora.auth.sessionState;  // SessionState enum
```

`Velora.auth.user` carries the roles and permissions that power the [Permissions](permissions.md) system.

## Protect routes

Wrap authenticated routes with `VeloraAuthGuard` to redirect unauthenticated users to `/login`:

```dart
GetPage(
  name: '/home',
  page: () => const HomePage(),
  middlewares: [VeloraAuthGuard()],
),
```

## Logout

Logout is a lifecycle transaction, not a plain token clear. Call `Velora.auth.logout()` — it delegates to `LogoutCoordinator` which enforces a safe teardown order:

```dart
await Velora.auth.logout();
```

The coordinator runs in order:

1. Locks logout — double taps are idempotent.
2. Sets `SessionState.loggingOut`.
3. Stops event sources: sockets, notification streams, timers, background sync.
4. Calls the logout endpoint **while the token still exists**.
5. Continues local teardown even if the remote call fails.
6. Navigates to `/login` (or your configured unauthenticated route).
7. Waits one Flutter frame so mounted widgets can dispose.
8. Clears token, user, permissions, and private user cache.
9. Disposes user-scope and feature-scope dependencies.

**Never** call `Velora.storage.clearToken()` before the logout endpoint — the coordinator handles ordering.

### Session states

```dart
enum SessionState {
  guest,          // no session
  authenticating, // login in flight
  authenticated,  // active session
  loggingOut,     // teardown in progress
}
```

Route guards must redirect during `loggingOut` without reading partially-cleared state. `AuthService.check` only returns `true` in the `authenticated` state.

### Lifecycle hooks

Services that need to clean up user data implement logout-aware hooks:

```dart
// beforeLogout — stop listeners, cancel requests
// afterLogoutNavigation — work that needs UI gone first
// onLogoutDispose — clear private user data before DI disposal
```

### Dependency scopes

**Keep alive during logout:** `AuthService`, `ApiService`, `StorageService`, `NavigationService`, `LogoutCoordinator`, `PermissionService`.

**Dispose during logout:** notification service, tenant/profile services, feature services, repositories, data sources, and controllers.

## Mock auth

In mock mode, `Velora.auth.login()` accepts any credentials and seeds a configurable `VeloraUser` with roles and permissions — no backend required while building your UI.

---

**Next:** [4 — API Client →](api-client.md)
