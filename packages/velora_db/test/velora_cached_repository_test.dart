import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';

void main() {
  group('VeloraCachedRepository', () {
    late VeloraDatabase db;
    late VeloraTable<TodoModel, int> table;
    late _FakeRemote remote;
    late VeloraCachedRepository<TodoModel, int> repository;

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
      remote = _FakeRemote();
      repository = VeloraCachedRepository<TodoModel, int>(
        remote: remote,
        cache: table,
      );
    });

    tearDown(() => db.close());

    test(
      'index() online returns remote data and populates the cache',
      () async {
        remote.items = [
          const TodoModel(id: 1, title: 'alpha'),
          const TodoModel(id: 2, title: 'beta'),
        ];

        final result = await repository.index();
        expect(result.map((t) => t.title), ['alpha', 'beta']);

        final cached = await table.all();
        expect(cached, hasLength(2));
        expect(cached.map((t) => t.title), containsAll(['alpha', 'beta']));
      },
    );

    test(
      'index() online with many items populates the cache with every row '
      'via a single batched write',
      () async {
        remote.items = List.generate(
          5,
          (i) => TodoModel(id: i + 1, title: 'item-${i + 1}'),
        );

        final result = await repository.index();
        expect(result, hasLength(5));
        expect(
          result.map((t) => t.title),
          ['item-1', 'item-2', 'item-3', 'item-4', 'item-5'],
        );

        final cached = await table.all();
        expect(cached, hasLength(5));
        expect(
          cached.map((t) => t.title),
          containsAll(['item-1', 'item-2', 'item-3', 'item-4', 'item-5']),
        );
      },
    );

    test(
      'index() offline (connectionError) returns the previously-cached rows',
      () async {
        // Prime the cache via a successful online call first.
        remote.items = [const TodoModel(id: 1, title: 'cached-one')];
        await repository.index();

        // Now the remote goes offline.
        remote.indexError = _connectionErrorDioException();
        final result = await repository.index();
        expect(result, hasLength(1));
        expect(result.single.title, 'cached-one');
      },
    );

    test('show(id) online caches the row', () async {
      remote.showResponses[1] = const TodoModel(id: 1, title: 'shown');

      final shown = await repository.show(1);
      expect(shown.title, 'shown');

      final cached = await table.find(1);
      expect(cached, isNotNull);
      expect(cached!.title, 'shown');
    });

    test('show(id) offline returns the cached row', () async {
      remote.showResponses[1] = const TodoModel(id: 1, title: 'shown-first');
      await repository.show(1);

      remote.showError = _connectionErrorDioException();
      final shown = await repository.show(1);
      expect(shown.title, 'shown-first');
    });

    test(
      'show(missing) offline rethrows the original offline error (never '
      'cached, so nothing to fall back to)',
      () async {
        final offlineError = _connectionErrorDioException();
        remote.showError = offlineError;

        await expectLater(
          repository.show(999),
          throwsA(same(offlineError)),
        );
      },
    );

    test(
      'a non-offline error from index() (badResponse) is rethrown, not '
      'swallowed into a cache read',
      () async {
        remote.items = [const TodoModel(id: 1, title: 'primed')];
        await repository.index();

        remote.indexError = DioException(
          requestOptions: RequestOptions(path: '/todos'),
          type: DioExceptionType.badResponse,
        );

        await expectLater(
          repository.index(),
          throwsA(isA<DioException>()),
        );
      },
    );

    test(
      'a non-offline, non-Dio error from show() is rethrown, not swallowed '
      'into a cache read',
      () async {
        remote.showResponses[1] = const TodoModel(id: 1, title: 'primed');
        await repository.show(1);

        remote.showError = Exception('server exploded');

        await expectLater(
          repository.show(1),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'store() returns the remote result and the cache reflects it',
      () async {
        remote.storeResult = const TodoModel(id: 5, title: 'created');

        final created = await repository.store({'title': 'created'});
        expect(created.title, 'created');

        final cached = await table.find(5);
        expect(cached, isNotNull);
        expect(cached!.title, 'created');
      },
    );

    test(
      'update() returns the remote result and the cache reflects it',
      () async {
        remote.showResponses[7] = const TodoModel(id: 7, title: 'before');
        await repository.show(7);

        remote.updateResult = const TodoModel(id: 7, title: 'after');
        final updated = await repository.update(7, {'title': 'after'});
        expect(updated.title, 'after');

        final cached = await table.find(7);
        expect(cached!.title, 'after');
      },
    );

    test('destroy() removes the row from the cache', () async {
      remote.showResponses[9] = const TodoModel(id: 9, title: 'to-delete');
      await repository.show(9);
      expect(await table.find(9), isNotNull);

      await repository.destroy(9);
      expect(await table.find(9), isNull);
    });

    test(
      'defaultIsOfflineError classifies SocketException and TimeoutException '
      'as offline, and a generic Exception as not offline',
      () {
        expect(
          defaultIsOfflineError(const SocketException('unreachable')),
          isTrue,
        );
        expect(
          defaultIsOfflineError(TimeoutException('too slow')),
          isTrue,
        );
        expect(defaultIsOfflineError(Exception('nope')), isFalse);
      },
    );

    test(
      'defaultIsOfflineError classifies a normalized ApiException with '
      'isConnectionError set as offline, but a plain ApiException (e.g. a '
      '404/500 that reached the server) as not offline',
      () {
        expect(
          defaultIsOfflineError(
            const ApiException(
              message: 'Connection failed',
              isConnectionError: true,
            ),
          ),
          isTrue,
        );
        expect(
          defaultIsOfflineError(
            const ApiException(message: 'Not found', statusCode: 404),
          ),
          isFalse,
        );
      },
    );

    test(
      'index() offline via a NORMALIZED ApiException (isConnectionError: '
      'true, as VeloraApiService produces for a real connection failure) '
      'still returns the previously-cached rows -- this is the case that '
      'raw-DioException-only detection would miss',
      () async {
        remote.items = [const TodoModel(id: 1, title: 'cached-via-api-exc')];
        await repository.index();

        remote.indexError = const ApiException(
          message: 'Failed host lookup',
          isConnectionError: true,
        );
        final result = await repository.index();
        expect(result, hasLength(1));
        expect(result.single.title, 'cached-via-api-exc');
      },
    );

    test(
      'show(id) offline via a normalized ApiException (isConnectionError: '
      'true) returns the cached row',
      () async {
        remote.showResponses[1] = const TodoModel(
          id: 1,
          title: 'shown-via-api-exc',
        );
        await repository.show(1);

        remote.showError = const ApiException(
          message: 'Connection timed out',
          isConnectionError: true,
        );
        final shown = await repository.show(1);
        expect(shown.title, 'shown-via-api-exc');
      },
    );

    test(
      'a plain (non-connection) ApiException from index() is rethrown, not '
      'swallowed into a cache read',
      () async {
        remote.items = [const TodoModel(id: 1, title: 'primed')];
        await repository.index();

        remote.indexError = const ApiException(
          message: 'Internal Server Error',
          statusCode: 500,
        );

        await expectLater(
          repository.index(),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });
}

DioException _connectionErrorDioException() => DioException(
  requestOptions: RequestOptions(path: '/todos'),
  type: DioExceptionType.connectionError,
);

/// A controllable fake [VeloraRemoteDataSource] for exercising
/// [VeloraCachedRepository]'s network-first / offline-fallback behavior
/// without a real network.
class _FakeRemote implements VeloraRemoteDataSource<TodoModel, int> {
  List<TodoModel> items = [];
  Object? indexError;

  final Map<int, TodoModel> showResponses = {};
  Object? showError;

  TodoModel? storeResult;
  TodoModel? updateResult;

  @override
  Future<List<TodoModel>> index() async {
    if (indexError != null) throw indexError!;
    return items;
  }

  @override
  Future<TodoModel> show(int id) async {
    if (showError != null) throw showError!;
    final model = showResponses[id];
    if (model == null) {
      throw StateError('No fake response registered for id $id');
    }
    return model;
  }

  @override
  Future<TodoModel> store(Map<String, dynamic> data) async {
    return storeResult ?? TodoModel.fromJson(data);
  }

  @override
  Future<TodoModel> update(int id, Map<String, dynamic> data) async {
    return updateResult ?? TodoModel.fromJson({'id': id, ...data});
  }

  @override
  Future<void> destroy(int id) async {}
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

/// Mirrors the test suite's own `TodoModel` in velora_db_test.dart -- kept
/// separate here so this file can run standalone.
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
