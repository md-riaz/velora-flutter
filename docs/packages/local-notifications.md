# velora_local_notifications

**What you'll do:** Install `velora_local_notifications`, wire `VeloraLocalNotificationsAdapter` into `Velora.boot`, and show/schedule/cancel on-device notifications through `Velora.notify` — on Android and iOS/macOS, and in tests without a device.

---

## What it does

`velora_local_notifications` is a real [`LocalNotificationAdapter`](../notifications.md) backed by `flutter_local_notifications`. Like `velora_fcm`, it does **not** ship a `VeloraPlugin` — it ships a single adapter class, `VeloraLocalNotificationsAdapter`, passed to a *named* `Velora.boot(...)` argument:

```dart
await Velora.boot(
  config: myConfig,
  localAdapter: VeloraLocalNotificationsAdapter(),
);
```

`localAdapter:` is a top-level `Velora.boot()` argument (not nested under `notifications:`), the same shape as `pushAdapter:` — it's how any local-notification backend gets threaded into the shared `NotificationService`/`VeloraNotify` without the core package depending on `flutter_local_notifications`. Omit it and `Velora.boot()` falls back to `InMemoryLocalNotificationAdapter`, which only records calls in memory and shows nothing on-screen — fine for early development, not for a real app.

The package is intentionally small:

- **`VeloraLocalNotificationsAdapter`** — implements `LocalNotificationAdapter`'s `show`/`schedule`/`cancel`/`cancelAll`/`init`. Since `flutter_local_notifications` needs integer ids but Velora's contract uses `String` ids, `schedule()`/`cancel()` derive the int id from the caller-supplied string id via a stable 32-bit hash — no in-memory registry is involved, so the mapping is the same on every run, including after an app restart (scheduling the same string id twice overwrites the previous notification instead of leaving a duplicate, and canceling a string id works even if it was scheduled in a previous app session). `show()` has no caller id to hash, so it draws from a separate counter seeded from the current time.
- **`LocalNotificationsClient`** (and its real implementation `FlutterLocalNotificationsClient`) — the injectable seam between the adapter and the plugin's platform-channel-backed API, plus everything plugin-specific (Android notification channel, Darwin settings, timezone conversion via the `timezone` package).

## Install

```yaml
dependencies:
  velora_local_notifications:
    path: packages/velora_local_notifications # or the pub.dev version once published
```

Or let the CLI add the dependency and print the setup checklist:

```bash
velora install velora_local_notifications
```

This adds the dependency only — there's no `plugins: [...]` list for the CLI to splice `VeloraLocalNotificationsAdapter()` into (see [Plugins →](../plugins.md)), so wire it into `main()` by hand:

```dart
import 'package:velora/velora.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';

await Velora.boot(
  config: myConfig,
  localAdapter: VeloraLocalNotificationsAdapter(),
);
```

### Android

No manual channel setup is needed — `FlutterLocalNotificationsClient.initialize()` (called by `VeloraLocalNotificationsAdapter.init()`, which `NotificationService.initForUser()` calls for you) creates the notification channel (`velora_default_channel` by default) on first use. Make sure your app has a launcher icon at the default path (`@mipmap/ic_launcher`) or pass a custom `androidDefaultIcon` when constructing `FlutterLocalNotificationsClient` yourself. `initialize()` also requests the Android 13+ runtime notification permission itself (via `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()`), so local notifications work even in apps with no push adapter wired up — `Velora.notify.requestPermission()` (which only delegates to the *push* adapter) is not required for local notifications to appear.

### iOS / macOS

`initialize()` requests permission itself via `IOSFlutterLocalNotificationsPlugin`/`MacOSFlutterLocalNotificationsPlugin`'s `requestPermissions(alert: true, badge: true, sound: true)`, guarded so a platform without that implementation is a no-op. `Velora.notify.requestPermission()` is still worth calling for push notifications, but local notifications no longer depend on it.

## Usage

Drive local notifications through `Velora.notify` — never call `FlutterLocalNotificationsPlugin` directly from app code:

```dart
// Immediate notification.
await Velora.notify.showLocal(
  title: 'Upload complete',
  body: 'Your file finished processing.',
);

// Scheduled notification, keyed by your own string id.
await Velora.notify.scheduleLocal(
  id: 'daily_reminder',
  title: 'Reminder',
  body: 'Submit your timesheet',
  dateTime: DateTime.now().add(const Duration(hours: 8)),
);

// Cancel one scheduled notification, or everything.
await Velora.notify.cancelLocal('daily_reminder');
await Velora.notify.cancelAllLocal();
```

Scheduling the same `id` again reuses the underlying platform notification (overwrite, not duplicate); canceling an id that was never scheduled is a harmless no-op.

### Exact vs. inexact scheduling (Android)

`FlutterLocalNotificationsClient` schedules with `AndroidScheduleMode.inexactAllowWhileIdle` by default -- it needs no special permission and never throws a `SecurityException` on Android 12+/14+. If you need exact-time delivery, pass `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` explicitly when constructing the client, and make sure your app declares/requests the `SCHEDULE_EXACT_ALARM` permission (Android 12+ requires declaring it; Android 14+ also requires the user to grant it via Settings). Most reminder-style notifications are fine a few seconds/minutes off and should stick with the (safe) default:

```dart
localAdapter: VeloraLocalNotificationsAdapter(
  client: FlutterLocalNotificationsClient(
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // only if you truly need exact timing
  ),
),
```

## Testing without a device

`flutter_local_notifications` talks to platform channels that don't exist under `flutter test`. `VeloraLocalNotificationsAdapter` never touches the plugin directly outside of `FlutterLocalNotificationsClient` — everything else goes through the `LocalNotificationsClient` seam, so tests inject a fake:

```dart
class FakeLocalNotificationsClient implements LocalNotificationsClient {
  final shown = <int>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(int id, String? title, String? body, {String? payload}) async {
    shown.add(id);
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
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

test('show() synthesizes an id and forwards it to the client', () async {
  final client = FakeLocalNotificationsClient();
  final adapter = VeloraLocalNotificationsAdapter(client: client);

  await adapter.show(title: 'Hello', body: 'World');

  expect(client.shown, hasLength(1));
});
```

Because the id-mapping logic (the interesting part of this adapter) only ever touches plain `int`/`String`/`DateTime` values, it's fully exercised this way with no platform channel involved.

## Native notifications (new API)

`VeloraNativeNotifications` is the provider-neutral facade for showing notifications with action buttons, text inputs, and activation tracking. New code should use it instead of `LocalNotificationAdapter`.

```dart
import 'package:velora_local_notifications/velora_local_notifications.dart';

final notifications = FlutterLocalNotificationsNativeAdapter();
await notifications.initialize();

// Listen for activations (body taps, action buttons, text input).
notifications.activations.listen((activation) {
  print('Notification ${activation.id} tapped');
  if (activation.actionId != null) {
    print('Action: ${activation.actionId}');
  }
  if (activation.input != null) {
    print('User typed: ${activation.input}');
  }
});

// Show a notification with actions.
await notifications.show(VeloraNativeNotification(
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
));
```

### Models

- **`VeloraNativeNotification`** — content, stable string ID (same ID replaces), actions, silent flag, payload.
- **`VeloraNativeAction`** — action button with optional text input placeholder.
- **`VeloraNotificationActivation`** — delivered when the user taps a notification or action. Includes the original string ID, action ID, user input, payload, and platform-specific data.

### Activation stream

The `activations` stream merges cold-start (app launched by a notification tap) and live (app already running) activations. Duplicate activations within a 2-second window are suppressed.

### Windows support

`FlutterLocalNotificationsClient` accepts `windowsAppName`, `windowsAppUserModelId`, `windowsGuid`, and `windowsIconPath` for Windows toast configuration. On Windows, text input values arrive in `VeloraNotificationActivation.data` keyed by the action's input ID (not in `input`), matching `flutter_local_notifications_windows` behavior.

### Compatibility

`NativeNotificationsCompat` (deprecated) wraps `VeloraNativeNotifications` into the old `LocalNotificationAdapter` interface for one deprecation cycle:

```dart
// ignore: deprecated_member_use
final adapter = NativeNotificationsCompat(nativeNotifications);
await Velora.boot(config: myConfig, localAdapter: adapter);
```

### Testing

Use `FakeNativeNotifications` for unit tests:

```dart
final fake = FakeNativeNotifications();
await fake.initialize();
await fake.show(VeloraNativeNotification(id: 'test', title: 'Test'));
expect(fake.shown, hasLength(1));

// Simulate an activation.
fake.simulateActivation(VeloraNotificationActivation(id: 'test'));
```

---

**See also:** [Notifications →](../notifications.md) for `NotificationService`/`Velora.notify`, [Plugins →](../plugins.md) for why this package wires via `localAdapter:` instead of `plugins: [...]`, [velora_fcm →](fcm.md) for the matching remote-push adapter, and [velora_desktop →](desktop.md) for forwarding activations to the desktop coordinator.
