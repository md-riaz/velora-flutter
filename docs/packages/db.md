# velora_db

**What you'll do:** Install `velora_db`, wire it into `Velora.boot`, define a table with a migration, and query it through the Eloquent-style facade — on native and Web, and in tests without a device.

---

## What it does

`velora_db` is a cross-platform local database plugin: a sqflite-backed store with an Eloquent-style query API, built on the same [Velora plugin](../plugins.md) contract as `velora_offline`. It adds:

- **`VeloraDatabase`** — opens and owns a versioned sqflite database, applying a list of `VeloraMigration`s deterministically on create/upgrade.
- **`QueryBuilder`** — an immutable, fluent, allowlisted query builder (`where`, `whereOp`, `orderBy`, `limit`, `offset`) that always binds values as parameters, never interpolates them.
- **`VeloraTable<T, ID>`** — maps rows of a single table to/from a model type, with `all`/`find`/`where`/`insert`/`create`/`update`/`delete`/`count`.
- **`VeloraDbRepository<T, ID>`** — adapts a `VeloraTable` to Velora's `VeloraRepository` contract, so a local table is a drop-in repository alongside remote-backed ones.

It works identically on native (via `sqflite`) and Web (via `sqflite_common_ffi_web`, persisting to IndexedDB) — see [Cross-platform](#cross-platform) below.

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

**Web only:** run this once to add the SQLite WASM/worker assets `sqflite_common_ffi_web` needs:

```bash
dart run sqflite_common_ffi_web:setup
```

## Boot

```dart
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

class CreateTodosTable extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
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

## Clearing user data on logout

The database **connection** is app-lifetime — `VeloraDbPlugin` opens it once and never closes it on logout. But some of the **data** in it can be user-scoped (a permission cache, cached message history, etc.) and shouldn't leak to the next account on a shared device. Two hooks run during the logout `beforeLogout` phase for exactly that, deleting rows without touching the schema or connection:

```dart
VeloraDbPlugin(
  databaseName: 'app.db',
  version: 1,
  migrations: [CreateTodosTable()],
  // Blanket `DELETE FROM <table>` for simple whole-table wipes.
  clearOnLogout: ['messages', 'permission_cache'],
  // Anything more selective — a WHERE clause, a VACUUM — via a callback,
  // which runs after clearOnLogout's deletes.
  onLogout: (db) async {
    await db.delete('notes', where: 'user_scoped = ?', whereArgs: [1]);
  },
);
```

## Cross-platform

`VeloraDatabase` opens its connection through a `DatabaseFactory`, resolved by a conditional-import seam so the same `VeloraDbPlugin`/`VeloraDb`/`VeloraTable` API works everywhere:

- **Native** (iOS/Android/desktop): the default `sqflite` factory, backed by the platform's real SQLite.
- **Web**: `sqflite_common_ffi_web`'s factory, which persists to IndexedDB transparently — run `dart run sqflite_common_ffi_web:setup` once per app to install the required WASM/worker assets (see [Install](#install)).

No code changes are needed between platforms — only the `factory` an app never has to touch directly.

## Testing without a device

Inject `sqflite_common_ffi`'s factory to run entirely headless, without any platform channel:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

setUpAll(() {
  sqfliteFfiInit();
});

test('todos round-trip', () async {
  final plugin = VeloraDbPlugin(
    databaseName: inMemoryDatabasePath,
    version: 1,
    migrations: [CreateTodosTable()],
    factory: databaseFactoryFfi,
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

`inMemoryDatabasePath` keeps each test isolated and fast — no file ever touches disk.

---

**See also:** [Plugins →](../plugins.md) for the `VeloraPlugin` / `VeloraContext` contract this package implements, and [velora_offline →](offline.md) for another official package built on the same contract.
