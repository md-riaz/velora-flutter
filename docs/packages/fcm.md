# velora_fcm

**What you'll do:** Install `velora_fcm`, complete the Firebase platform setup it can't do for you, wire `VeloraFcmAdapter` into `Velora.boot`, and use `Velora.notify` to request permission, read the device token, and react to incoming push messages.

---

## What it does

`velora_fcm` is a real [`PushAdapter`](../notifications.md) backed by `firebase_messaging`. Unlike `velora_offline`/`velora_db`, it does **not** ship a `VeloraPlugin` — it ships a single adapter class, `VeloraFcmAdapter`, that you pass to a *named* `Velora.boot(...)` argument:

```dart
await Velora.boot(
  config: myConfig,
  pushAdapter: VeloraFcmAdapter(),
);
```

`pushAdapter:` is a top-level `Velora.boot()` argument (not nested under `notifications:`) — that's how the framework threads any push provider into the shared `NotificationService`/`VeloraNotify` without the core package ever depending on Firebase.

The package is intentionally small:

- **`VeloraFcmAdapter`** — implements `PushAdapter`: `requestPermission()`, `getToken()`, `deleteToken()`, and the `onMessage`/`onMessageOpenedApp` streams, all backed by Firebase Messaging.
- **`FcmClient`** (and its real implementation `FirebaseMessagingClient`) — the injectable seam between the adapter and `firebase_messaging`'s static, platform-channel-backed API. Tests inject a fake `FcmClient`; apps get the real one by default.
- **`pushMessageFromRemoteMessage`** — a pure function mapping a `firebase_messaging` `RemoteMessage` to Velora's transport-agnostic `PushMessage`.

## Install

!!! warning "Platform setup is required — it cannot be skipped"
    `velora_fcm` needs real Firebase project configuration and a `Firebase.initializeApp()` call before it can be constructed. `velora install velora_fcm` adds the pub dependency and prints these steps, but it cannot perform Firebase's platform setup or edit `main()` for you — there's no `plugins: [...]` list for this package to be spliced into (see [Plugins →](../plugins.md) for why `pushAdapter:` can't be auto-wired the way `VeloraOfflinePlugin()`/`VeloraDbPlugin()` are).

```yaml
dependencies:
  velora_fcm:
    path: packages/velora_fcm # or the pub.dev version once published
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.0
```

Or let the CLI add the dependency and print the full checklist:

```bash
velora install velora_fcm
```

Then, by hand:

1. **Configure Firebase for your app.** Run `flutterfire configure` — it generates `firebase_options.dart` and drops the native config files your platforms need (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
2. **Initialize Firebase before `Velora.boot()`.** `VeloraFcmAdapter` does not call `Firebase.initializeApp()` itself — the app must do it first:

    ```dart
    import 'package:firebase_core/firebase_core.dart';
    import 'package:velora/velora.dart';
    import 'package:velora_fcm/velora_fcm.dart';

    import 'firebase_options.dart';

    Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await Velora.boot(
        config: const VeloraConfig(
          appName: 'My App',
          apiBaseUrl: 'https://api.example.com/api',
          notifications: VeloraNotificationConfig(provider: PushProvider.fcm),
        ),
        pushAdapter: VeloraFcmAdapter(),
      );

      runApp(const MyApp());
    }
    ```

3. **Set `provider: PushProvider.fcm`** on `VeloraNotificationConfig` (this is already the default, but make it explicit alongside a real adapter).

Constructing `VeloraFcmAdapter()` before `Firebase.initializeApp()` has resolved will fail — the ordering above is not optional.

## Usage

Once booted, drive everything through `Velora.notify` — never reach for `FirebaseMessaging` directly from app code:

```dart
// Ask the user for permission (also triggered automatically after login if
// VeloraNotificationConfig.requestPermissionAfterLogin is true, the default).
final granted = await Velora.notify.requestPermission();

// Register the device token with your Laravel backend.
await Velora.notify.registerDeviceToken();

// React to a message that arrived while the app was foregrounded, or that
// the user tapped to open the app — go through NotificationService's own
// handling (initForUser() wires this up), not FirebaseMessaging streams.
await Velora.notify.initForUser();
```

## Testing without a device

`firebase_messaging`'s API is backed by platform channels that don't exist under `flutter test`. `velora_fcm` never talks to `firebase_messaging` directly outside of `FirebaseMessagingClient` — everything else goes through the `FcmClient` seam, so tests inject a fake:

```dart
class FakeFcmClient implements FcmClient {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => 'fake-token';

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<RemoteMessage> get onMessage => const Stream.empty();

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();
}

test('adapter reports fcm as its provider', () {
  final adapter = VeloraFcmAdapter(client: FakeFcmClient());
  expect(adapter.provider, 'fcm');
});
```

`pushMessageFromRemoteMessage` is a pure function, so it's testable directly against a `RemoteMessage.fromMap({...})` fixture with no client or Firebase involved at all.

---

**See also:** [Notifications →](../notifications.md) for `NotificationService`/`Velora.notify`, [Plugins →](../plugins.md) for why this package wires via `pushAdapter:` instead of `plugins: [...]`, and [velora_local_notifications →](local-notifications.md) for the matching local-notification adapter.
