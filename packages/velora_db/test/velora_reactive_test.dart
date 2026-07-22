import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_db/velora_db.dart';

/// Tests for the reactive (Dexie-`liveQuery`-style) surface added on top of
/// the drift engine swap: [VeloraTable.watchAll], [VeloraTable.watchQuery],
/// and [VeloraTable.watchFind]. Every write path in `velora_db`
/// (`insert`/`update`/`delete`, and `VeloraCachedRepository`'s batched cache
/// writes) calls `notifyUpdates` for the affected table, which is what makes
/// these streams re-emit -- see `query_builder.dart`'s `watch()` and
/// `velora_sql_database.dart` for the underlying `tableUpdates`/
/// `notifyUpdates` machinery this proves out.
void main() {
  late VeloraDatabase db;
  late VeloraTable<TodoModel, int> table;

  setUp(() async {
    db = await VeloraDatabase(
      databaseName: ':memory:',
      version: 1,
      migrations: [_CreateTodosTable()],
      executor: NativeDatabase.memory(),
    ).open();
    table = VeloraTable<TodoModel, int>(
      db: db.db,
      table: 'todos',
      fromMap: TodoModel.fromJson,
      toMap: (todo) => todo.toJson(),
    );
  });

  tearDown(() => db.close());

  /// Lets pending microtasks (the async `emit()` triggered by a write or by
  /// subscribing) resolve before the next assertion. `NativeDatabase.memory()`
  /// runs entirely synchronously/via microtasks in this isolate (no
  /// background isolate hop), so a single event-loop tick is enough.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('VeloraTable.watchAll', () {
    test(
      'emits the current rows immediately, then re-emits after insert, '
      'update, and delete',
      () async {
        final emissions = <List<TodoModel>>[];
        final sub = table.watchAll().listen(emissions.add);
        addTearDown(sub.cancel);

        await settle();
        expect(emissions, hasLength(1));
        expect(emissions.single, isEmpty);

        final created = await table.create(
          const TodoModel(title: 'alpha').toJson(),
        );
        await settle();
        expect(emissions, hasLength(2));
        expect(emissions.last.map((t) => t.title), ['alpha']);

        await table.update(created.id!, {'title': 'alpha-renamed'});
        await settle();
        expect(emissions, hasLength(3));
        expect(emissions.last.single.title, 'alpha-renamed');

        await table.delete(created.id!);
        await settle();
        expect(emissions, hasLength(4));
        expect(emissions.last, isEmpty);
      },
    );

    test(
      'is broadcast-friendly: two independent listeners each get their own '
      'initial emission and independently see subsequent writes, and '
      'cancelling one does not affect the other',
      () async {
        final first = <List<TodoModel>>[];
        final second = <List<TodoModel>>[];
        final subA = table.watchAll().listen(first.add);
        await settle();

        final subB = table.watchAll().listen(second.add);
        addTearDown(subB.cancel);
        await settle();

        // `first` has an initial emission from subA's own subscribe, plus
        // whatever it's seen since; `second` gets its own initial emission
        // now, independent of `first`'s history.
        expect(first, isNotEmpty);
        expect(second, hasLength(1));
        expect(second.single, isEmpty);

        await table.create(const TodoModel(title: 'shared').toJson());
        await settle();
        expect(first.last.map((t) => t.title), ['shared']);
        expect(second.last.map((t) => t.title), ['shared']);

        // Cancelling subA must not disturb subB's stream.
        await subA.cancel();
        final secondCountBeforeMoreWrites = second.length;

        await table.create(const TodoModel(title: 'after-cancel').toJson());
        await settle();
        expect(second.length, greaterThan(secondCountBeforeMoreWrites));
        expect(
          second.last.map((t) => t.title),
          containsAll(['shared', 'after-cancel']),
        );
      },
    );
  });

  group('VeloraTable.watchFind', () {
    test('reflects updates and deletes to the watched row', () async {
      final created = await table.create(const TodoModel(title: 'first').toJson());

      final emissions = <TodoModel?>[];
      final sub = table.watchFind(created.id!).listen(emissions.add);
      addTearDown(sub.cancel);

      await settle();
      expect(emissions, hasLength(1));
      expect(emissions.single?.title, 'first');

      await table.update(created.id!, {'title': 'second'});
      await settle();
      expect(emissions, hasLength(2));
      expect(emissions.last?.title, 'second');

      await table.delete(created.id!);
      await settle();
      expect(emissions, hasLength(3));
      expect(emissions.last, isNull);
    });

    test('emits null immediately when the row never existed', () async {
      final emissions = <TodoModel?>[];
      final sub = table.watchFind(12345).listen(emissions.add);
      addTearDown(sub.cancel);

      await settle();
      expect(emissions, hasLength(1));
      expect(emissions.single, isNull);
    });
  });

  group('VeloraTable.watchQuery', () {
    test(
      're-emits when a row starts or stops matching the filter',
      () async {
        await table.create(const TodoModel(title: 'keep', done: false).toJson());
        final target = await table.create(
          const TodoModel(title: 'flip', done: false).toJson(),
        );

        final emissions = <List<TodoModel>>[];
        final sub = table
            .watchQuery(table.query().where('done', 1))
            .listen(emissions.add);
        addTearDown(sub.cancel);

        await settle();
        expect(emissions, hasLength(1));
        expect(emissions.single, isEmpty);

        await table.update(target.id!, {'done': 1});
        await settle();
        expect(emissions, hasLength(2));
        expect(emissions.last.map((t) => t.title), ['flip']);

        await table.update(target.id!, {'done': 0});
        await settle();
        expect(emissions, hasLength(3));
        expect(emissions.last, isEmpty);
      },
    );

    test(
      'supports reactive pagination via orderBy + limit/offset, re-running '
      'on every write',
      () async {
        await table.create(const TodoModel(title: 'a').toJson());
        await table.create(const TodoModel(title: 'b').toJson());

        final emissions = <List<TodoModel>>[];
        final sub = table
            .watchQuery(table.query().orderBy('title').limit(2))
            .listen(emissions.add);
        addTearDown(sub.cancel);

        await settle();
        expect(emissions, hasLength(1));
        expect(emissions.single.map((t) => t.title), ['a', 'b']);

        // A new row that sorts first pushes 'b' out of the first page.
        await table.create(const TodoModel(title: '0-first').toJson());
        await settle();
        expect(emissions, hasLength(2));
        expect(emissions.last.map((t) => t.title), ['0-first', 'a']);
      },
    );
  });
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

/// Mirrors the other test files' own `TodoModel` -- kept separate so this
/// file can run standalone.
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
