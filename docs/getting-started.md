# 1 — Install & Boot

**What you'll do:** Add Velora to your app, call `Velora.boot()` before `runApp`, and verify the setup works in mock mode — no backend required.

---

## Add the dependency

Velora is distributed as a git dependency while in developer preview:

```yaml title="pubspec.yaml"
dependencies:
  velora:
    git:
      url: https://github.com/md-riaz/velora-flutter
      path: packages/velora
```

```bash
flutter pub get
```

## Configure and boot

Call `Velora.boot()` in `main()` before `runApp`. Pass a `VeloraConfig` with your app name and Laravel API base URL:

```dart title="lib/main.dart"
import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Velora.boot(
    config: const VeloraConfig(
      appName: 'My App',
      apiBaseUrl: 'https://api.example.com/api',
    ),
  );

  runApp(const MyApp());
}
```

`Velora.boot()` initializes storage, API client, auth, navigation, and permissions in the correct dependency order. Always `await` it before `runApp`.

## Enable mock mode

You don't need a running Laravel backend to build UI. Set `useMock: true` and your feature data sources return seeded test data instead of hitting the network:

```dart
await Velora.boot(
  config: const VeloraConfig(
    appName: 'My App',
    apiBaseUrl: 'https://api.example.com/api',
    useMock: true,
  ),
);
```

With mock mode on:

- `Velora.auth.login()` accepts any credentials and seeds a fake user with configurable roles and permissions.
- Your `MockRemoteDataSource` implementations return fixture data.
- `VeloraMockApi.ok(data, delayMs: 120)` and `VeloraMockApi.error(message)` simulate responses with realistic latency.

## Available facades

After boot, all core services are accessible through `Velora.*` — no manual `Get.find()` required:

| Facade | Service | Purpose |
|---|---|---|
| `Velora.auth` | `AuthService` | Session, current user, token |
| `Velora.api` | `ApiService` | HTTP client, request helpers |
| `Velora.nav` | `NavigationService` | GetX routing |
| `Velora.storage` | `StorageService` | Key-value persistence |
| `Velora.permission` | `PermissionService` | Role and permission checks |
| `Velora.notify` | `NotificationService` | Push + in-app notifications |

---

**Next:** [2 — Architecture →](architecture.md)
