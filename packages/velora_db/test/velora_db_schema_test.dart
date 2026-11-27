import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('VeloraDbSchema', () {
    test('has expected defaults', () {
      const schema = VeloraDbSchema();
      expect(schema.databaseName, 'app.db');
      expect(schema.version, 1);
      expect(schema.migrations, isEmpty);
      expect(schema.clearOnLogout, isEmpty);
    });

    test('preserves provided configuration', () {
      final migrations = [_CreateTodosMigration()];
      final schema = VeloraDbSchema(
        databaseName: 'notes.db',
        version: 3,
        migrations: migrations,
        clearOnLogout: const ['todos', 'sessions'],
      );

      expect(schema.databaseName, 'notes.db');
      expect(schema.version, 3);
      expect(schema.migrations, same(migrations));
      expect(schema.clearOnLogout, ['todos', 'sessions']);
    });
  });

  group('VeloraDatabase.inMemory', () {
    test('opens, runs migrations, and supports reading and writing', () async {
      final schema = VeloraDbSchema(
        databaseName: 'test.db',
        version: 2,
        migrations: [_CreateTodosMigration(), _AddDoneColumnMigration()],
      );

      final database = await VeloraDatabase.inMemory(schema).open();
      addTearDown(database.close);

      final versionRows = await database.db
          .customSelect('PRAGMA user_version')
          .get();
      expect(versionRows.single.read<int>('user_version'), 2);

      await database.db.customStatement(
        'INSERT INTO todos (title, done) VALUES (?, ?)',
        ['Write schema tests', 1],
      );

      final rows = await database.db
          .customSelect('SELECT title, done FROM todos')
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.read<String>('title'), 'Write schema tests');
      expect(rows.single.read<int>('done'), 1);
    });
  });

  group('VeloraDbPlugin.fromSchema', () {
    test('registers database from schema and clears clearOnLogout tables on logout', () async {
      const config = VeloraConfig(
        appName: 'Test',
        apiBaseUrl: 'https://example.test',
      );
      final context = VeloraContext(config);
      final lifecycle = VeloraLifecycleRegistry();
      Get.put<VeloraLifecycleRegistry>(lifecycle);

      final schema = VeloraDbSchema(
        databaseName: 'plugin_test.db',
        version: 2,
        migrations: [_CreateTodosMigration(), _AddDoneColumnMigration()],
        clearOnLogout: const ['todos'],
      );

      var onLogoutCalled = false;
      final plugin = VeloraDbPlugin.fromSchema(
        schema,
        executor: NativeDatabase.memory(),
        onLogout: (db) async {
          onLogoutCalled = true;
        },
      );

      expect(plugin.databaseName, 'plugin_test.db');
      expect(plugin.version, 2);
      expect(plugin.migrations, hasLength(2));
      expect(plugin.clearOnLogout, ['todos']);

      await plugin.register(context);

      final db = VeloraDb.instance;
      addTearDown(db.close);

      await db.db.customStatement(
        'INSERT INTO todos (title, done) VALUES (?, ?)',
        ['Ephemeral item', 0],
      );
      expect(
        await db.db.customSelect('SELECT * FROM todos').get(),
        hasLength(1),
      );

      await lifecycle.beforeLogout();

      expect(onLogoutCalled, isTrue);
      expect(await db.db.customSelect('SELECT * FROM todos').get(), isEmpty);
    });
  });
}

class _CreateTodosMigration extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext db) async {
    await db.execute(
      'CREATE TABLE todos (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL)',
    );
  }
}

class _AddDoneColumnMigration extends VeloraMigration {
  @override
  int get version => 2;

  @override
  Future<void> up(VeloraMigrationContext db) async {
    await db.execute(
      'ALTER TABLE todos ADD COLUMN done INTEGER NOT NULL DEFAULT 0',
    );
  }
}
