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

`OfflineRequestQueue.flush()` replays queued requests strictly in order, through the same `VeloraApiService` used everywhere else in the app (so auth headers and interceptors still apply). It never throws, and it never reorders. A transient failure — no connectivity, a 5xx server error, or a `408`/`429` response — halts the flush immediately and leaves that item and everything behind it queued for the next reconnect. A permanent `4xx` response (any other client error — the request can never succeed as-is, a "poison pill") is discarded, and the flush continues with the next item.

## Offline-first: reactive local store + write sync

`velora_offline` bundles [`velora_db`](db.md) as its reactive local store engine, and layers an **offline-first repository** on top: `VeloraOfflineFirstRepository<T, ID>`. This is the offline-first (Dexie-in-a-browser-style) pattern, as opposed to the read-through cache pattern `velora_db`'s `VeloraCachedRepository` implements on its own (see the contrast below).

- **Reads are reactive and local-first.** The bound `VeloraTable` is the source of truth for every read — `watchAll()` / `watchQuery(...)` / `watchFind(id)` return Streams that emit immediately and re-emit on every local write, so UI bound to them updates instantly and works fully offline.
- **Writes are optimistic-local, then synced.** `store` / `update` / `destroy` write to the local table *first* (so the UI updates immediately), then enqueue the write onto the same `OfflineRequestQueue` this package already ships, so it's delivered to the server over conventional Laravel resource routes rooted at an `endpoint` you supply: create → `POST {endpoint}`, update → `PUT {endpoint}/{id}`, delete → `DELETE {endpoint}/{id}`. If already online, a flush is kicked off immediately; otherwise it waits for the next reconnect, exactly like any other queued write.

Building one requires both `VeloraDbPlugin()` and `VeloraOfflinePlugin()` to have booted, since it resolves a `VeloraTable` (from `velora_db`) alongside the `OfflineRequestQueue` / `ConnectivityService` this package registers:

```dart
import 'package:flutter/material.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_offline/velora_offline.dart';

await Velora.boot(
  config: myConfig,
  plugins: [
    VeloraDbPlugin(migrations: [CreateTodosTable()]),
    VeloraOfflinePlugin(),
  ],
);

final todos = VeloraOffline.offlineFirst<TodoModel, String>(
  table: VeloraDb.table<TodoModel, String>(
    table: 'todos',
    fromMap: TodoModel.fromJson,
    toMap: (todo) => todo.toJson(),
  ),
  endpoint: 'todos',
);

// Bind straight to the reactive stream -- this is the whole point.
StreamBuilder<List<TodoModel>>(
  stream: todos.watchAll(),
  builder: (context, snapshot) {
    final items = snapshot.data ?? const [];
    return ListView(children: [for (final t in items) Text(t.title)]);
  },
);

// A UUID must be generated client-side, since store() writes locally
// before the server ever sees the row -- there's no server id to wait for.
await todos.store({'id': uuid.v4(), 'title': 'Buy milk'});
```

Two things to keep in mind:

- **IDs must be client-generated.** Because `store()` writes to the local table before the request even reaches the queue, an offline create has no server-assigned id to fall back on — include the primary key (e.g. a UUID) in the `data` map yourself.
- **Server → local reconciliation is your app's job.** `VeloraOfflineFirstRepository` only pushes local writes outward; it never pulls fresh server data down. Poll an endpoint or open a websocket and write what comes back into the same `VeloraTable` (an upsert via `table.create`/`table.update`) — that write reactively flows through to every open `watchAll()` / `watchQuery(...)` / `watchFind(id)` stream, the same as any other local write.

Compare with `velora_db`'s `VeloraCachedRepository`: that one is **network-first**, read-through caching — reads always try the remote API first and fall back to the local cache only when offline. `VeloraOfflineFirstRepository` is the opposite — local-first for both reads and writes — so reach for it when the local store, not the server, should be what the UI renders.

## Testing without platform plugins

`velora_offline` is unit-testable without `connectivity_plus`'s platform channels: `VeloraOfflinePlugin(source: ...)` accepts any `ConnectivitySource`, so tests can inject a fake that pushes connectivity events on demand instead of touching a real device radio.

---

**See also:** [Plugins →](../plugins.md) for the `VeloraPlugin` / `VeloraContext` contract this package implements, and [API Client →](../api-client.md) for `VeloraApiInterceptor`.
