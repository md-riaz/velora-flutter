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

---

**See also:** [Notifications →](../notifications.md) for `NotificationService`/`Velora.notify`, [Plugins →](../plugins.md) for why this package wires via `localAdapter:` instead of `plugins: [...]`, and [velora_fcm →](fcm.md) for the matching remote-push adapter.
