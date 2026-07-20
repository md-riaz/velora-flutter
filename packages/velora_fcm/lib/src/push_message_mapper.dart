import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:velora/velora.dart';

/// Maps a firebase_messaging [RemoteMessage] to Velora's transport-agnostic
/// [PushMessage].
///
/// Pure and side-effect free, so it's fully unit-testable without touching
/// Firebase: build a [RemoteMessage] via `RemoteMessage.fromMap({...})` in a
/// test and assert on the result directly.
PushMessage pushMessageFromRemoteMessage(RemoteMessage message) {
  return PushMessage(
    id: message.messageId,
    title: message.notification?.title,
    body: message.notification?.body,
    data: message.data,
  );
}
