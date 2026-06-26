# 4 — API Client

**What you'll do:** Call your Laravel endpoints through `Velora.api`, unwrap `ApiResponse<T>` generics, handle validation errors, and swap in mock data sources for testing.

---

## The `Velora.api` facade

`Velora.api` is a `GetxService` wrapping Dio. It applies your configured base URL, injects the stored bearer token on every request, and normalizes Laravel validation errors into `ApiException`.

Never call Dio directly from a controller or service — always go through a repository → data source → `Velora.api`.

## Making requests

```dart
// GET with a typed parser
final res = await Velora.api.get<List<User>>(
  '/users',
  parser: (json) => (json as List)
      .map((e) => User.fromJson(e as Map<String, dynamic>))
      .toList(),
);
final users = res.data ?? [];

// GET with query parameters
final res = await Velora.api.get<List<User>>(
  '/users',
  queryParameters: {'page': 1, 'per_page': 20},
  parser: (json) => (json as List).map((e) => User.fromJson(e)).toList(),
);

// POST
final res = await Velora.api.post<User>(
  '/users',
  data: {'name': 'Jane', 'email': 'jane@example.com'},
  parser: (json) => User.fromJson(json as Map<String, dynamic>),
);

// PUT / DELETE
await Velora.api.put('/users/$id', data: {'name': 'Updated'});
await Velora.api.delete('/users/$id');
```

## `ApiResponse<T>`

Every call returns `ApiResponse<T>`, not the data directly:

```dart
final res = await Velora.api.get<User>('/users/1', parser: User.fromJson);

res.data;       // T? — parsed response body
res.message;    // String? — top-level "message" from Laravel response
res.success;    // bool — true for HTTP 2xx
res.statusCode; // int — raw HTTP status code
```

Always check `res.data` for null — a `204 No Content` response has a non-null `ApiResponse` but a null `.data`.

## Error handling

`Velora.api` normalizes Laravel's `422 Unprocessable Entity` shape into `ApiException`. Inside `VeloraController.run()`, exceptions are caught automatically and written to `error.value`:

```dart
class UsersController extends VeloraController {
  Future<void> createUser(String name, String email) async {
    await run(() async {
      final user = await _dataSource.create(name: name, email: email);
      users.add(user);
    });
    if (error.value.isNotEmpty) return; // validation/network error shown by UI
    Velora.toast.success('User created');
  }
}
```

`ApiException.validationErrors` is a `Map<String, List<String>>` — the same shape as Laravel's validation response — so you can display field-level messages directly.

## The data source pattern

Data sources are the only layer that calls `Velora.api`. Define an abstract interface and bind implementations in your feature `Binding`:

```dart
// Contract — what controllers and services depend on
abstract class UsersDataSource {
  Future<List<User>> list();
  Future<User> create({required String name, required String email});
}

// Production — hits the network
class UsersRemoteDataSource implements UsersDataSource {
  @override
  Future<List<User>> list() async {
    final res = await Velora.api.get<List<User>>(
      '/users',
      parser: (json) => (json as List).map((e) => User.fromJson(e)).toList(),
    );
    return res.data ?? [];
  }

  @override
  Future<User> create({required String name, required String email}) async {
    final res = await Velora.api.post<User>(
      '/users',
      data: {'name': name, 'email': email},
      parser: (json) => User.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }
}

// Development — returns seeded data with realistic latency
class MockUsersDataSource implements UsersDataSource {
  final _store = <User>[...seeds];

  @override
  Future<List<User>> list() async {
    await VeloraMockApi.ok<void>(null, delayMs: 120);
    return List.of(_store);
  }

  @override
  Future<User> create({required String name, required String email}) async {
    final user = User(id: '${_store.length + 1}', name: name, email: email);
    await VeloraMockApi.ok(user, delayMs: 80);
    _store.add(user);
    return user;
  }
}
```

Bind `MockUsersDataSource` during development, swap to `UsersRemoteDataSource` for production — your service and controller are never touched.

---

**Next:** [5 — Permissions →](permissions.md)
