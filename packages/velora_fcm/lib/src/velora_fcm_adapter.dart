import 'dart:async';

import 'package:velora/velora.dart';

import 'fcm_client.dart';
import 'push_message_mapper.dart';

/// A real Firebase Cloud Messaging-backed [PushAdapter].
///
/// ## Setup
///
/// The app is responsible for initializing Firebase itself — this adapter
/// does not call `Firebase.initializeApp()`. Do that once in `main()`,
/// before `Velora.boot()`:
///
/// ```dart
/// import 'package:firebase_core/firebase_core.dart';
/// import 'package:velora_fcm/velora_fcm.dart';
///
/// await Firebase.initializeApp();
///
/// await Velora.boot(
///   config: VeloraConfig(
///     ...,
///     notifications: VeloraNotificationConfig(
///       pushAdapter: VeloraFcmAdapter(),
///     ),
///   ),
/// );
/// ```
///
/// All firebase-specific types are confined to [FcmClient] (the injectable
/// seam) and [pushMessageFromRemoteMessage] (the pure mapping function) — the
/// adapter's own logic (stream mapping, provider id, dispose semantics) is
/// exercised in tests via a fake [FcmClient], with no real Firebase involved.
class VeloraFcmAdapter implements PushAdapter {
  final FcmClient _client;

  final StreamController<PushMessage> _onMessageController =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> _onMessageOpenedAppController =
      StreamController<PushMessage>.broadcast();

  late final StreamSubscription<Object?> _onMessageSub;
  late final StreamSubscription<Object?> _onMessageOpenedAppSub;

  VeloraFcmAdapter({FcmClient? client})
      : _client = client ?? FirebaseMessagingClient() {
    _onMessageSub = _client.onMessage.listen(
      (message) =>
          _onMessageController.add(pushMessageFromRemoteMessage(message)),
    );
    _onMessageOpenedAppSub = _client.onMessageOpenedApp.listen(
      (message) => _onMessageOpenedAppController
          .add(pushMessageFromRemoteMessage(message)),
    );
  }

  @override
  String get provider => 'fcm';

  @override
  Future<void> init() async {
    // Firebase itself must already be initialized by the app (see class doc)
    // before this adapter is constructed. Nothing else is required, so this
    // is intentionally a no-op.
  }

  @override
  Future<bool> requestPermission() => _client.requestPermission();

  @override
  Future<String?> getToken() => _client.getToken();

  @override
  Future<void> deleteToken() => _client.deleteToken();

  @override
  Stream<PushMessage> get onMessage => _onMessageController.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      _onMessageOpenedAppController.stream;

  @override
  Future<void> dispose() async {
    await _onMessageSub.cancel();
    await _onMessageOpenedAppSub.cancel();
    await _onMessageController.close();
    await _onMessageOpenedAppController.close();
  }
}
