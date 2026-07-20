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
///
/// ## init()/dispose() are reversible
///
/// `NotificationService` owns a single, permanent `VeloraFcmAdapter`
/// instance for the app's whole lifetime and calls `init()` on login and
/// `dispose()` on logout (`disposeForUser()`), potentially many times across
/// a session (login -> logout -> login -> ...). So that later logins keep
/// working, [dispose] only cancels the underlying Firebase stream
/// subscriptions — it never closes [onMessage]/[onMessageOpenedApp]
/// themselves. Those broadcast controllers are created once and live for
/// the lifetime of the adapter; [init] (re)subscribes to the Firebase
/// streams every time it runs, so events start flowing again on the next
/// login.
class VeloraFcmAdapter implements PushAdapter {
  final FcmClient _client;

  final StreamController<PushMessage> _onMessageController =
      StreamController<PushMessage>.broadcast();
  final StreamController<PushMessage> _onMessageOpenedAppController =
      StreamController<PushMessage>.broadcast();

  StreamSubscription<Object?>? _onMessageSub;
  StreamSubscription<Object?>? _onMessageOpenedAppSub;

  VeloraFcmAdapter({FcmClient? client})
      : _client = client ?? FirebaseMessagingClient();

  @override
  String get provider => 'fcm';

  @override
  Future<void> init() async {
    // Firebase itself must already be initialized by the app (see class doc)
    // before this adapter is constructed.

    // Guard against double-subscription: if init() is called again without
    // an intervening dispose() (or after a previous dispose()), cancel any
    // existing subscriptions before wiring up fresh ones.
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();

    _onMessageSub = _client.onMessage.listen(
      (message) =>
          _onMessageController.add(pushMessageFromRemoteMessage(message)),
    );
    _onMessageOpenedAppSub = _client.onMessageOpenedApp.listen(
      (message) => _onMessageOpenedAppController
          .add(pushMessageFromRemoteMessage(message)),
    );

    // `onMessageOpenedApp` never fires for a notification tap that launches
    // the app from a terminated state -- that launch message only shows up
    // via `getInitialMessage()`. Surface it through the same
    // `onMessageOpenedApp` stream so `NotificationService`'s single
    // opened-app listener handles cold-start taps identically to
    // warm/background ones. `getInitialMessage()` returns the message at
    // most once (it's consumed after being read), so this can't double-fire
    // across repeated init() calls within the same app launch.
    final initialMessage = await _client.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedAppController.add(
        pushMessageFromRemoteMessage(initialMessage),
      );
    }
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
    // Deliberately does NOT close `_onMessageController` /
    // `_onMessageOpenedAppController` -- see the class doc. Only the
    // underlying Firebase subscriptions are torn down, so a later `init()`
    // call can re-subscribe and resume delivering events on the same
    // (still-open) streams.
    await _onMessageSub?.cancel();
    await _onMessageOpenedAppSub?.cancel();
    _onMessageSub = null;
    _onMessageOpenedAppSub = null;
  }
}
