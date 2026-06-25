import 'dart:async';

import '../notification_payload.dart';
import 'push_adapter.dart';

/// A [PushAdapter] wired by dependency injection: the caller provides
/// closures backed by Firebase Messaging (or any other provider) so that the
/// core Velora package stays free of mandatory Firebase dependencies.
///
/// ## Setup
///
/// In your app, add `firebase_messaging` to pubspec.yaml, initialise Firebase,
/// then pass the Firebase-backed closures:
///
/// ```dart
/// import 'package:firebase_messaging/firebase_messaging.dart';
///
/// PushMessage _fromFcm(RemoteMessage msg) => PushMessage(
///   id: msg.messageId ?? '',
///   title: msg.notification?.title ?? '',
///   body: msg.notification?.body ?? '',
///   data: msg.data,
/// );
///
/// final pushAdapter = FcmPushAdapter(
///   getToken: () => FirebaseMessaging.instance.getToken(),
///   deleteToken: () => FirebaseMessaging.instance.deleteToken(),
///   requestPermission: () async {
///     final s = await FirebaseMessaging.instance.requestPermission();
///     return s.authorizationStatus == AuthorizationStatus.authorized;
///   },
///   onMessage: FirebaseMessaging.onMessage.map(_fromFcm),
///   onMessageOpenedApp: FirebaseMessaging.onMessageOpenedApp.map(_fromFcm),
/// );
/// ```
///
/// Then pass it to `Velora.boot`:
/// ```dart
/// await Velora.boot(
///   config: VeloraConfig(
///     ...,
///     notifications: VeloraNotificationConfig(pushAdapter: pushAdapter),
///   ),
/// );
/// ```
class FcmPushAdapter implements PushAdapter {
  final Future<String?> Function() _getToken;
  final Future<void> Function() _deleteToken;
  final Future<bool> Function() _requestPermission;
  final Stream<PushMessage> _onMessage;
  final Stream<PushMessage> _onMessageOpenedApp;
  final Future<void> Function()? _onDispose;

  FcmPushAdapter({
    required Future<String?> Function() getToken,
    required Future<void> Function() deleteToken,
    required Future<bool> Function() requestPermission,
    required Stream<PushMessage> onMessage,
    required Stream<PushMessage> onMessageOpenedApp,
    Future<void> Function()? onDispose,
  })  : _getToken = getToken,
        _deleteToken = deleteToken,
        _requestPermission = requestPermission,
        _onMessage = onMessage,
        _onMessageOpenedApp = onMessageOpenedApp,
        _onDispose = onDispose;

  @override
  String get provider => 'fcm';

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() => _requestPermission();

  @override
  Future<String?> getToken() => _getToken();

  @override
  Future<void> deleteToken() => _deleteToken();

  @override
  Stream<PushMessage> get onMessage => _onMessage;

  @override
  Stream<PushMessage> get onMessageOpenedApp => _onMessageOpenedApp;

  @override
  Future<void> dispose() async => _onDispose?.call();
}
