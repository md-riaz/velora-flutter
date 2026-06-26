# 2 — Architecture

**What you'll learn:** The six-layer stack Velora enforces, why services own state instead of controllers, and how a feature flows end-to-end from data source to UI.

---

## The stack

Every Velora feature follows the same vertical slice:

```text
View
  ↓  user events, navigation
Controller
  ↓  delegates business logic
Service (GetxService)
  ↓  owns shared/business state
Repository interface
  ↓  data-access contract
Repository implementation
  ↓  delegates to data sources
RemoteDataSource / LocalDataSource
  ↓  knows where data actually comes from
Velora.api / Velora.storage
```

The rule: **each layer only talks to the layer directly below it.** A view never calls a repository. A controller never calls `Velora.api` directly.

## Services own state, controllers own screens

This is the most important distinction in Velora:

| `GetxService` | `GetxController` |
|---|---|
| Lives for the session lifecycle | Lives for the screen lifecycle |
| Owns shared and business state | Owns screen/UI state |
| Injected across many features | Bound to one screen |
| Examples: auth session, unread count, feature flags | Examples: form state, loading spinner, pagination offset |

If two screens need the same piece of state — the current user, a notification count, a flag — it belongs in a **service**, not a controller.

## A concrete example

Here's how a "load users" feature flows through all six layers:

```dart
// 1. View — triggers the action
ElevatedButton(
  onPressed: controller.loadUsers,
  child: const Text('Load Users'),
)

// 2. Controller — UI-focused, delegates to service
class UsersController extends VeloraController {
  final UsersService _service = Get.find();

  Future<void> loadUsers() async {
    await run(_service.fetchUsers);
  }
}

// 3. Service — owns the users list, applies business logic
class UsersService extends GetxService {
  final UsersRepository _repo;
  UsersService(this._repo);

  final RxList<User> users = <User>[].obs;

  Future<void> fetchUsers() async {
    users.value = await _repo.list();
  }
}

// 4. Repository interface — data-access contract
abstract class UsersRepository {
  Future<List<User>> list();
}

// 5. Remote data source — calls Velora.api
class UsersRemoteDataSource implements UsersRepository {
  @override
  Future<List<User>> list() async {
    final res = await Velora.api.get<List<User>>(
      '/users',
      parser: (json) => (json as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res.data ?? [];
  }
}
```

`VeloraController.run()` manages `loading` and `error` automatically — you never set them manually.

## Swapping data sources

Because controllers and services depend only on the repository **interface**, you can bind `MockUsersDataSource` in development and swap to `UsersRemoteDataSource` in production — zero changes to services or controllers. This is the foundation of Velora's mock mode.

Bind implementations in your feature's `Binding`:

```dart
class UsersBinding extends Bindings {
  @override
  void dependencies() {
    // Swap MockUsersDataSource ↔ UsersRemoteDataSource here
    Get.lazyPut<UsersRepository>(() => UsersRemoteDataSource());
    Get.lazyPut(() => UsersService(Get.find()));
    Get.lazyPut(() => UsersController());
  }
}
```

## Key rules

- **Services** must not call `Get.back()`, push routes, or show dialogs — those are controller/navigation concerns.
- **Controllers** must not call `Velora.api` directly — always go through a service and repository.
- **Data sources** are the only layer that knows whether data comes from the network, local storage, or a mock.
- **`VeloraController.run()`** is the standard wrapper for async work — use it everywhere loading/error state is needed.

---

**Next:** [3 — Auth →](auth.md)
