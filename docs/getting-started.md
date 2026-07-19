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

## Build UI without a backend

`VeloraConfig` has no `useMock` switch — Velora doesn't have a framework-level mock
mode. Instead, write a mock data source and choose it yourself in your module's
factory. This is an app-level convention, not something the framework does for you.

Given a generated `users` module (see [7 — Scaffold a Module](scaffolding.md)),
add a mock implementation of the same data-source interface using
[`VeloraMockApi`](https://github.com/md-riaz/velora-flutter/blob/main/packages/velora/lib/src/http/mock_api_service.dart)
to fake network latency and responses:

```dart
import 'package:velora/velora.dart';

class MockUsersDataSource implements VeloraRemoteDataSource<UsersModel, int> {
  @override
  Future<List<UsersModel>> index() {
    return VeloraMockApi.ok(
      [
        {'id': 1, 'name': 'Ada Lovelace'},
        {'id': 2, 'name': 'Grace Hopper'},
      ],
      parser: (v) => (v as List)
          .map((e) => UsersModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<UsersModel> show(int id) =>
      VeloraMockApi.fail(message: 'Not implemented in mock mode');

  @override
  Future<UsersModel> store(Map<String, dynamic> data) =>
      VeloraMockApi.fail(message: 'Not implemented in mock mode');

  @override
  Future<UsersModel> update(int id, Map<String, dynamic> data) =>
      VeloraMockApi.fail(message: 'Not implemented in mock mode');

  @override
  Future<void> destroy(int id) async {}
}
```

Then pick which data source your module factory wires up behind a compile-time
flag, the same way `velora make:module` wires the real one by constructor
injection:

```dart
const bool useMock = bool.fromEnvironment('USE_MOCK');

class UsersModule {
  const UsersModule._();

  static UsersController controller() {
    final dataSource = useMock ? MockUsersDataSource() : UsersRemoteDataSource();
    final repository = UsersRepository(dataSource);
    final service = UsersService(repository);
    return UsersController(service);
  }
}
```

Run with `flutter run --dart-define=USE_MOCK=true` to build against fixture data
with no backend running — no config field to flip, just a data source your app
chooses. `VeloraMockApi.ok(data, delayMs: 120)` and `VeloraMockApi.fail(message: '...')`
simulate success and error responses with realistic latency.

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
