# Velora Chat

An offline-first messaging demo built on `velora_db` and `velora_offline`. It
shows a full conversations list + message thread UI where every read is a
reactive, local-first stream and every write lands locally first and
survives being offline.

## What it demonstrates

- **Reactive local reads** — `VeloraOfflineFirstRepository.watchQuery` drives
  both the conversations list and each message thread straight from
  `velora_db`, so the UI updates the instant a row changes, online or off.
- **Outbox-backed writes** — sending a message writes it to `velora_db`
  immediately (visible right away with `status: 'pending'`) and enqueues it
  onto `velora_offline`'s write outbox. If the app is online, the outbox
  flushes right away; if not, the message just waits until connectivity
  returns.
- **Simulated server round-trip** — there's no real backend. A
  `MockChatServerInterceptor` stands in for one: it acknowledges queued
  writes (flipping them from `'pending'` to `'sent'`) and periodically
  simulates the other side replying, so every reactive stream in the app
  updates exactly as it would from a real server.
- **An in-app connectivity toggle** — a `ToggleConnectivitySource` lets you
  flip the app between "online" and "offline" from a switch in the UI,
  instead of relying on airplane mode or a flaky real network, to see the
  outbox fill up and drain on demand.

See [`../../docs/examples.md`](../../docs/examples.md) for a fuller
walkthrough of the outbox/connectivity flow and the mock server.

## Running it

```bash
flutter run
```

Use the online/offline switch in the app to simulate connectivity drops:
send a few messages while "offline" and watch them sit as `pending` in the
outbox, then flip back "online" and watch them flush and get acknowledged.

To build the installable, offline-capable PWA:

```bash
flutter build web
```

Serve `build/web` over HTTPS (or `localhost`, which counts as secure) to
test the service worker's offline behavior — see
[`../../docs/pwa.md`](../../docs/pwa.md).
