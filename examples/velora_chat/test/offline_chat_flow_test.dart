import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart';
import 'package:velora_chat/app/data/chat_schema.dart';
import 'package:velora_chat/app/data/chat_tables.dart';
import 'package:velora_chat/app/data/message.dart';
import 'package:velora_chat/app/offline/mock_chat_server_interceptor.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

/// Proves the demo's whole offline loop end to end, using the app's own
/// schema/tables/mock-server code (not a re-implementation of it) against an
/// in-memory drift database, exactly the way `velora_db`/`velora_offline`'s
/// own test suites do.
void main() {
  late VeloraDatabase db;
  late ToggleConnectivitySource toggleSource;
  late OfflineRequestQueue queue;
  late ConnectivityService connectivity;
  late VeloraOfflineFirstRepository<Message, String> messagesRepo;

  setUp(() async {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    // The same VeloraDbPlugin wiring the real app boots, minus GetX
    // permanence -- an in-memory drift executor keeps this hermetic and fast.
    db = await VeloraDatabase(
      databaseName: ':memory:',
      version: 1,
      migrations: [CreateChatSchema()],
      executor: NativeDatabase.memory(),
    ).open();
    Get.put<VeloraDatabase>(db);

    final storage = await VeloraStorageService().init();
    final api = VeloraApiService(
      config: const VeloraConfig(
        appName: 'Velora Chat Test',
        apiBaseUrl: 'https://example.invalid',
      ),
      storage: storage,
    );
    // The exact interceptor the real app registers via
    // `Velora.api.addInterceptor(...)` after boot.
    api.addInterceptor(MockChatServerInterceptor());

    // Starts offline -- the demo's toggle, flippable without touching a real
    // network or airplane mode.
    toggleSource = ToggleConnectivitySource(online: false);
    connectivity = await ConnectivityService(toggleSource).init();
    Get.put<ConnectivityService>(connectivity);

    queue = OfflineRequestQueue(storage: storage, api: api);
    await queue.load();
    Get.put<OfflineRequestQueue>(queue);
    // Mirrors VeloraOfflinePlugin.register's own wiring: flush on reconnect.
    connectivity.onOnline(() => queue.flush());

    messagesRepo = VeloraOffline.offlineFirst<Message, String>(
      table: messagesTable(),
      endpoint: 'messages',
    );
  });

  tearDown(() async {
    Get.reset();
    toggleSource.dispose();
    await db.close();
  });

  test(
    'sending a message while offline writes it locally as pending and '
    'queues exactly one outbox write',
    () async {
      await messagesRepo.store(
        Message(
          id: 'm1',
          conversationId: 'c1',
          body: 'hello there',
          outgoing: true,
          status: 'pending',
          createdAt: DateTime.now(),
        ).toMap(),
      );

      final stored = await messagesTable().find('m1');
      expect(stored, isNotNull);
      expect(stored!.status, 'pending');
      expect(stored.outgoing, isTrue);

      expect(queue.pending, hasLength(1));
      expect(queue.pending.single.method, 'POST');
      expect(queue.pending.single.path, 'messages');
    },
  );

  test(
    'toggling online flushes the outbox, and the mock server acknowledges '
    'the message by flipping it to sent',
    () async {
      await messagesRepo.store(
        Message(
          id: 'm2',
          conversationId: 'c1',
          body: 'are you there?',
          outgoing: true,
          status: 'pending',
          createdAt: DateTime.now(),
        ).toMap(),
      );
      expect(queue.pending, hasLength(1));
      expect((await messagesTable().find('m2'))!.status, 'pending');

      // Flip the demo's simulated connectivity back on -- this is exactly
      // what the conversations page's Switch does.
      toggleSource.setOnline(true);

      // ConnectivityService's onOnline hook fires the queue flush
      // fire-and-forget; the mock server then waits ~400ms before
      // acknowledging. Give both enough runway to settle deterministically.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await pumpEventQueue();

      expect(queue.pending, isEmpty);
      final stored = await messagesTable().find('m2');
      expect(stored!.status, 'sent');
    },
  );

  test(
    'a write made while already online is enqueued and flushed immediately, '
    'without needing a connectivity toggle',
    () async {
      toggleSource.setOnline(true);
      await pumpEventQueue();

      await messagesRepo.store(
        Message(
          id: 'm3',
          conversationId: 'c1',
          body: 'already online',
          outgoing: true,
          status: 'pending',
          createdAt: DateTime.now(),
        ).toMap(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 800));
      await pumpEventQueue();

      expect(queue.pending, isEmpty);
      final stored = await messagesTable().find('m3');
      expect(stored!.status, 'sent');
    },
  );
}
