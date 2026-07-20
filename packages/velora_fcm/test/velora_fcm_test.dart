import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';
import 'package:velora_fcm/velora_fcm.dart';

void main() {
  group('pushMessageFromRemoteMessage', () {
    test('maps messageId, notification, and data', () {
      final message = RemoteMessage.fromMap({
        'messageId': 'msg-1',
        'notification': {'title': 'Hello', 'body': 'World'},
        'data': {'route': '/inbox', 'id': '42'},
      });

      final result = pushMessageFromRemoteMessage(message);

      expect(result.id, 'msg-1');
      expect(result.title, 'Hello');
      expect(result.body, 'World');
      expect(result.data, {'route': '/inbox', 'id': '42'});
    });

    test('maps a data-only message with no notification block', () {
      final message = RemoteMessage.fromMap({
        'messageId': 'msg-2',
        'data': {'type': 'silent', 'foo': 'bar'},
      });

      final result = pushMessageFromRemoteMessage(message);

      expect(result.id, 'msg-2');
      expect(result.title, isNull);
      expect(result.body, isNull);
      expect(result.data, {'type': 'silent', 'foo': 'bar'});
    });

    test('handles a message with neither notification nor data', () {
      final message = RemoteMessage.fromMap({'messageId': 'msg-3'});

      final result = pushMessageFromRemoteMessage(message);

      expect(result.id, 'msg-3');
      expect(result.title, isNull);
      expect(result.body, isNull);
      expect(result.data, isEmpty);
    });
  });

  group('VeloraFcmAdapter', () {
    late _FakeFcmClient client;
    late VeloraFcmAdapter adapter;

    setUp(() {
      client = _FakeFcmClient();
      adapter = VeloraFcmAdapter(client: client);
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test('provider is fcm', () {
      expect(adapter.provider, 'fcm');
    });

    test('requestPermission forwards the client value', () async {
      client.permissionResult = true;
      expect(await adapter.requestPermission(), isTrue);

      client.permissionResult = false;
      expect(await adapter.requestPermission(), isFalse);
      expect(client.requestPermissionCalls, 2);
    });

    test('getToken forwards the client token', () async {
      client.token = 'abc-token';
      expect(await adapter.getToken(), 'abc-token');
      expect(client.getTokenCalls, 1);
    });

    test('deleteToken forwards to the client', () async {
      await adapter.deleteToken();
      expect(client.deleteTokenCalls, 1);
    });

    test('onMessage emits mapped PushMessage from the client stream',
        () async {
      await adapter.init();
      final events = <PushMessage>[];
      final sub = adapter.onMessage.listen(events.add);

      client.pushOnMessage(RemoteMessage.fromMap({
        'messageId': 'fg-1',
        'notification': {'title': 'Foreground', 'body': 'Body'},
        'data': {'k': 'v'},
      }));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.id, 'fg-1');
      expect(events.single.title, 'Foreground');
      expect(events.single.body, 'Body');
      expect(events.single.data, {'k': 'v'});

      await sub.cancel();
    });

    test(
        'onMessageOpenedApp emits mapped PushMessage from the client stream',
        () async {
      await adapter.init();
      final events = <PushMessage>[];
      final sub = adapter.onMessageOpenedApp.listen(events.add);

      client.pushOnMessageOpenedApp(RemoteMessage.fromMap({
        'messageId': 'opened-1',
        'notification': {'title': 'Opened', 'body': 'Tapped'},
      }));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.id, 'opened-1');
      expect(events.single.title, 'Opened');
      expect(events.single.body, 'Tapped');

      await sub.cancel();
    });

    test(
      'init() consumes a non-null getInitialMessage() once and emits it on '
      'onMessageOpenedApp, delivering a terminated-app (cold-start) '
      'notification tap',
      () async {
        client.initialMessage = RemoteMessage.fromMap({
          'messageId': 'cold-start-1',
          'notification': {'title': 'Cold Start', 'body': 'Tapped while dead'},
        });

        final events = <PushMessage>[];
        final sub = adapter.onMessageOpenedApp.listen(events.add);

        await adapter.init();
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.single.id, 'cold-start-1');
        expect(events.single.title, 'Cold Start');
        expect(events.single.body, 'Tapped while dead');
        expect(client.getInitialMessageCalls, 1);

        await sub.cancel();
      },
    );

    test(
      'init() with a null getInitialMessage() emits nothing extra on '
      'onMessageOpenedApp',
      () async {
        client.initialMessage = null;

        final events = <PushMessage>[];
        final sub = adapter.onMessageOpenedApp.listen(events.add);

        await adapter.init();
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
        expect(client.getInitialMessageCalls, 1);

        await sub.cancel();
      },
    );

    test(
      'dispose() cancels the underlying client subscriptions but leaves the '
      'adapter streams open, and a subsequent init() re-subscribes so '
      'events flow again (re-login after logout)',
      () async {
        await adapter.init();
        expect(client.onMessageController.hasListener, isTrue);
        expect(client.onMessageOpenedAppController.hasListener, isTrue);

        await adapter.dispose();

        // The adapter released its own subscription to the underlying
        // client streams -- no more work happens on them post-dispose.
        expect(client.onMessageController.hasListener, isFalse);
        expect(client.onMessageOpenedAppController.hasListener, isFalse);

        // But the adapter's own public streams are still open/usable.
        final events = <PushMessage>[];
        final sub = adapter.onMessage.listen(events.add);

        // Re-init (simulating a subsequent login) re-subscribes to the
        // client streams.
        await adapter.init();
        expect(client.onMessageController.hasListener, isTrue);

        client.pushOnMessage(RemoteMessage.fromMap({
          'messageId': 'after-relogin',
          'notification': {'title': 'Back', 'body': 'Again'},
        }));
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));
        expect(events.single.id, 'after-relogin');

        await sub.cancel();
      },
    );

    test(
      'calling init() twice in a row without an intervening dispose() does '
      'not double-deliver events (no duplicate subscriptions)',
      () async {
        await adapter.init();
        await adapter.init();

        final events = <PushMessage>[];
        final sub = adapter.onMessage.listen(events.add);

        client.pushOnMessage(RemoteMessage.fromMap({
          'messageId': 'no-dupe',
          'notification': {'title': 'Once', 'body': 'Only'},
        }));
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(1));

        await sub.cancel();
      },
    );
  });
}

class _FakeFcmClient implements FcmClient {
  bool permissionResult = true;
  String? token;
  int requestPermissionCalls = 0;
  int getTokenCalls = 0;
  int deleteTokenCalls = 0;
  int getInitialMessageCalls = 0;
  RemoteMessage? initialMessage;

  final onMessageController = StreamController<RemoteMessage>.broadcast();
  final onMessageOpenedAppController =
      StreamController<RemoteMessage>.broadcast();

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    return permissionResult;
  }

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return token;
  }

  @override
  Future<void> deleteToken() async {
    deleteTokenCalls++;
  }

  @override
  Stream<RemoteMessage> get onMessage => onMessageController.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      onMessageOpenedAppController.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    getInitialMessageCalls++;
    return initialMessage;
  }

  void pushOnMessage(RemoteMessage message) =>
      onMessageController.add(message);

  void pushOnMessageOpenedApp(RemoteMessage message) =>
      onMessageOpenedAppController.add(message);
}
