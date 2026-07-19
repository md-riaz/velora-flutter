# velora_offline

**What you'll do:** Install the first official Velora package, wire it into `Velora.boot`, and use it to detect connectivity and queue writes made while offline.

---

## What it does

`velora_offline` is the reference implementation of a [Velora plugin](../plugins.md): a self-contained package that proves the plugin contract end-to-end. It adds two things to a booted app:

- **`ConnectivityService`** — a reactive `isOnline` flag backed by `connectivity_plus`, plus an `onOnline` hook that fires exactly once per offline → online transition.
- **`OfflineRequestQueue`** — persists write requests (`POST`/`PUT`/`PATCH`/`DELETE`) that fail with a connection-level error, and replays them in order once connectivity returns.

The two are wired together automatically: an `OfflineQueueInterceptor` on the shared `VeloraApiService` queues failed writes, and the queue flushes whenever `ConnectivityService` reports a reconnect.

## Install

```yaml
dependencies:
  velora_offline:
    path: packages/velora_offline # or the pub.dev version once published
```

## Boot

```dart
import 'package:velora/velora.dart';
import 'package:velora_offline/velora_offline.dart';

await Velora.boot(
  config: myConfig,
  plugins: [VeloraOfflinePlugin()],
);
```

That's it — connectivity tracking starts immediately, and any write that fails with a connection error is queued for replay.

## Using it

```dart
import 'package:velora_offline/velora_offline.dart';

// Reactive: rebuild a widget whenever connectivity changes.
Obx(() => VeloraOffline.isOnline
    ? const Icon(Icons.cloud_done)
    : const Icon(Icons.cloud_off));

// One-shot check.
if (!VeloraOffline.isOnline) {
  showSnackBar('You are offline — changes will sync automatically.');
}

// Inspect or manipulate the queue directly.
final pendingCount = VeloraOffline.queue.pending.length;
await VeloraOffline.queue.flush(); // force a replay attempt
```

Queued writes persist across app restarts (backed by `VeloraStorageService`), and are cleared automatically on logout.

## How replay works

`OfflineRequestQueue.flush()` replays queued requests strictly in order, through the same `VeloraApiService` used everywhere else in the app (so auth headers and interceptors still apply). If a replay fails, `flush()` stops immediately and leaves the remaining items queued — it never throws, and it never reorders or drops a write.

## Testing without platform plugins

`velora_offline` is unit-testable without `connectivity_plus`'s platform channels: `VeloraOfflinePlugin(source: ...)` accepts any `ConnectivitySource`, so tests can inject a fake that pushes connectivity events on demand instead of touching a real device radio.

---

**See also:** [Plugins →](../plugins.md) for the `VeloraPlugin` / `VeloraContext` contract this package implements, and [API Client →](../api-client.md) for `VeloraApiInterceptor`.
