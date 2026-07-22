import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('VeloraMigrationRunner', () {
    test('onCreate runs all migrations in version order', () async {
      final applied = <int>[];
      final runner = VeloraMigrationRunner([
        _RecordingMigration(2, applied),
        _RecordingMigration(1, applied),
        _RecordingMigration(3, applied),
      ]);

      final context = _rawContext();
      await runner.onCreate(context, 3);
      expect(applied, [1, 2, 3]);
    });

    test('onUpgrade runs only migrations with version in (old, new]', () async {
      final applied = <int>[];
      final runner = VeloraMigrationRunner([
        _RecordingMigration(1, applied),
        _RecordingMigration(2, applied),
        _RecordingMigration(3, applied),
        _RecordingMigration(4, applied),
      ]);

      final context = _rawContext();
      await runner.onUpgrade(context, 2, 4);
      expect(applied, [3, 4]);
    });

    test('rejects duplicate versions with a clear ArgumentError', () {
      expect(
        () => VeloraMigrationRunner([
          _RecordingMigration(1, []),
          _RecordingMigration(1, []),
        ]),
        throwsArgumentError,
      );
    });

    test(
      'VeloraDatabase: opening at a higher version runs onUpgrade for the '
      'new migrations only, and PRAGMA user_version ends at the max version',
      () async {
        final dir = await Directory.systemTemp.createTemp('velora_db_test');
        final path = p.join(dir.path, 'upgrade_test.db');
        addTearDown(() => dir.delete(recursive: true));

        // Fresh database at version 1: only the v1 migration runs (onCreate).
        var db = await VeloraDatabase(
          databaseName: path,
          version: 1,
          migrations: [_CreateTodosTable()],
          executor: NativeDatabase(File(path)),
        ).open();
        expect(await _userVersion(db.db), 1);
        await db.db.customStatement(
          'INSERT INTO todos (title, done) VALUES (?, ?)',
          ['seed', 0],
        );
        await db.close();

        // Reopen at version 2 with an additional migration: only the v2
        // migration should run (onUpgrade), not v1 again.
        final upgradeCalls = <int>[];
        db = await VeloraDatabase(
          databaseName: path,
          version: 2,
          migrations: [
            _CreateTodosTable(),
            _AddArchivedColumn(onApplied: upgradeCalls),
          ],
          executor: NativeDatabase(File(path)),
        ).open();

        expect(upgradeCalls, [2]);
        expect(await _userVersion(db.db), 2);
        // The pre-existing row survived the upgrade, and the new column is
        // usable.
        final rows = await _select(db.db, 'SELECT * FROM todos');
        expect(rows, hasLength(1));
        await db.db.customStatement(
          'UPDATE todos SET archived = 1 WHERE title = ?',
          ['seed'],
        );
        final updated = await _select(
          db.db,
          'SELECT * FROM todos WHERE archived = ?',
          [1],
        );
        expect(updated, hasLength(1));
        await db.close();
      },
    );

    test(
      "drift's onUpgrade also fires for downgrades: reopening a persisted "
      'database at a lower version than its stored version does not throw '
      'and the database remains usable',
      () async {
        final dir = await Directory.systemTemp.createTemp(
          'velora_db_downgrade_test',
        );
        final path = p.join(dir.path, 'downgrade_test.db');
        addTearDown(() => dir.delete(recursive: true));

        final migrations = [_CreateTodosTable(), _AddArchivedColumn(onApplied: [])];

        // Open at version 2: both migrations run via onCreate.
        var db = await VeloraDatabase(
          databaseName: path,
          version: 2,
          migrations: migrations,
          executor: NativeDatabase(File(path)),
        ).open();
        expect(await _userVersion(db.db), 2);
        await db.db.customStatement(
          'INSERT INTO todos (title, done) VALUES (?, ?)',
          ['seed', 0],
        );
        await db.close();

        // Reopen at version 1 with the same migrations list. The persisted
        // PRAGMA user_version (2) is now higher than the requested version
        // (1), so drift's onUpgrade fires with from=2, to=1 -- routed to
        // VeloraMigrationRunner.onDowngrade.
        db = await VeloraDatabase(
          databaseName: path,
          version: 1,
          migrations: migrations,
          executor: NativeDatabase(File(path)),
        ).open();

        expect(await _userVersion(db.db), 1);
        // The database is still usable after the downgrade -- the
        // pre-existing row survived and the table can still be queried.
        final rows = await _select(db.db, 'SELECT * FROM todos');
        expect(rows, hasLength(1));
        expect(rows.single['title'], 'seed');
        await db.close();
      },
    );
  });

  group('QueryBuilder', () {
    late VeloraDatabase db;

    setUp(() async {
      db = await _openTodosDb();
      await db.db.customStatement(
        'INSERT INTO todos (title, done) VALUES (?, ?)',
        ['alpha', 0],
      );
      await db.db.customStatement(
        'INSERT INTO todos (title, done) VALUES (?, ?)',
        ['beta', 1],
      );
      await db.db.customStatement(
        'INSERT INTO todos (title, done) VALUES (?, ?)',
        ['gamma', 0],
      );
    });

    tearDown(() => db.close());

    test('where filters by equality', () async {
      final rows = await QueryBuilder('todos').where('title', 'beta').get(db.db);
      expect(rows, hasLength(1));
      expect(rows.single['title'], 'beta');
    });

    test('whereOp supports comparison operators', () async {
      final rows =
          await QueryBuilder('todos').whereOp('done', '!=', 0).get(db.db);
      expect(rows, hasLength(1));
      expect(rows.single['title'], 'beta');
    });

    test('whereOp rejects an unsupported operator', () {
      expect(
        () => QueryBuilder('todos').whereOp('done', 'OR 1=1 --', 0),
        throwsArgumentError,
      );
    });

    test('rejects an invalid column name', () {
      expect(
        () => QueryBuilder('todos').where('title; DROP TABLE todos', 'x'),
        throwsArgumentError,
      );
    });

    test('orderBy sorts ascending and descending', () async {
      final asc = await QueryBuilder('todos').orderBy('title').get(db.db);
      expect(asc.map((r) => r['title']), ['alpha', 'beta', 'gamma']);

      final desc =
          await QueryBuilder('todos').orderBy('title', desc: true).get(db.db);
      expect(desc.map((r) => r['title']), ['gamma', 'beta', 'alpha']);
    });

    test('limit and offset page through results', () async {
      final page = await QueryBuilder('todos')
          .orderBy('title')
          .limit(1)
          .offset(1)
          .get(db.db);
      expect(page, hasLength(1));
      expect(page.single['title'], 'beta');
    });

    test(
      'offset without limit still returns valid SQL and skips the first n '
      'rows (no limit applied)',
      () async {
        final rows = await QueryBuilder('todos')
            .orderBy('title')
            .offset(1)
            .get(db.db);
        expect(rows.map((r) => r['title']), ['beta', 'gamma']);
      },
    );

    test('first returns the first matching row or null', () async {
      final found = await QueryBuilder('todos').where('title', 'alpha').first(db.db);
      expect(found?['title'], 'alpha');

      final missing =
          await QueryBuilder('todos').where('title', 'nope').first(db.db);
      expect(missing, isNull);
    });

    test('count returns the number of matching rows', () async {
      expect(await QueryBuilder('todos').count(db.db), 3);
      expect(await QueryBuilder('todos').where('done', 0).count(db.db), 2);
    });

    test(
      'a value containing a quote or semicolon is bound as data, not SQL',
      () async {
        const dangerous = "O'Brien; DROP TABLE todos;--";
        await db.db.customStatement(
          'INSERT INTO todos (title, done) VALUES (?, ?)',
          [dangerous, 0],
        );

        final rows =
            await QueryBuilder('todos').where('title', dangerous).get(db.db);
        expect(rows, hasLength(1));
        expect(rows.single['title'], dangerous);

        // The table must still exist and contain all 4 rows -- if the value
        // had been interpolated instead of parameterized, the DROP TABLE
        // would have executed and this query would throw or return nothing.
        expect(await QueryBuilder('todos').count(db.db), 4);
      },
    );
  });

  group('QueryBuilder null handling', () {
    late VeloraDatabase db;

    setUp(() async {
      db = await VeloraDatabase(
        databaseName: ':memory:',
        version: 1,
        migrations: [_CreateEntriesTable()],
        executor: NativeDatabase.memory(),
      ).open();
      // deleted_at is left unset (NULL) on the two "active" rows.
      await db.db.customStatement(
        'INSERT INTO entries (name) VALUES (?)',
        ['active-1'],
      );
      await db.db.customStatement(
        'INSERT INTO entries (name, deleted_at) VALUES (?, ?)',
        ['deleted', '2024-01-01'],
      );
      await db.db.customStatement(
        'INSERT INTO entries (name) VALUES (?)',
        ['active-2'],
      );
    });

    tearDown(() => db.close());

    test(
      "where('col', null) compiles to 'col IS NULL' and matches only rows "
      'whose column is NULL, excluding non-null rows',
      () async {
        final rows =
            await QueryBuilder('entries').where('deleted_at', null).get(db.db);
        expect(rows, hasLength(2));
        expect(
          rows.map((r) => r['name']),
          containsAll(['active-1', 'active-2']),
        );
      },
    );

    test(
      "whereOp('col', '!=', null) compiles to 'col IS NOT NULL' and matches "
      'only rows whose column is non-null',
      () async {
        final rows = await QueryBuilder('entries')
            .whereOp('deleted_at', '!=', null)
            .get(db.db);
        expect(rows, hasLength(1));
        expect(rows.single['name'], 'deleted');
      },
    );

    test(
      'a normal equality comparison against a non-null value is unaffected '
      'by the null-to-IS rewrite',
      () async {
        final rows =
            await QueryBuilder('entries').where('name', 'deleted').get(db.db);
        expect(rows, hasLength(1));
        expect(rows.single['deleted_at'], '2024-01-01');
      },
    );
  });

  group('VeloraTable', () {
    late VeloraDatabase db;
    late VeloraTable<TodoModel, int> table;

    setUp(() async {
      db = await _openTodosDb();
      table = VeloraTable<TodoModel, int>(
        db: db.db,
        table: 'todos',
        fromMap: TodoModel.fromJson,
        toMap: (todo) => todo.toJson(),
      );
    });

    tearDown(() => db.close());

    test('insert then find round-trips a model', () async {
      final id = await table.insert(const TodoModel(title: 'Buy milk').toJson());
      final found = await table.find(id);
      expect(found, isNotNull);
      expect(found!.title, 'Buy milk');
      expect(found.done, isFalse);
    });

    test(
      'insert on an int-pk table with no id supplied returns the int rowid '
      'directly (the "rowId is ID" fast path)',
      () async {
        final id = await table.insert(const TodoModel(title: 'x').toJson());
        expect(id, isA<int>());
      },
    );

    test('create inserts and returns the hydrated model', () async {
      final created = await table.create(const TodoModel(title: 'Walk dog').toJson());
      expect(created.id, isNotNull);
      expect(created.title, 'Walk dog');
    });

    test('all returns every row', () async {
      await table.create(const TodoModel(title: 'one').toJson());
      await table.create(const TodoModel(title: 'two').toJson());
      final all = await table.all();
      expect(all.map((t) => t.title), containsAll(['one', 'two']));
    });

    test('where returns matching rows as models', () async {
      await table.create(const TodoModel(title: 'done-one', done: true).toJson());
      await table.create(const TodoModel(title: 'not-done', done: false).toJson());
      final done = await table.where('done', 1);
      expect(done, hasLength(1));
      expect(done.single.title, 'done-one');
    });

    test('update mutates the row', () async {
      final created = await table.create(const TodoModel(title: 'original').toJson());
      final affected = await table.update(created.id!, {'title': 'renamed'});
      expect(affected, 1);
      final reloaded = await table.find(created.id!);
      expect(reloaded!.title, 'renamed');
    });

    test('delete removes the row', () async {
      final created = await table.create(const TodoModel(title: 'temp').toJson());
      final affected = await table.delete(created.id!);
      expect(affected, 1);
      expect(await table.find(created.id!), isNull);
    });

    test('count reflects the number of rows', () async {
      expect(await table.count(), 0);
      await table.create(const TodoModel(title: 'x').toJson());
      await table.create(const TodoModel(title: 'y').toJson());
      expect(await table.count(), 2);
    });

    test(
      'insert rejects a malicious data key instead of splicing it into the '
      'column list',
      () async {
        expect(
          () => table.insert(const {
            'title': 'x',
            'x); DROP TABLE todos;--': 'y',
          }),
          throwsArgumentError,
        );

        // The table must still exist and be untouched -- if the key had been
        // interpolated instead of validated, the DROP TABLE would have
        // executed.
        expect(await table.count(), 0);
      },
    );

    test(
      'update rejects a malicious data key instead of splicing it into the '
      'SET clause',
      () async {
        final created = await table.create(const TodoModel(title: 'original').toJson());

        expect(
          () => table.update(created.id!, const {
            'x); DROP TABLE todos;--': 'y',
          }),
          throwsArgumentError,
        );

        // The row must still exist, untouched.
        final reloaded = await table.find(created.id!);
        expect(reloaded!.title, 'original');
      },
    );
  });

  group('VeloraTable with a String primary key', () {
    late VeloraDatabase db;
    late VeloraTable<UuidItemModel, String> table;

    setUp(() async {
      db = await VeloraDatabase(
        databaseName: ':memory:',
        version: 1,
        migrations: [_CreateItemsUuidTable()],
        executor: NativeDatabase.memory(),
      ).open();
      table = VeloraTable<UuidItemModel, String>(
        db: db.db,
        table: 'items_uuid',
        primaryKey: 'uuid',
        fromMap: UuidItemModel.fromJson,
        toMap: (item) => item.toJson(),
      );
    });

    tearDown(() => db.close());

    test(
      'create returns the hydrated model when the primary key is supplied '
      'by the caller (providedId path)',
      () async {
        final created = await table.create(
          const UuidItemModel(uuid: 'abc-123', name: 'explicit').toJson(),
        );
        expect(created.uuid, 'abc-123');
        expect(created.name, 'explicit');
      },
    );

    test(
      'create resolves a DB-generated String primary key by reading the row '
      'back by rowid, instead of crashing on an int-to-String cast',
      () async {
        final created = await table.create(
          const UuidItemModel(name: 'generated').toJson(),
        );
        expect(created.uuid, isNotNull);
        expect(created.uuid, isNotEmpty);
        expect(created.name, 'generated');

        // The resolved id round-trips through find().
        final found = await table.find(created.uuid!);
        expect(found!.name, 'generated');
      },
    );

    test(
      'conflictAlgorithm defaults to replace (overwrites a duplicate '
      'primary key); passing .abort throws on the same duplicate instead',
      () async {
        await table.create(
          const UuidItemModel(uuid: 'dup', name: 'first').toJson(),
        );

        // Default (replace) silently overwrites.
        final replaced = await table.create(
          const UuidItemModel(uuid: 'dup', name: 'second').toJson(),
        );
        expect(replaced.name, 'second');
        expect(await table.count(), 1);

        // Explicit abort throws instead of replacing.
        await expectLater(
          table.create(
            const UuidItemModel(uuid: 'dup', name: 'third').toJson(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          ),
          throwsA(isA<SqliteException>()),
        );
        // The aborted insert didn't touch the existing row.
        final row = await table.find('dup');
        expect(row!.name, 'second');
        expect(await table.count(), 1);
      },
    );
  });

  group('VeloraDbRepository', () {
    late VeloraDatabase db;
    late VeloraDbRepository<TodoModel, int> repository;

    setUp(() async {
      db = await _openTodosDb();
      final table = VeloraTable<TodoModel, int>(
        db: db.db,
        table: 'todos',
        fromMap: TodoModel.fromJson,
        toMap: (todo) => todo.toJson(),
      );
      repository = VeloraDbRepository<TodoModel, int>(table);
    });

    tearDown(() => db.close());

    test('store returns the created model with an id', () async {
      final created = await repository.store(const TodoModel(title: 'first').toJson());
      expect(created.id, isNotNull);
      expect(created.title, 'first');
    });

    test('index lists all stored models', () async {
      await repository.store(const TodoModel(title: 'a').toJson());
      await repository.store(const TodoModel(title: 'b').toJson());
      final all = await repository.index();
      expect(all, hasLength(2));
    });

    test('show returns the model by id', () async {
      final created = await repository.store(const TodoModel(title: 'findme').toJson());
      final shown = await repository.show(created.id!);
      expect(shown.title, 'findme');
    });

    test('show throws for a missing id', () async {
      expect(() => repository.show(999999), throwsA(isA<StateError>()));
    });

    test('update mutates and returns the model', () async {
      final created = await repository.store(const TodoModel(title: 'old').toJson());
      final updated = await repository.update(created.id!, {'title': 'new'});
      expect(updated.title, 'new');
    });

    test('destroy removes the model', () async {
      final created = await repository.store(const TodoModel(title: 'bye').toJson());
      await repository.destroy(created.id!);
      expect(() => repository.show(created.id!), throwsA(isA<StateError>()));
    });
  });

  group('VeloraDbPlugin', () {
    test(
      'a bare VeloraDbPlugin(executor: ...) — all other params defaulted — '
      'registers and opens a working empty database',
      () async {
        // This mirrors exactly what `velora install velora_db` wires into
        // `Velora.boot(plugins: [VeloraDbPlugin()])` — no databaseName,
        // version, or migrations supplied — except an in-memory executor is
        // injected here so the test runs headless and never touches disk.
        const config = VeloraConfig(appName: 'Test', apiBaseUrl: 'https://example.test');
        final context = VeloraContext(config);
        Get.put<VeloraLifecycleRegistry>(VeloraLifecycleRegistry());

        final plugin = VeloraDbPlugin(executor: NativeDatabase.memory());
        await plugin.register(context);

        expect(plugin.databaseName, 'app.db');
        expect(plugin.version, 1);
        expect(plugin.migrations, isEmpty);
        expect(VeloraDb.instance, isA<VeloraDatabase>());

        // The empty database is still usable: create a table by hand and
        // query it through the facade, proving the connection is live.
        await VeloraDb.db.customStatement('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0
          )
        ''');
        final table = VeloraDb.table<TodoModel, int>(
          table: 'todos',
          fromMap: TodoModel.fromJson,
          toMap: (todo) => todo.toJson(),
        );
        final created = await table.create(const TodoModel(title: 'default-ctor').toJson());
        expect(created.title, 'default-ctor');
        expect(await table.count(), 1);

        await VeloraDb.instance.close();
      },
    );

    test('register opens a working, queryable database', () async {
      const config = VeloraConfig(appName: 'Test', apiBaseUrl: 'https://example.test');
      final context = VeloraContext(config);
      Get.put<VeloraLifecycleRegistry>(VeloraLifecycleRegistry());

      final plugin = VeloraDbPlugin(
        databaseName: ':memory:',
        version: 1,
        migrations: [_CreateTodosTable()],
        executor: NativeDatabase.memory(),
      );
      await plugin.register(context);

      expect(VeloraDb.instance, isA<VeloraDatabase>());
      final table = VeloraDb.table<TodoModel, int>(
        table: 'todos',
        fromMap: TodoModel.fromJson,
        toMap: (todo) => todo.toJson(),
      );
      final created = await table.create(const TodoModel(title: 'via facade').toJson());
      expect(created.title, 'via facade');
      expect(await table.count(), 1);

      await VeloraDb.instance.close();
    });

    test(
      'clearOnLogout wipes only the listed table, keeps others and the '
      'connection intact',
      () async {
        const config = VeloraConfig(appName: 'Test', apiBaseUrl: 'https://example.test');
        final context = VeloraContext(config);
        final lifecycle = VeloraLifecycleRegistry();
        Get.put<VeloraLifecycleRegistry>(lifecycle);

        final plugin = VeloraDbPlugin(
          databaseName: ':memory:',
          version: 2,
          migrations: [_CreateTodosTable(), _CreateNotesTable()],
          executor: NativeDatabase.memory(),
          clearOnLogout: ['todos'],
        );
        await plugin.register(context);

        final db = VeloraDb.instance;
        await db.db.customStatement(
          'INSERT INTO todos (title, done) VALUES (?, ?)',
          ['secret todo', 0],
        );
        await db.db.customStatement(
          'INSERT INTO notes (body) VALUES (?)',
          ['keep me'],
        );

        await lifecycle.beforeLogout();

        final todos = await _select(db.db, 'SELECT * FROM todos');
        expect(todos, isEmpty);

        // Non-listed table is untouched and the connection is still open.
        final notes = await _select(db.db, 'SELECT * FROM notes');
        expect(notes, hasLength(1));
        expect(notes.single['body'], 'keep me');

        await db.close();
      },
    );

    test(
      'onLogout callback runs a custom delete against the live db',
      () async {
        const config = VeloraConfig(appName: 'Test', apiBaseUrl: 'https://example.test');
        final context = VeloraContext(config);
        final lifecycle = VeloraLifecycleRegistry();
        Get.put<VeloraLifecycleRegistry>(lifecycle);

        var onLogoutCalled = false;
        final plugin = VeloraDbPlugin(
          databaseName: ':memory:',
          version: 1,
          migrations: [_CreateNotesTable()],
          executor: NativeDatabase.memory(),
          onLogout: (db) async {
            onLogoutCalled = true;
            await db.customStatement(
              'DELETE FROM notes WHERE body = ?',
              ['secret'],
            );
          },
        );
        await plugin.register(context);

        final db = VeloraDb.instance;
        await db.db.customStatement('INSERT INTO notes (body) VALUES (?)', ['secret']);
        await db.db.customStatement('INSERT INTO notes (body) VALUES (?)', ['public']);

        await lifecycle.beforeLogout();

        expect(onLogoutCalled, isTrue);
        final remaining = await _select(db.db, 'SELECT * FROM notes');
        expect(remaining, hasLength(1));
        expect(remaining.single['body'], 'public');

        await db.close();
      },
    );

    test(
      'registers no logout hook when neither clearOnLogout nor onLogout is set',
      () async {
        const config = VeloraConfig(appName: 'Test', apiBaseUrl: 'https://example.test');
        final context = VeloraContext(config);
        final lifecycle = VeloraLifecycleRegistry();
        Get.put<VeloraLifecycleRegistry>(lifecycle);

        final plugin = VeloraDbPlugin(
          databaseName: ':memory:',
          version: 1,
          migrations: [_CreateTodosTable()],
          executor: NativeDatabase.memory(),
        );
        await plugin.register(context);

        final db = VeloraDb.instance;
        await db.db.customStatement(
          'INSERT INTO todos (title, done) VALUES (?, ?)',
          ['stays', 0],
        );

        // Should not throw and should not touch the data -- there is simply
        // no participant registered for this plugin.
        await lifecycle.beforeLogout();

        expect(await _select(db.db, 'SELECT * FROM todos'), hasLength(1));
        await db.close();
      },
    );
  });
}

/// A minimal, unopened [VeloraMigrationContext] backed by its own throwaway
/// in-memory database -- used to unit-test [VeloraMigrationRunner] in
/// isolation, independent of a full [VeloraDatabase]. The migrations
/// exercised in these tests never call [VeloraMigrationContext.execute], so
/// the underlying database is never actually touched.
VeloraMigrationContext _rawContext() {
  final raw = VeloraSqlDatabase(
    NativeDatabase.memory(),
    schemaVersion: 1,
    runner: VeloraMigrationRunner(const []),
  );
  return VeloraMigrationContext(raw);
}

Future<VeloraDatabase> _openTodosDb() {
  return VeloraDatabase(
    databaseName: ':memory:',
    version: 1,
    migrations: [_CreateTodosTable()],
    executor: NativeDatabase.memory(),
  ).open();
}

/// Reads the current `PRAGMA user_version` -- drift's on-disk record of
/// [VeloraDatabase.version], the thing sqflite exposed as `getVersion()`.
Future<int> _userVersion(VeloraSqlDatabase db) async {
  final row = await db.customSelect('PRAGMA user_version').getSingle();
  return row.data['user_version'] as int;
}

/// Runs a raw `SELECT` and returns its rows as plain maps -- used in tests
/// that assert on table contents without going through [VeloraTable].
Future<List<Map<String, dynamic>>> _select(
  VeloraSqlDatabase db,
  String sql, [
  List<Object?> args = const [],
]) async {
  final rows = await db
      .customSelect(sql, variables: args.map((v) => Variable<Object>(v)).toList())
      .get();
  return rows.map((row) => row.data).toList();
}

class _RecordingMigration extends VeloraMigration {
  @override
  final int version;
  final List<int> applied;

  _RecordingMigration(this.version, this.applied);

  @override
  Future<void> up(VeloraMigrationContext context) async {
    applied.add(version);
  }
}

class _CreateTodosTable extends VeloraMigration {
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

class _CreateNotesTable extends VeloraMigration {
  @override
  int get version => 2;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        body TEXT NOT NULL
      )
    ''');
  }
}

class _AddArchivedColumn extends VeloraMigration {
  final List<int> onApplied;

  _AddArchivedColumn({required this.onApplied});

  @override
  int get version => 2;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    onApplied.add(version);
    await context.execute(
      'ALTER TABLE todos ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
    );
  }
}

class _CreateEntriesTable extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
  }
}

/// A table keyed by a `TEXT` primary key with a SQL-side default, so an
/// insert that doesn't supply `uuid` still gets one assigned by SQLite
/// itself (not by the app) -- this is the case where the raw drift insert's
/// rowid (an `int`) is not a valid `String` id on its own, and
/// `VeloraTable.insert` must read the row back by `rowid` to recover it.
class _CreateItemsUuidTable extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE items_uuid (
        uuid TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(4)))),
        name TEXT NOT NULL
      )
    ''');
  }
}

/// Sample model used only in this test suite, mirroring the plain-Dart model
/// convention (`const` constructor, `fromJson`/`toJson`) used across Velora
/// packages -- not part of `velora_db`'s public API.
class TodoModel {
  final int? id;
  final String title;
  final bool done;

  const TodoModel({this.id, required this.title, this.done = false});

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      done: json['done'] == 1 || json['done'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'done': done ? 1 : 0,
    };
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

/// Sample model with a `String` (UUID-shaped) primary key, used only in this
/// test suite to exercise `VeloraTable`'s non-int id resolution path.
class UuidItemModel {
  final String? uuid;
  final String name;

  const UuidItemModel({this.uuid, required this.name});

  factory UuidItemModel.fromJson(Map<String, dynamic> json) {
    return UuidItemModel(
      uuid: json['uuid']?.toString(),
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (uuid != null) 'uuid': uuid,
      'name': name,
    };
  }
}
