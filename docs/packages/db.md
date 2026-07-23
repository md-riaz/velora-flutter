# velora_db

**What you'll do:** Install `velora_db`, wire it into `Velora.boot`, define a table with a migration, query it through the Eloquent-style facade, and bind a `watch()` stream to your UI for live-updating reads — on native and Web, and in tests without a device.

---

## What it does

`velora_db` is a cross-platform, **reactive** local database plugin: a [drift](https://drift.simonbinder.eu/)-backed store with an Eloquent-style query API, built on the same [Velora plugin](../plugins.md) contract as `velora_offline`. It adds:

- **`VeloraDatabase`** — opens and owns a versioned, reactive drift database, applying a list of `VeloraMigration`s deterministically on create/upgrade.
- **`QueryBuilder`** — an immutable, fluent, allowlisted query builder (`where`, `whereOp`, `orderBy`, `limit`, `offset`) that always binds values as parameters, never interpolates them. Its terminal `watch()` method turns any compiled query into a live stream.
- **`VeloraTable<T, ID>`** — maps rows of a single table to/from a model type, with `all`/`find`/`where`/`insert`/`create`/`update`/`delete`/`count`, plus the reactive `watchAll`/`watchQuery`/`watchFind`.
- **`VeloraDbRepository<T, ID>`** — adapts a `VeloraTable` to Velora's `VeloraRepository` contract, so a local table is a drop-in repository alongside remote-backed ones.
- **`VeloraCachedRepository<T, ID>`** — a network-first, read-through cache: wraps a remote data source with a `VeloraTable` cache so reads still work offline. See [Offline reads](#offline-reads-read-through-cache) below.

It works identically on native (drift's `NativeDatabase`, backed by `package:sqlite3`) and Web (drift's `WasmDatabase`, persisting to OPFS/IndexedDB) — see [Cross-platform](#cross-platform) below.

### Why drift, and why no codegen

drift is normally used with generated table classes (`@DriftDatabase(tables: [...])` + `build_runner`). `velora_db` deliberately does **not** do that: there are no drift-generated table classes anywhere in this package or in apps that use it. Every table is created by a plain `VeloraMigration` running raw SQL (`CREATE TABLE ...`), and every read/write goes through drift's untyped `customSelect`/`customStatement` APIs. This keeps the exact same map-based `VeloraTable<T, ID>` API sqflite-backed `velora_db` always had — **no `build_runner`, ever, for apps using this package** — while gaining drift's connection management and, especially, its stream-invalidation primitives (`tableUpdates`/`notifyUpdates`), which is what makes reactive queries possible at all.

## Install

```yaml
dependencies:
  velora_db:
    path: packages/velora_db # or the pub.dev version once published
```

Or let the CLI do it:

```bash
velora install velora_db
```

This adds the dependency, adds the import, and wires `VeloraDbPlugin()` into your `Velora.boot(plugins: [...])` call.

**Native platforms (iOS/Android/macOS/Windows/Linux):** nothing manual to do. `velora_db` depends on [`sqlite3`](https://pub.dev/packages/sqlite3) 3.x, whose build hook bundles a native SQLite build for each of those platforms automatically -- no separate plugin needed (drift's older `sqlite3_flutter_libs` companion package is now end-of-life and obsolete as of `sqlite3` 3.x; see [Cross-platform](#cross-platform) below). There is no equivalent of the old sqflite native setup step.

**Web only:** drift needs two static assets served alongside your app — see [Cross-platform](#cross-platform) below for exactly what they are and where they go. There's no `dart run ...:setup` command for this (that was the old sqflite-based setup); the assets are copied by hand (or by your web build pipeline) into your `web/` directory. This is the *only* manual platform step `velora_db` requires.

## Boot

```dart
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

class CreateTodosTable extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}

await Velora.boot(
  config: myConfig,
  plugins: [
    VeloraDbPlugin(
      databaseName: 'app.db',
      version: 1,
      migrations: [CreateTodosTable()],
    ),
  ],
);
```

`databaseName`, `version`, and `migrations` all default (`'app.db'`, `1`, `const []`), so a bare `VeloraDbPlugin()` — what `velora install velora_db` wires in — is valid and opens an empty database. Add real migrations as soon as you know what tables you need; each `VeloraMigration.version` must be unique, and migrations run in ascending version order (`up()` for every migration on create, and only the migrations whose version falls in `(oldVersion, newVersion]` on upgrade).

`VeloraMigration.up`/`down` receive a `VeloraMigrationContext` rather than a raw database handle — a thin, engine-agnostic wrapper exposing `execute(sql, [args])`. Migrations are always plain SQL strings; they never need to know they're running on drift.

## Define a table & query it

A `VeloraMigration` creates the schema; `VeloraDb.table` (or a `VeloraDbRepository`) binds a model to it:

```dart
class Todo {
  final int? id;
  final String title;
  final bool done;

  const Todo({this.id, required this.title, this.done = false});

  factory Todo.fromMap(Map<String, dynamic> row) => Todo(
    id: row['id'] as int?,
    title: row['title'] as String,
    done: row['done'] == 1,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title,
    'done': done ? 1 : 0,
  };
}

final todos = VeloraDb.table<Todo, int>(
  table: 'todos',
  fromMap: Todo.fromMap,
  toMap: (todo) => todo.toMap(),
);

final all = await todos.all();
final one = await todos.find(1);
final pending = await todos.where('done', 0);
final created = await todos.create(const Todo(title: 'Buy milk').toMap());
await todos.update(created.id!, {'done': 1});
await todos.delete(created.id!);
```

For finer-grained filtering than `where`'s single equality check, drop down to `todos.query()`, which returns a `QueryBuilder` supporting `whereOp` (comparison operators like `>`, `LIKE`, `IS NOT`), `orderBy`, `limit`, and `offset`.

Wrap the table in a `VeloraDbRepository` to use it anywhere a `VeloraRepository<T, ID>` is expected (`index`/`show`/`store`/`update`/`destroy`):

```dart
final todoRepository = VeloraDbRepository<Todo, int>(todos);
final all = await todoRepository.index();
final created = await todoRepository.store(const Todo(title: 'Walk dog').toMap());
```

## Reactive queries (live data)

Every write through `VeloraTable` (`insert`/`update`/`delete`, and `VeloraCachedRepository`'s batched cache refresh) marks its table as changed. Three methods on `VeloraTable` turn that into a live stream, Dexie-`liveQuery`-style: subscribe once, and the stream re-emits the current result set every time something writes to that table — whether that write came from the user tapping a button, a background sync, or a websocket handler somewhere else in your app.

```dart
final todos = VeloraDb.table<Todo, int>(
  table: 'todos',
  fromMap: Todo.fromMap,
  toMap: (todo) => todo.toMap(),
);

// The whole table, live.
Stream<List<Todo>> allTodos = todos.watchAll();

// A filtered, ordered, live query -- same QueryBuilder you'd pass to .get().
Stream<List<Todo>> pending = todos.watchQuery(
  todos.query().where('done', 0).orderBy('title'),
);

// A single row, live -- emits null if the row doesn't exist (yet, or anymore).
Stream<Todo?> one = todos.watchFind(created.id!);
```

Bind any of these directly to a `StreamBuilder`:

```dart
StreamBuilder<List<Todo>>(
  stream: todos.watchAll(),
  builder: (context, snapshot) {
    final items = snapshot.data ?? const <Todo>[];
    return ListView(children: [for (final t in items) Text(t.title)]);
  },
);
```

Or, in a GetX controller, feed a stream into an `Rx` and bind with `Obx`:

```dart
class TodosController extends GetxController {
  final todos = <Todo>[].obs;
  StreamSubscription<List<Todo>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = VeloraDb.table<Todo, int>(
      table: 'todos',
      fromMap: Todo.fromMap,
      toMap: (todo) => todo.toMap(),
    ).watchAll().listen((rows) => todos.assignAll(rows));
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

// In a widget:
Obx(() => ListView(children: [for (final t in controller.todos) Text(t.title)]));
```

Because the stream re-emits on *any* write to the table — not just ones made through this exact `VeloraTable` instance — a background sync job, another screen's repository call, or `VeloraCachedRepository` refreshing its cache after a network fetch, all make every bound widget update automatically. This is the same mental model as [Dexie's `liveQuery`](https://dexie.org/docs/liveQuery()) or Room's `Flow`/`LiveData` queries: you write once, read reactively, and never manually re-fetch after a mutation.

Every stream returned by `watchAll`/`watchQuery`/`watchFind` is broadcast (each `.listen()` call gets its own independent subscription and initial emission) and cancels its internal subscription cleanly when your `StreamSubscription` is cancelled — always cancel in `dispose()`/`onClose()` as shown above. If your controller extends `VeloraController` (see [Architecture](../architecture.md)), skip the manual `StreamSubscription` field entirely and bind with `listenStream(todos.watchAll(), items.assignAll)` — it cancels automatically on `onClose`.

## Offline reads (read-through cache)

`velora_offline` handles offline **writes** — it queues failed POST/PUT/PATCH/DELETE requests and replays them once you're back online. It does not cache reads. `VeloraCachedRepository` is the read counterpart: a **network-first** `VeloraRepository` that tries your remote data source first and falls back to a local `VeloraTable` cache when (and only when) the request looks like it never reached the server.

The two packages compose but don't depend on each other — `VeloraCachedRepository` never imports `velora_offline`; it decides "offline" purely via a pluggable error predicate.

```dart
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

final todoCache = VeloraDb.table<Todo, int>(
  table: 'todos',
  fromMap: Todo.fromMap,
  toMap: (todo) => todo.toMap(),
);

final todoRepository = VeloraCachedRepository<Todo, int>(
  remote: myTodoRemoteDataSource, // a VeloraRemoteDataSource<Todo, int>
  cache: todoCache,
);

final all = await todoRepository.index(); // remote when online, cache when offline
final one = await todoRepository.show(1);
```

Behavior, method by method:

- **`index()` / `show(id)`** — try the remote source first. On success, the result is used to refresh the cache (upserted row by row, in a single batched write) and returned as-is. If the remote call throws an error that looks like "never reached the server" (see below), the cache is served instead — `index()` returns `cache.all()`, `show(id)` returns `cache.find(id)` if that row was ever cached, or rethrows the original error if it wasn't. Any *other* error — e.g. a 404 or 500 that the server actually returned — is rethrown untouched; it is not treated as offline, so a real API error never gets silently swallowed into a stale cache read.
- **`store(data)` / `update(id, data)` / `destroy(id)`** — always delegate straight to the remote source (the source of truth for writes), then update the cache best-effort. A cache write failure here never masks or replaces the already-successful remote result. This class does **not** queue offline writes itself — that's what `velora_offline` is for; put its remote data source underneath (or in front of) a `VeloraCachedRepository` if you want both offline writes and offline reads.

Because cache refreshes go through the same `notifyUpdates` mechanism as any other write, any `watchAll`/`watchQuery`/`watchFind` stream bound to `cache` (or an equivalent `VeloraTable` on the same table) re-emits automatically whenever `index()`/`show()` refreshes it — including a network-only refresh with no local user action at all.

"Looks like never reached the server" is decided by `isOfflineError`, which defaults to `defaultIsOfflineError`: `true` for a `DioException` with type `connectionError`, `connectionTimeout`, `receiveTimeout`, or `sendTimeout`, or for a `SocketException`/`TimeoutException`; `false` for everything else (including `DioException(type: badResponse)`, i.e. a response the server actually sent). Override it if your remote data source surfaces offline conditions differently:

```dart
VeloraCachedRepository<Todo, int>(
  remote: myTodoRemoteDataSource,
  cache: todoCache,
  isOfflineError: (error) => error is MyCustomOfflineSignal || defaultIsOfflineError(error),
);
```

`toCacheMap` defaults to the cache table's own `toMap`; pass it explicitly only if the shape you want cached differs from the table's normal serialization.

**MVP caveat:** cache refresh is an upsert per row from the latest response, not a full replace — rows that were cached previously but are absent from the latest `index()` response (e.g. something deleted server-side) are not automatically evicted from the cache. Plan around this (e.g. periodic full resyncs, or a TTL/version column) if staleness matters for your data.

## Clearing user data on logout

The database **connection** is app-lifetime — `VeloraDbPlugin` opens it once and never closes it on logout. But some of the **data** in it can be user-scoped (a permission cache, cached message history, etc.) and shouldn't leak to the next account on a shared device. Two hooks run during the logout `beforeLogout` phase for exactly that, deleting rows without touching the schema or connection:

```dart
VeloraDbPlugin(
  databaseName: 'app.db',
  version: 1,
  migrations: [CreateTodosTable()],
  // Blanket `DELETE FROM <table>` for simple whole-table wipes.
  clearOnLogout: ['messages', 'permission_cache'],
  // Anything more selective -- a WHERE clause, a VACUUM -- via a callback,
  // which runs after clearOnLogout's deletes. Receives the underlying
  // VeloraSqlDatabase, whose customStatement/customSelect run raw SQL.
  onLogout: (db) async {
    await db.customStatement(
      'DELETE FROM notes WHERE user_scoped = ?',
      [1],
    );
  },
);
```

## Cross-platform

`VeloraDatabase` opens its connection through a drift `QueryExecutor`, resolved by a conditional-import seam so the same `VeloraDbPlugin`/`VeloraDb`/`VeloraTable` API works everywhere:

- **Native** (iOS/Android/macOS/Windows/Linux): a drift `NativeDatabase` running in a background isolate, backed by `package:sqlite3`. For a real app, there's no manual native setup step at all: on a real device or desktop build, the native SQLite library it opens is bundled automatically by `package:sqlite3` 3.x's own build hook -- no companion plugin required, and no `hooks.user_defines` config needed in your app's `pubspec.yaml`. (Older drift setups depended on a separate `sqlite3_flutter_libs` package for this; that package is now discontinued -- its pub.dev listing marks it end-of-life as of its `0.6.0+eol` release, which says outright "update to version 3.x of `package:sqlite3` instead" -- and starting with drift 2.32.0 / `sqlite3` 3.x, native bundling needs no extra dependency at all, so `velora_db` doesn't depend on it.) If you want a fully offline/deterministic build instead of letting the hook download a prebuilt binary -- which is what this repo does for its own packages/examples -- vendor the SQLite amalgamation and point the hook at it with `hooks.user_defines.sqlite3: {source: source, path: <path>/sqlite3.c}`; see [Testing without a device](#testing-without-a-device) and `third_party/sqlite3/README.md` for the details of that setup. That pin only ever applies when the package declaring it is the root package being built/tested -- `hooks.user_defines` is read from the *root* package's `pubspec.yaml`, never a dependency's, so it's invisible to apps that merely depend on `velora_db`.
- **Web**: a drift `WasmDatabase`, opened via `WasmDatabase.open(...)`, which probes the browser for the best available persistence backend (OPFS when available, falling back to IndexedDB) and runs the database in a Web Worker. This needs two static assets in your app's `web/` directory:
  - **`sqlite3.wasm`** — the compiled SQLite WebAssembly module, published as an asset of the `sqlite3` package. Copy it from `.dart_tool/pub/deps/... /sqlite3-<version>/example/web/sqlite3.wasm` (or the version drift's own example ships), or fetch the matching release asset directly — see the [drift Web docs](https://drift.simonbinder.eu/web/) for the current recommended source. **Deployment note:** your web server/hosting config must serve this file with the `Content-Type: application/wasm` header -- browsers refuse to `instantiateStreaming`/compile a `.wasm` module served with the wrong MIME type (e.g. a static-file server defaulting to `application/octet-stream`), which breaks the database at runtime even though the file itself is correct.
  - **`drift_worker.dart.js`** — the worker script that hosts the database. drift can generate this: `dart run drift_dev make-worker`. This is a one-time, optional dev-time step for apps that want the worker (not required by `velora_db`'s own tests, and not `build_runner` codegen for your app's *schema* -- there is none) — see the same drift Web docs page for the exact command and output location.

No code changes are needed between platforms — only these two files an app has to add for Web.

## Testing without a device

Inject drift's own in-memory `NativeDatabase` to run entirely headless, without any platform channel:

```dart
import 'package:drift/native.dart';

test('todos round-trip', () async {
  final plugin = VeloraDbPlugin(
    databaseName: ':memory:', // unused when executor is injected
    version: 1,
    migrations: [CreateTodosTable()],
    executor: NativeDatabase.memory(),
  );
  await plugin.register(context);

  final todos = VeloraDb.table<Todo, int>(
    table: 'todos',
    fromMap: Todo.fromMap,
    toMap: (todo) => todo.toMap(),
  );
  final created = await todos.create(const Todo(title: 'test').toMap());
  expect(created.id, isNotNull);
});
```

`NativeDatabase.memory()` keeps each test isolated and fast — no file ever touches disk, and reactive `watch()` streams work exactly the same as in a real app (see `velora_db`'s own `test/velora_reactive_test.dart` for `watchAll`/`watchQuery`/`watchFind` examples).

**For a real app, none of this is needed.** `package:sqlite3`'s build hook bundles a prebuilt native SQLite automatically, on-device and in host tests alike, with zero `pubspec.yaml` config -- the default behavior described above under Cross-platform.

**Why this repo's own packages/examples configure a hook anyway.** This repo's build environments (sandbox/CI) block the network call that hook makes to download its prebuilt binary. So every package/example here (`velora_db`, `velora_offline`, `velora_chat`, `velora_catalog`) vendors the official SQLite amalgamation source at `third_party/sqlite3/` (see its `README.md` for provenance and update steps) and points the hook at it instead:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: source
      path: <relative path to>/third_party/sqlite3/sqlite3.c
```

With `source: source`, the hook compiles this exact vendored copy of SQLite from source -- on host tests, in CI, and on real device/desktop builds of these repo's own examples -- so builds are reproducible and work fully offline, instead of depending on a network fetch. This only takes effect for the package/example that declares it when *it* is the root package being built (`hooks.user_defines` is read from the root package's pubspec, never a dependency's), so it's invisible to apps that merely depend on `velora_db`. If your own app wants the same offline/deterministic build behavior, vendor `third_party/sqlite3/sqlite3.c` (or your own copy of the amalgamation) and add the equivalent `hooks.user_defines.sqlite3` block to *your app's* `pubspec.yaml` — it won't be inherited from `velora_db`.

---

**See also:** [Plugins →](../plugins.md) for the `VeloraPlugin` / `VeloraContext` contract this package implements, and [velora_offline →](offline.md) for another official package built on the same contract.
