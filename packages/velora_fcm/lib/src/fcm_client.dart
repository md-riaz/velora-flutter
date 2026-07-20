import 'package:firebase_messaging/firebase_messaging.dart';

/// A thin seam around the static `firebase_messaging` plugin surface.
///
/// `firebase_messaging`'s platform channel calls (`FirebaseMessaging.instance`,
/// `FirebaseMessaging.onMessage`, ...) don't work under `flutter test` because
/// there's no real platform behind them. [VeloraFcmAdapter] never talks to
/// `firebase_messaging` directly — it only calls through an [FcmClient], so
/// tests can inject a fake implementation and exercise the adapter's logic
/// (stream mapping, provider id, dispose semantics) fully headlessly.
///
/// The default, real implementation is [FirebaseMessagingClient].
abstract class FcmClient {
  /// Requests notification permission from the user and reports whether it
  /// was granted (`true` for both `authorized` and `provisional`).
  Future<bool> requestPermission();

  /// Returns the current FCM registration token, or `null` if unavailable.
  Future<String?> getToken();

  /// Deletes the current FCM registration token.
  Future<void> deleteToken();

  /// Messages received while the app is in the foreground.
  Stream<RemoteMessage> get onMessage;

  /// Messages that caused the user to tap a notification and open the app.
  Stream<RemoteMessage> get onMessageOpenedApp;
}

/// The real [FcmClient], backed by `FirebaseMessaging.instance`.
///
/// Requires `Firebase.initializeApp()` to have already run (typically in
/// `main()`, before `Velora.boot()`) — this class does not initialize
/// Firebase itself.
class FirebaseMessagingClient implements FcmClient {
  final FirebaseMessaging _messaging;

  FirebaseMessagingClient({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}
