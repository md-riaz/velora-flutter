# 2 — Architecture

**What you'll learn:** How a Velora feature is actually wired together — controller, service, repository, data source — and why the framework uses plain constructor injection instead of a service locator or `Bindings` subclasses.

---

## The stack

Every Velora feature follows the same vertical slice, from a user action down to the network:

```text
View
  ↓  user events, navigation
Controller (extends VeloraController / VeloraFormController / VeloraPaginatedController)
  ↓  owns screen-local Rx state (loading, error, items, ...); delegates business logic
Service (plain Dart class — NOT GetxService)
  ↓  business logic / orchestration, injected by constructor
Repository (implements VeloraRepository<T, ID>)
  ↓  data-access contract
RemoteDataSource (implements VeloraRemoteDataSource<T, ID>)
  ↓  knows where data actually comes from
Velora.api / Velora.storage
```

The rule: **each layer only talks to the layer directly below it.** A view never calls a repository. A controller never calls `Velora.api` directly (`examples/claude_clone`'s `HomeController` is a deliberate, documented exception — see below).

## Wiring: plain constructor injection, not a service locator

Velora does not use `Get.lazyPut`, `Get.find()`, or a `Bindings` subclass to assemble a module. Every module `velora new` / `make:module` generates ships a `{name}_module.dart` factory that wires dependencies by hand:

```dart
class UsersModule {
  const UsersModule._();

  static UsersController controller() {
    final dataSource = UsersRemoteDataSource();
    final repository = UsersRepository(dataSource);
    final service = UsersService(repository);
    return UsersController(service);
  }
}
```

A page gets its controller straight from the module factory (`UsersModule.controller()`). There's no runtime lookup by type, so a missing or mistyped dependency is a compile error, not a "controller not found" crash at runtime.

Services in this pattern are **plain Dart classes — not `GetxService`** — that hold business logic and delegate to a repository. A service is not an app-wide singleton by default, but it *is* where shared/business data belongs: if two screens need the same data, share a repository/data-source instance (or a plain service wrapping it) across the module factories that need it. Controllers stay screen-local — they hold their own UI state and delegate everything else, never the other way around. App **business/module** services stay plain classes; the one place app code legitimately reaches for a `GetxService` is genuinely app-wide *session* state (current org, current user, ...), the same tier the framework's own `AuthService`/`LogoutCoordinator` occupy — see [Where shared state lives](#where-shared-state-lives).

## Controllers own their own Rx state

`VeloraController` gives every controller `loading` (`RxBool`) and `error` (`RxString`), plus a `run()` helper that wraps async work with loading/error bookkeeping and an optional success/error toast:

```dart
class UsersController extends VeloraController {
  final UsersService service;
  UsersController(this.service);

  Future<List<UsersModel>> load() async {
    final result = await run<List<UsersModel>>(service.index);
    return result ?? <UsersModel>[];
  }
}
```

For list screens, `VeloraPaginatedController<T>` (page-number pagination) and `VeloraCursorController<T, C>` (cursor pagination) add `items`, `hasMore`, `reload()`, and `loadMore()` on top of the same `loading`/`error`/`run()` base — **the controller itself owns that screen's Rx list**, not a separate service. For forms, `VeloraFormController` adds an `errors` map keyed by field name. This screen-local Rx state (`loading`/`error`/`items`/`errors`) is the only state a controller should own directly; shared or cross-screen data belongs elsewhere — a reactive query, a plain feature service, or a session service depending on its scope — never duplicated across controllers. [Where shared state lives](#where-shared-state-lives) covers which is which.

For binding a reactive source — e.g. a `velora_db`/`velora_offline` `watch*` stream — into that Rx state, `VeloraController.listenStream(stream, onData)` subscribes and automatically cancels the subscription when the controller is disposed, so a controller never has to hand-manage a `StreamSubscription` field or an `onClose` cancel call itself.

## Where shared state lives

"Shared state" is not one thing, and it does **not** automatically mean "make a `GetxService`." Pick a home by the state's **scope and lifetime**, not by whether more than one widget reads it:

| State | Home | Example |
|---|---|---|
| One screen's UI state | The **controller** (`VeloraController` Rx fields) | `loading`, `error`, the current list/page, form `errors` |
| Shared **records** many screens read | The **reactive data layer** (`velora_db` / `velora_offline`) — the single source of truth | Chat messages shown in both a conversation list and a thread |
| **Session / app-wide** value tied to login↔logout | A **session service** (a `GetxService`, or a plain class held app-wide) | Current org/tenant, current user, feature flags, locale |
| Business data shared by a **few related screens** in one feature | A **plain service**, constructed once and injected via those module factories | A feature's in-memory working set |
| **Derived** cross-page aggregates | A **reactive query/stream over whichever layer above owns the truth** — never a hand-incremented counter duplicated per page | Unread count, "latest N", an app-bar badge |

Two rules cut through most confusion:

- **Reactivity does not require `GetxService`.** `.obs` / `Rx` / `Rxn` — or even a plain `ValueNotifier` — work in any plain class (the generated notifications module holds its `unreadCount` as a `ValueNotifier<int>`). `GetxService` buys you three specific things: an app-wide lifetime managed outside the widget tree, lifecycle hooks (`onInit`/`onClose` and **logout teardown** via `VeloraLogoutAware`), and global access without threading the instance through factories. Reach for it only when you need those.
- **The "no app-level `GetxService`" rule is about per-module *business* services** (the `UsersService` kind — those stay plain classes). It is **not** a ban on genuinely app-wide *session* state, which is the same tier as the framework's own `AuthService` / `FeatureService` / `ConnectivityService`.

### Example: current-org (session state → a session service)

A "current organization" that every page can read without re-fetching is session state: one instance, app-wide lifetime, set at login/switch, cleared at logout. That earns a `GetxService`:

```dart
class CurrentOrgService extends GetxService with VeloraLogoutAwareDefaults {
  final _current = Rxn<Org>();

  Org? get current => _current.value;    // one-shot read, no re-fetch
  Rxn<Org> get rx => _current;           // for Obx(() => ...rx.value)

  void set(Org org) => _current.value = org;   // on login / org switch
  void clear() => _current.value = null;

  @override
  Future<void> onLogoutDispose() async => clear();  // cleared at logout
}
```

Register it in a tiny `VeloraPlugin` (so it joins boot + logout teardown) and expose a facade for ergonomic access, mirroring `Velora.auth` / `VeloraOffline.connectivity`:

```dart
class CurrentOrgPlugin extends VeloraPlugin {
  @override
  Future<void> register(VeloraContext context) async {
    final service = CurrentOrgService();
    context.put<CurrentOrgService>(service);
    context.onBeforeLogout(service.clear);
  }
}

abstract final class Session {
  static CurrentOrgService get org => Get.find<CurrentOrgService>();
}
```

Now any page reads `Session.org.current`, binds `Obx(() => Text(Session.org.rx.value?.name ?? '—'))`, and an API interceptor can scope every request by `Session.org.current?.id` — all from one in-memory value that's fetched once and cleared on sign-out.

### Example: unread counts & badges (derived state → a reactive query)

When the underlying records already live in the reactive data layer, cross-page aggregates are **derived views**, not a second copy of the state. An unread-message count on a dashboard and the same figure as an app-bar badge are both just another `watch*` query over the same `velora_db` tables the conversation screens read:

```dart
class DashboardController extends VeloraController {
  final VeloraTable<Message, String> _messages;
  DashboardController(this._messages);

  final unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    listenStream(
      _messages.watchQuery(_messages.query().where('read', false)),
      (rows) => unreadCount.value = rows.length,
    );
  }
}
```

Because the count is derived from the single source of truth, it can never drift out of sync with the threads — every screen watching a matching query updates the instant a message is written or marked read. A **hand-maintained counter that each page increments is the anti-pattern** here: it duplicates state and drifts.

For a badge whose source isn't a table — e.g. the notification bell — bind the app bar to a shared service's reactive field instead: a session service exposing an `RxInt` read inside `Obx`, or a plain injected service exposing a `ValueNotifier<int>` read inside `ValueListenableBuilder` (the shape the generated notifications module uses). Either way the badge is a reactive *view* over one owner, not a counter the app bar maintains.


## A concrete example: the generated `users` module

This is what `dart run velora_cli make:module users --crud` actually produces (see [Scaffolding](scaffolding.md) for the full file tree):

```dart
// 1. Remote data source — the only layer that calls Velora.api
class UsersRemoteDataSource implements VeloraRemoteDataSource<UsersModel, int> {
  final String endpoint;
  const UsersRemoteDataSource({this.endpoint = '/users'});

  @override
  Future<List<UsersModel>> index() async {
    final response = await Velora.api.get<List<UsersModel>>(
      endpoint,
      parser: (value) => /* ... */ [],
    );
    return response.data ?? <UsersModel>[];
  }
  // show / store / update / destroy follow the same shape.
}

// 2. Repository — implements the shared VeloraRepository contract
class UsersRepository implements VeloraRepository<UsersModel, int> {
  final UsersRemoteDataSource remoteDataSource;
  const UsersRepository(this.remoteDataSource);

  @override
  Future<List<UsersModel>> index() => remoteDataSource.index();
  // show / store / update / destroy delegate the same way.
}

// 3. Service — plain class, delegates to the repository
class UsersService {
  final UsersRepository repository;
  const UsersService(this.repository);

  Future<List<UsersModel>> index() => repository.index();
  // show / store / update / destroy delegate the same way.
}

// 4. Controller — owns loading/error, delegates to the service
class UsersController extends VeloraController {
  final UsersService service;
  UsersController(this.service);

  Future<List<UsersModel>> load() async {
    final result = await run<List<UsersModel>>(service.index);
    return result ?? <UsersModel>[];
  }
}

// 5. Module factory — the only place that wires the layers together
class UsersModule {
  const UsersModule._();

  static UsersController controller() {
    final dataSource = UsersRemoteDataSource();
    final repository = UsersRepository(dataSource);
    final service = UsersService(repository);
    return UsersController(service);
  }
}
```

## Swapping data sources

Because the repository and service depend on a constructor-supplied instance — not something resolved through a locator — you swap implementations by changing what `${ClassName}Module.controller()` constructs, with zero changes to the controller or service. `examples/claude_clone`'s `HomeController` uses exactly this: it accepts an optional data source in its constructor,

```dart
class HomeController extends VeloraPaginatedController<ConversationModel> {
  final ConversationsDataSource _dataSource;

  HomeController({ConversationsDataSource? dataSource})
      : _dataSource = dataSource ?? MockConversationsDataSource();

  @override
  Future<PaginatedData<ConversationModel>> fetchPage(int page) =>
      _dataSource.getPage(page);
}
```

so a test, or a different environment, can pass a `RemoteConversationsDataSource` instead — with no repository/service layer in between at all for that screen.

## A richer hand-built example: `examples/claude_clone`

The generated scaffold above is the minimal shape `make:module` produces. `examples/claude_clone` is a larger, hand-built app that follows the same DI philosophy but adapts it per screen — it's a richer reference, not the CLI's baseline:

- `HomeController extends VeloraPaginatedController<ConversationModel>` talks directly to a `ConversationsDataSource`, skipping a dedicated repository/service layer for that screen, and overrides `fetchPage` to get pagination for free.
- Routing uses GetX's declarative `GetPage`/`AppPages` list. Each route's `binding: BindingsBuilder(...)` is *only* how that route constructs its page's controller — a routing convenience, not a dependency-injection strategy:

  ```dart
  GetPage(
    name: AppRoutes.home,
    page: () => const HomePage(),
    binding: BindingsBuilder(() => Get.lazyPut(() => HomeController(), fenix: true)),
    middlewares: Velora.authOnly,
  ),
  ```

  This is different from the minimal `velora new` scaffold, which wires a `MaterialApp` to a hand-written `switch` in `AppRouter.onGenerateRoute` and constructs controllers straight from a `{name}_module.dart` factory (see [Scaffolding](scaffolding.md)). `claude_clone`'s `BindingsBuilder`/`Get.lazyPut` is a one-off consequence of that example choosing GetX's declarative routing — it is **not** an endorsed alternative for dependency injection, and app code should not adopt `Bindings`/`Get.lazyPut` as its DI mechanism.

The blessed pattern, everywhere, is the module factory: `{ClassName}Module.controller()` constructs the full dependency chain by hand and hands the caller a ready controller, exactly as shown in the generated `users` module example above. Notice that even inside `claude_clone`'s `BindingsBuilder`, the thing actually being constructed is still `HomeController()` — a plain constructor call, not a service-locator lookup of something pre-registered elsewhere. `Get.lazyPut`/`Get.find()` as a general-purpose locator, and an app-level `Bindings` subclass that resolves dependencies implicitly across the app, remain out of scope for app code regardless of which routing style you pick.

## Key rules

- **Controllers** must not call `Velora.api` directly — go through a service and repository, or (for a simple screen like `claude_clone`'s `HomeController`) directly through a data source.
- **Services**, when used, must not call `Get.back()`, push routes, or show dialogs — those are controller/navigation concerns.
- **Data sources** are the only layer that knows whether data comes from the network, local storage, or a mock/fake.
- **`VeloraController.run()`** (and the `reload()`/`loadMore()` it powers on `VeloraPaginatedController`/`VeloraCursorController`) is the standard wrapper for async work — use it everywhere loading/error state is needed.
- **Wiring is explicit and constructor-based**: a per-module factory (`{name}_module.dart`) constructs and injects dependencies by hand. This — not a service locator or a `Bindings` subclass — is the blessed DI pattern for app **modules**. (Genuinely app-wide *session* state is the one exception that's registered as a singleton rather than constructor-wired — see [Where shared state lives](#where-shared-state-lives). And `claude_clone`'s per-route `BindingsBuilder` is a GetX routing convenience for constructing that route's controller, not an app-wide DI mechanism — don't copy it into your own dependency wiring.)

---

**Next:** [3 — Auth →](auth.md)
