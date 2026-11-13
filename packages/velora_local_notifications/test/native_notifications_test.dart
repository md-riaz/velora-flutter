import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';

/// Mirrors the private FNV-1a hash in the adapter.
int _expectedHash(String id) {
  var hash = 0x811c9dc5;
  for (final codeUnit in id.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

void main() {
  late _FakeClient client;
  late FlutterLocalNotificationsNativeAdapter adapter;

  setUp(() {
    client = _FakeClient();
    adapter = FlutterLocalNotificationsNativeAdapter(client: client);
  });

  tearDown(() => adapter.dispose());

  group('initialize', () {
    test('delegates to client with activation callback', () async {
      await adapter.initialize();
      expect(client.initializeCalls, 1);
      expect(client.onActivation, isNotNull);
    });
  });

  group('show', () {
    test('maps string id to hashed int and forwards all fields', () async {
      await adapter.initialize();
      await adapter.show(const VeloraNativeNotification(
        id: 'msg-42',
        title: 'New message',
        body: 'Hello there',
        payload: {'threadId': '7'},
        actions: [
          VeloraNativeAction(id: 'reply', label: 'Reply'),
          VeloraNativeAction(
            id: 'quick-reply',
            label: 'Quick Reply',
            textInputPlaceholder: 'Type a reply...',
          ),
        ],
        silent: true,
      ));

      expect(client.shown, hasLength(1));
      final call = client.shown.single;
      expect(call.id, _expectedHash('msg-42'));
      expect(call.title, 'New message');
      expect(call.body, 'Hello there');
      expect(call.silent, isTrue);

      // Actions forwarded.
      expect(call.actions, hasLength(2));
      expect(call.actions[0]['id'], 'reply');
      expect(call.actions[0]['label'], 'Reply');
      expect(call.actions[0]['textInputPlaceholder'], isNull);
      expect(call.actions[1]['id'], 'quick-reply');
      expect(call.actions[1]['textInputPlaceholder'], 'Type a reply...');

      // Payload includes veloraId for round-trip.
      final payload = jsonDecode(call.payload!) as Map<String, dynamic>;
      expect(payload['veloraId'], 'msg-42');
      expect(payload['threadId'], '7');
    });

    test('replacing a notification reuses the same int id', () async {
      await adapter.initialize();
      await adapter.show(const VeloraNativeNotification(
        id: 'notif-1',
        title: 'v1',
      ));
      await adapter.show(const VeloraNativeNotification(
        id: 'notif-1',
        title: 'v2',
      ));

      expect(client.shown[0].id, client.shown[1].id);
      expect(client.shown[0].id, _expectedHash('notif-1'));
    });

    test('empty payload still includes veloraId', () async {
      await adapter.initialize();
      await adapter.show(const VeloraNativeNotification(
        id: 'bare',
        title: 'Bare',
      ));

      final payload = jsonDecode(client.shown.single.payload!) as Map;
      expect(payload['veloraId'], 'bare');
    });
  });

  group('cancel', () {
    test('cancels the hashed int id', () async {
      await adapter.initialize();
      await adapter.cancel('msg-42');
      expect(client.canceled, [_expectedHash('msg-42')]);
    });
  });

  group('cancelAll', () {
    test('delegates to client', () async {
      await adapter.initialize();
      await adapter.cancelAll();
      expect(client.cancelAllCalls, 1);
    });
  });

  group('activations', () {
    test('body tap delivers activation with original string id', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      // Simulate a body tap from the plugin.
      final payload = jsonEncode({'veloraId': 'msg-42', 'threadId': '7'});
      client.onActivation!(
        id: _expectedHash('msg-42'),
        payload: payload,
      );
      await Future<void>.delayed(Duration.zero);

      expect(activations, hasLength(1));
      expect(activations[0].id, 'msg-42');
      expect(activations[0].actionId, isNull);
      expect(activations[0].input, isNull);
      expect(activations[0].payload['threadId'], '7');
      // veloraId is stripped from the payload.
      expect(activations[0].payload.containsKey('veloraId'), isFalse);
    });

    test('action button delivers activation with actionId', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      final payload = jsonEncode({'veloraId': 'msg-42'});
      client.onActivation!(
        id: _expectedHash('msg-42'),
        actionId: 'reply',
        payload: payload,
      );
      await Future<void>.delayed(Duration.zero);

      expect(activations, hasLength(1));
      expect(activations[0].id, 'msg-42');
      expect(activations[0].actionId, 'reply');
    });

    test('text input delivers activation with input', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      final payload = jsonEncode({'veloraId': 'msg-42'});
      client.onActivation!(
        id: _expectedHash('msg-42'),
        actionId: 'quick-reply',
        input: 'Sure thing!',
        payload: payload,
      );
      await Future<void>.delayed(Duration.zero);

      expect(activations, hasLength(1));
      expect(activations[0].input, 'Sure thing!');
    });

    test('platform data is forwarded', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      final payload = jsonEncode({'veloraId': 'msg-42'});
      client.onActivation!(
        id: _expectedHash('msg-42'),
        payload: payload,
        data: {'windows_input_reply': 'typed text'},
      );
      await Future<void>.delayed(Duration.zero);

      expect(activations[0].data['windows_input_reply'], 'typed text');
    });

    test('duplicate activation is suppressed within dedup window', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      final payload = jsonEncode({'veloraId': 'msg-42'});
      client.onActivation!(id: _expectedHash('msg-42'), payload: payload);
      client.onActivation!(id: _expectedHash('msg-42'), payload: payload);
      await Future<void>.delayed(Duration.zero);

      expect(activations, hasLength(1));
    });

    test('different action ids are not deduplicated', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      final payload = jsonEncode({'veloraId': 'msg-42'});
      client.onActivation!(id: _expectedHash('msg-42'), payload: payload);
      client.onActivation!(
        id: _expectedHash('msg-42'),
        actionId: 'reply',
        payload: payload,
      );
      await Future<void>.delayed(Duration.zero);

      expect(activations, hasLength(2));
    });

    test('falls back to int id when payload has no veloraId', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      client.onActivation!(id: 999, payload: null);
      await Future<void>.delayed(Duration.zero);

      expect(activations[0].id, '999');
    });

    test('falls back to in-memory id map when payload is malformed', () async {
      await adapter.initialize();
      // Show a notification to populate the in-memory map.
      await adapter.show(const VeloraNativeNotification(
        id: 'mapped',
        title: 'Test',
      ));

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add);

      client.onActivation!(
        id: _expectedHash('mapped'),
        payload: 'not-valid-json',
      );
      await Future<void>.delayed(Duration.zero);

      expect(activations[0].id, 'mapped');
    });

    test('activation after dispose is ignored', () async {
      await adapter.initialize();

      final activations = <VeloraNotificationActivation>[];
      adapter.activations.listen(activations.add, onError: (_) {});

      await adapter.dispose();

      // Should not throw or emit.
      client.onActivation!(id: 1, payload: null);
      await Future<void>.delayed(Duration.zero);

      expect(activations, isEmpty);
    });
  });

  group('FakeNativeNotifications', () {
    test('records shown notifications', () async {
      final fake = FakeNativeNotifications();
      await fake.initialize();

      await fake.show(const VeloraNativeNotification(
        id: 'test-1',
        title: 'Test',
      ));

      expect(fake.initialized, isTrue);
      expect(fake.shown, hasLength(1));
      expect(fake.shown[0].id, 'test-1');

      await fake.dispose();
      expect(fake.disposed, isTrue);
    });

    test('simulateActivation delivers to stream', () async {
      final fake = FakeNativeNotifications();
      final activations = <VeloraNotificationActivation>[];
      fake.activations.listen(activations.add);

      fake.simulateActivation(const VeloraNotificationActivation(
        id: 'test-1',
        actionId: 'reply',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(activations, hasLength(1));
      expect(activations[0].actionId, 'reply');

      await fake.dispose();
    });
  });

  group('NativeNotificationsCompat', () {
    test('wraps VeloraNativeNotifications into LocalNotificationAdapter',
        () async {
      final fake = FakeNativeNotifications();
      // ignore: deprecated_member_use_from_same_package
      final compat = NativeNotificationsCompat(fake);

      await compat.init();
      expect(fake.initialized, isTrue);

      await compat.show(title: 'Hello', body: 'World');
      expect(fake.shown, hasLength(1));
      expect(fake.shown[0].title, 'Hello');
      expect(fake.shown[0].body, 'World');

      await compat.cancel('some-id');
      expect(fake.canceled, ['some-id']);

      await compat.cancelAll();
      expect(fake.cancelAllCalls, 1);

      await fake.dispose();
    });

    test('schedule falls back to immediate show', () async {
      final fake = FakeNativeNotifications();
      // ignore: deprecated_member_use_from_same_package
      final compat = NativeNotificationsCompat(fake);

      await compat.schedule(
        id: 'sched-1',
        title: 'Scheduled',
        body: 'Body',
        dateTime: DateTime(2030),
      );

      expect(fake.shown, hasLength(1));
      expect(fake.shown[0].id, 'sched-1');

      await fake.dispose();
    });
  });
}

class _ShowCall {
  _ShowCall(this.id, this.title, this.body, this.payload, this.actions,
      this.silent);
  final int id;
  final String? title;
  final String? body;
  final String? payload;
  final List<Map<String, String?>> actions;
  final bool silent;
}

class _FakeClient implements LocalNotificationsClient {
  int initializeCalls = 0;
  int cancelAllCalls = 0;
  final List<_ShowCall> shown = [];
  final List<int> canceled = [];

  void Function({
    required int id,
    String? actionId,
    String? input,
    String? payload,
    Map<String, dynamic> data,
  })? onActivation;

  @override
  Future<void> initialize({
    void Function({
      required int id,
      String? actionId,
      String? input,
      String? payload,
      Map<String, dynamic> data,
    })? onActivation,
  }) async {
    initializeCalls++;
    this.onActivation = onActivation;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
    List<Map<String, String?>> actions = const [],
    bool silent = false,
  }) async {
    shown.add(_ShowCall(id, title, body, payload, actions, silent));
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    DateTime dateTime, {
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }
}
