import 'package:flutter_test/flutter_test.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';

void main() {
  late _FakeLocalNotificationsClient client;
  late VeloraLocalNotificationsAdapter adapter;

  setUp(() {
    client = _FakeLocalNotificationsClient();
    adapter = VeloraLocalNotificationsAdapter(client: client);
  });

  group('init', () {
    test('delegates to the client', () async {
      await adapter.init();
      expect(client.initializeCalls, 1);
    });
  });

  group('show', () {
    test('synthesizes an int id and forwards title/body/payload', () async {
      await adapter.show(
        title: 'Hello',
        body: 'World',
        payload: {'route': '/home'},
      );

      expect(client.shown, hasLength(1));
      final call = client.shown.single;
      expect(call.id, isA<int>());
      expect(call.title, 'Hello');
      expect(call.body, 'World');
      expect(call.payload, '{"route":"/home"}');
    });

    test('a default (empty) payload is forwarded as null, not "{}"', () async {
      await adapter.show(title: 'Hello', body: 'World');
      expect(client.shown.single.payload, isNull);
    });

    test('each call synthesizes a distinct, increasing int id', () async {
      await adapter.show(title: 'a', body: 'a');
      await adapter.show(title: 'b', body: 'b');

      final ids = client.shown.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(2), reason: 'ids must be unique');
      expect(ids[1], greaterThan(ids[0]));
    });
  });

  group('schedule', () {
    test('maps a string id to an int and forwards dateTime/payload', () async {
      final when = DateTime(2030, 1, 1, 9);
      await adapter.schedule(
        id: 'daily-reminder',
        title: 'Reminder',
        body: 'Do the thing',
        dateTime: when,
        payload: {'kind': 'reminder'},
      );

      expect(client.scheduled, hasLength(1));
      final call = client.scheduled.single;
      expect(call.title, 'Reminder');
      expect(call.body, 'Do the thing');
      expect(call.dateTime, when);
      expect(call.payload, '{"kind":"reminder"}');
    });

    test(
      'scheduling the same string id twice reuses the same int id '
      '(overwrite semantics), not a new one',
      () async {
        await adapter.schedule(
          id: 'daily-reminder',
          title: 'Reminder v1',
          body: 'first',
          dateTime: DateTime(2030, 1, 1),
        );
        await adapter.schedule(
          id: 'daily-reminder',
          title: 'Reminder v2',
          body: 'second',
          dateTime: DateTime(2030, 2, 1),
        );

        expect(client.scheduled, hasLength(2));
        expect(client.scheduled[0].id, client.scheduled[1].id);
      },
    );

    test(
      'different string ids are mapped to different int ids',
      () async {
        await adapter.schedule(
          id: 'a',
          title: 'a',
          body: 'a',
          dateTime: DateTime(2030),
        );
        await adapter.schedule(
          id: 'b',
          title: 'b',
          body: 'b',
          dateTime: DateTime(2030),
        );

        expect(client.scheduled[0].id, isNot(client.scheduled[1].id));
      },
    );

    test(
      'the int id mapping is stable/deterministic for the same string id '
      'across repeated schedule calls',
      () async {
        final seenIds = <int>{};
        for (var i = 0; i < 5; i++) {
          await adapter.schedule(
            id: 'stable-id',
            title: 'x',
            body: 'x',
            dateTime: DateTime(2030),
          );
          seenIds.add(client.scheduled.last.id);
        }
        expect(seenIds, hasLength(1));
      },
    );
  });

  group('cancel', () {
    test('cancels the int id mapped to the given string id', () async {
      await adapter.schedule(
        id: 'to-cancel',
        title: 'x',
        body: 'x',
        dateTime: DateTime(2030),
      );
      final mappedId = client.scheduled.single.id;

      await adapter.cancel('to-cancel');

      expect(client.canceled, [mappedId]);
    });

    test('canceling an id that was never scheduled is a harmless no-op', () async {
      await adapter.cancel('never-scheduled');
      expect(client.canceled, isEmpty);
    });

    test(
      'canceling a string id removes it from the mapping, so scheduling it '
      'again afterwards allocates a fresh int id',
      () async {
        await adapter.schedule(
          id: 'reused',
          title: 'x',
          body: 'x',
          dateTime: DateTime(2030),
        );
        final firstId = client.scheduled.single.id;
        await adapter.cancel('reused');

        await adapter.schedule(
          id: 'reused',
          title: 'x',
          body: 'x',
          dateTime: DateTime(2030),
        );
        final secondId = client.scheduled.last.id;

        expect(secondId, isNot(firstId));
      },
    );
  });

  group('cancelAll', () {
    test('delegates to the client and clears the id mapping', () async {
      await adapter.schedule(
        id: 'a',
        title: 'a',
        body: 'a',
        dateTime: DateTime(2030),
      );
      final firstId = client.scheduled.single.id;

      await adapter.cancelAll();
      expect(client.cancelAllCalls, 1);

      // The mapping was cleared, so re-scheduling the same string id
      // allocates a fresh int id rather than reusing the pre-cancelAll one.
      await adapter.schedule(
        id: 'a',
        title: 'a',
        body: 'a',
        dateTime: DateTime(2030),
      );
      expect(client.scheduled.last.id, isNot(firstId));
    });
  });
}

class _ShowCall {
  _ShowCall(this.id, this.title, this.body, this.payload);

  final int id;
  final String? title;
  final String? body;
  final String? payload;
}

class _ScheduleCall {
  _ScheduleCall(this.id, this.title, this.body, this.dateTime, this.payload);

  final int id;
  final String? title;
  final String? body;
  final DateTime dateTime;
  final String? payload;
}

/// A fake [LocalNotificationsClient] that records every call instead of
/// touching a real platform channel, so [VeloraLocalNotificationsAdapter]
/// can be exercised headlessly under `flutter test`.
class _FakeLocalNotificationsClient implements LocalNotificationsClient {
  int initializeCalls = 0;
  int cancelAllCalls = 0;
  final List<_ShowCall> shown = <_ShowCall>[];
  final List<_ScheduleCall> scheduled = <_ScheduleCall>[];
  final List<int> canceled = <int>[];

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
  }) async {
    shown.add(_ShowCall(id, title, body, payload));
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    DateTime dateTime, {
    String? payload,
  }) async {
    scheduled.add(_ScheduleCall(id, title, body, dateTime, payload));
  }

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }
}
