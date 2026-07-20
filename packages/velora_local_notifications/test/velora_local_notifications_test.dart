import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';

/// Mirrors the private `_hashId` FNV-1a implementation in
/// [VeloraLocalNotificationsAdapter] so tests can assert against the exact
/// deterministic int a given string id maps to.
int _expectedHash(String id) {
  var hash = 0x811c9dc5;
  for (final codeUnit in id.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

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

    test(
      'ids stay positive and distinct across many calls '
      '(the 32-bit-overflow wraparound itself is covered by inspection of '
      'the show-id counter, since seeding the private counter near '
      'Int32.maxValue is not reachable from outside the adapter)',
      () async {
        const callCount = 500;
        for (var i = 0; i < callCount; i++) {
          await adapter.show(title: 'n$i', body: 'n$i');
        }

        final ids = client.shown.map((c) => c.id).toList();
        expect(ids, hasLength(callCount));
        expect(ids.every((id) => id > 0), isTrue, reason: 'ids must be positive');
        expect(ids.toSet(), hasLength(callCount), reason: 'ids must be unique');
      },
    );
  });

  group('schedule', () {
    test('hashes the string id to a deterministic int and forwards '
        'dateTime/payload', () async {
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
      expect(call.id, _expectedHash('daily-reminder'));
      expect(call.title, 'Reminder');
      expect(call.body, 'Do the thing');
      expect(call.dateTime, when);
      expect(call.payload, '{"kind":"reminder"}');
    });

    test(
      'scheduling the same string id twice reuses the same (hashed) int id '
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
        expect(client.scheduled[0].id, _expectedHash('daily-reminder'));
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
      'across repeated schedule calls, and across separate adapter '
      'instances (i.e. survives an app restart)',
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
        expect(seenIds.single, _expectedHash('stable-id'));

        // A brand-new adapter (simulating a fresh process/app restart, with
        // no in-memory state carried over) must hash the same string id to
        // the same int.
        final freshClient = _FakeLocalNotificationsClient();
        final freshAdapter =
            VeloraLocalNotificationsAdapter(client: freshClient);
        await freshAdapter.schedule(
          id: 'stable-id',
          title: 'x',
          body: 'x',
          dateTime: DateTime(2030),
        );
        expect(freshClient.scheduled.single.id, seenIds.single);
      },
    );
  });

  group('cancel', () {
    test('cancels the hashed int id for the given string id', () async {
      await adapter.schedule(
        id: 'to-cancel',
        title: 'x',
        body: 'x',
        dateTime: DateTime(2030),
      );

      await adapter.cancel('to-cancel');

      expect(client.canceled, [_expectedHash('to-cancel')]);
    });

    test(
      'canceling an id that was never scheduled still calls through to the '
      'client with the hashed id (safe no-op on the client side, but the '
      'adapter no longer skips the call since there is no map to miss)',
      () async {
        await adapter.cancel('never-scheduled');
        expect(client.canceled, [_expectedHash('never-scheduled')]);
      },
    );

    test(
      'canceling then re-scheduling the same string id reuses the same '
      'hashed int id (no map to have removed it from)',
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

        expect(secondId, firstId);
        expect(secondId, _expectedHash('reused'));
      },
    );
  });

  group('cancelAll', () {
    test('delegates to the client', () async {
      await adapter.schedule(
        id: 'a',
        title: 'a',
        body: 'a',
        dateTime: DateTime(2030),
      );
      final firstId = client.scheduled.single.id;

      await adapter.cancelAll();
      expect(client.cancelAllCalls, 1);

      // There is no id mapping to clear, so re-scheduling the same string
      // id still resolves to the same hashed int id as before.
      await adapter.schedule(
        id: 'a',
        title: 'a',
        body: 'a',
        dateTime: DateTime(2030),
      );
      expect(client.scheduled.last.id, firstId);
    });
  });

  group('FlutterLocalNotificationsClient', () {
    // FlutterLocalNotificationsClient is backed by real platform channels
    // (plugin.initialize/show/zonedSchedule/... all cross into native code),
    // so it isn't headlessly callable under `flutter test`. This only
    // exercises construction -- proving the androidScheduleMode parameter
    // exists and accepts a non-default value -- and never invokes any
    // method that would touch a platform channel.
    test(
      'constructs with a non-default androidScheduleMode without error',
      () {
        expect(
          () => FlutterLocalNotificationsClient(
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          ),
          returnsNormally,
        );
      },
    );

    test('defaults androidScheduleMode to the safe, inexact mode', () {
      // No platform call is made; this only checks that constructing with
      // no explicit androidScheduleMode doesn't throw, i.e. the safe
      // default documented on the constructor is exercised.
      expect(() => FlutterLocalNotificationsClient(), returnsNormally);
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
