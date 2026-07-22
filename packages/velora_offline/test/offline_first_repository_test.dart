import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  group('VeloraOfflineFirstRepository', () {
    late VeloraSqlDatabase db;
    late VeloraTable<Map<String, dynamic>, String> table;
    late _RecordingQueue queue;

    Future<VeloraOfflineFirstRepository<Map<String, dynamic>, String>>
        buildRepo({bool online = true}) async {
      db = VeloraSqlDatabase(
        NativeDatabase.memory(),
        schemaVersion: 1,
        runner: VeloraMigrationRunner(const []),
      );
      await db.customStatement(
        'CREATE TABLE todos (id TEXT PRIMARY KEY, title TEXT)',
      );
      table = VeloraTable<Map<String, dynamic>, String>(
        db: db,
        table: 'todos',
        fromMap: (row) => row,
        toMap: (model) => model,
      );

      final storage = await VeloraStorageService().init();
      final api = VeloraApiService(
        config: const VeloraConfig(
          appName: 'Test',
          apiBaseUrl: 'https://example.test',
        ),
        storage: storage,
      );
      queue = _RecordingQueue(storage: storage, api: api);
      await queue.load();

      final connectivity = await ConnectivityService(
        _FakeConnectivitySource(initial: online),
      ).init();

      return VeloraOfflineFirstRepository<Map<String, dynamic>, String>(
        table: table,
        queue: queue,
        connectivity: connectivity,
        endpoint: 'todos',
      );
    }

    tearDown(() async {
      await db.close();
    });

    test(
      'store writes the row locally and enqueues exactly one POST',
      () async {
        final repo = await buildRepo();

        final created = await repo.store({'id': '1', 'title': 'Buy milk'});
        expect(created['title'], 'Buy milk');

        final found = await table.find('1');
        expect(found, isNotNull);
        expect(found!['title'], 'Buy milk');

        expect(queue.enqueued, hasLength(1));
        expect(queue.enqueued.single.method, 'POST');
        expect(queue.enqueued.single.path, 'todos');
        expect(queue.enqueued.single.data, {'id': '1', 'title': 'Buy milk'});
      },
    );

    test(
      'watchAll emits the new row after store (reactive read through the '
      'real drift table)',
      () async {
        final repo = await buildRepo();

        final emissions = <List<Map<String, dynamic>>>[];
        final subscription = repo.watchAll().listen(emissions.add);
        addTearDown(subscription.cancel);

        await repo.store({'id': '1', 'title': 'Buy milk'});
        // Let the watch stream's async emit() complete.
        await pumpEventQueue();

        expect(
          emissions.last.map((row) => row['title']),
          contains('Buy milk'),
        );
      },
    );

    test('update mutates the local row and enqueues a matching PUT', () async {
      final repo = await buildRepo();
      await repo.store({'id': '1', 'title': 'original'});
      queue.enqueued.clear();

      final updated = await repo.update('1', {'title': 'renamed'});
      expect(updated['title'], 'renamed');

      final found = await table.find('1');
      expect(found!['title'], 'renamed');

      expect(queue.enqueued, hasLength(1));
      expect(queue.enqueued.single.method, 'PUT');
      expect(queue.enqueued.single.path, 'todos/1');
      expect(queue.enqueued.single.data, {'title': 'renamed'});
    });

    test(
      'destroy deletes the local row and enqueues a DELETE with null data',
      () async {
        final repo = await buildRepo();
        await repo.store({'id': '1', 'title': 'temp'});
        queue.enqueued.clear();

        await repo.destroy('1');

        expect(await table.find('1'), isNull);
        expect(queue.enqueued, hasLength(1));
        expect(queue.enqueued.single.method, 'DELETE');
        expect(queue.enqueued.single.path, 'todos/1');
        expect(queue.enqueued.single.data, isNull);
      },
    );

    test('a write triggers a flush when already online', () async {
      final repo = await buildRepo(online: true);
      await repo.store({'id': '1', 'title': 'x'});
      await pumpEventQueue();
      expect(queue.flushCalls, greaterThan(0));
    });

    test(
      'a write does NOT trigger a flush when offline, but is still enqueued',
      () async {
        final repo = await buildRepo(online: false);
        await repo.store({'id': '1', 'title': 'x'});
        await pumpEventQueue();
        expect(queue.flushCalls, 0);
        expect(queue.enqueued, hasLength(1));
      },
    );

    test('show throws StateError when the row is absent', () async {
      final repo = await buildRepo();
      expect(() => repo.show('missing'), throwsA(isA<StateError>()));
    });

    test('show returns the row when present', () async {
      final repo = await buildRepo();
      await repo.store({'id': '1', 'title': 'here'});
      final shown = await repo.show('1');
      expect(shown['title'], 'here');
    });
  });
}

/// Records every [enqueue]d [OfflineRequest] and counts [flush] calls
/// without ever touching a real API — [flush] never delegates to
/// `super.flush()`, so these tests never attempt a real network call.
class _RecordingQueue extends OfflineRequestQueue {
  final List<OfflineRequest> enqueued = [];
  int flushCalls = 0;

  _RecordingQueue({required super.storage, required super.api});

  @override
  Future<void> enqueue(OfflineRequest request) async {
    enqueued.add(request);
    await super.enqueue(request);
  }

  @override
  Future<void> flush() async {
    flushCalls += 1;
  }
}

class _FakeConnectivitySource implements ConnectivitySource {
  bool _connected;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  _FakeConnectivitySource({bool initial = true}) : _connected = initial;

  void push(bool online) {
    _connected = online;
    _controller.add(online);
  }

  @override
  Future<bool> isConnected() async => _connected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;
}
