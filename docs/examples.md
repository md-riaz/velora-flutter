# Example apps

**What you'll find here:** two full apps in `examples/`, built entirely on shipped Velora packages, that show what a real app looks like end to end rather than isolated snippets.

---

## velora_chat — offline-first messaging demo

`examples/velora_chat` is a WhatsApp-style chat app: a conversations list and a per-conversation message thread, both backed by a local reactive database and an offline write outbox instead of a live backend. It exists to show how [`velora_db`](packages/db.md) and [`velora_offline`](packages/offline.md) fit together in a shape you'd actually ship — reactive reads, optimistic writes, a write outbox that survives disconnects, and PWA support — not how to call each package's API in isolation.

### Schema

One `VeloraMigration` creates both tables the app needs:

```dart
class CreateChatSchema extends VeloraMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(VeloraMigrationContext context) async {
    await context.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        last_message TEXT,
        last_at INTEGER,
        unread INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await context.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        body TEXT NOT NULL,
        outgoing INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }
}
```

No `build_runner`, no generated table classes — `Conversation` and `Message` are plain classes with a `fromMap`/`toMap` pair, same as every other `velora_db` table.

### Reactive reads

The conversations list and the message thread both bind directly to a `watchQuery` stream — no manual refresh, no pull-to-reload:

```dart
// ConversationsController — newest activity first.
_subscription = _table
    .watchQuery(_table.query().orderBy('last_at', desc: true))
    .listen((rows) => conversations.assignAll(rows));

// ChatController — one conversation's thread, oldest first.
_subscription = _messages
    .watchQuery(
      _messages.query().where('conversation_id', conversationId).orderBy('created_at'),
    )
    .listen((rows) => messages.assignAll(rows));
```

Every insert/update anywhere in the app — a locally-sent message, a simulated incoming reply, an outbox flush marking a message `sent` — flows straight through these streams into the UI, because they all go through the same `velora_db` write path that notifies `watch*` listeners.

### Optimistic sends + the write outbox

Sending a message goes through `velora_offline`'s `VeloraOfflineFirstRepository`, not a raw API call:

```dart
final messagesRepo = VeloraOffline.offlineFirst<Message, String>(
  table: messagesTable(),
  endpoint: 'messages',
);

Future<void> send(String text) async {
  final message = Message(
    id: const Uuid().v4(), // client-generated — see offline.md
    conversationId: conversationId,
    body: text,
    outgoing: true,
    status: 'pending',
    createdAt: DateTime.now(),
  );
  await messagesRepo.store(message.toMap());
}
```

`store()` writes the message to `velora_db` first — instantly, with `status: 'pending'` — then enqueues it onto the offline write outbox. If the app is online, a flush kicks off immediately; if not, the message just sits in the outbox (visible as a badge on the conversations list) until connectivity returns.

### The connectivity toggle

Real device connectivity is hard to demo reliably, so the app ships a `ToggleConnectivitySource` — a `ConnectivitySource` the UI can flip directly:

```dart
class ToggleConnectivitySource implements ConnectivitySource {
  bool _online;
  final _controller = StreamController<bool>.broadcast();

  ToggleConnectivitySource({bool online = true}) : _online = online;

  @override
  Future<bool> isConnected() async => _online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }
}
```

Passed to `VeloraOfflinePlugin(source: toggleSource)` at boot, this is exactly the same seam `velora_offline`'s own tests use — see [Testing without platform plugins](packages/offline.md#testing-without-platform-plugins) — reused here as an in-app demo control instead of a test fake. Flipping the conversations page's `Switch` drives the real `ConnectivityService`, which flushes the outbox on the same offline → online transition a dropped-then-restored network connection would trigger.

### The mock server: what it does, and what it deliberately doesn't

There's no backend behind this demo. A `MockChatServerInterceptor` (a `VeloraApiInterceptor`) stands in for one, registered once after boot:

```dart
Velora.api.addInterceptor(MockChatServerInterceptor());
```

It short-circuits any `POST` to a path containing `messages`: after a short delay (so the `'pending'` state is visible in the UI), it writes `status: 'sent'` back into the local `messages` table and resolves the request — instead of ever reaching the network. Every third outgoing message, it also simulates the other side of the conversation replying, inserting an incoming message straight into `velora_db`.

This is deliberately a simplification worth calling out: **`velora_offline`'s outbox only delivers a write — it never pulls anything back down.** In a real app, the server would receive the queued request and your own sync mechanism (a poll, a websocket) would write the acknowledged/updated row back into `velora_db`, exactly as this interceptor does by hand. Reconciling server responses into the local store is the app's job, not the plugin's — see `VeloraOfflineFirstRepository`'s dartdoc and the [offline-first section](packages/offline.md#offline-first-reactive-local-store--write-sync) of these docs.

### PWA

`velora_chat` is PWA-enabled the same way any Velora web app is:

```bash
cd examples/velora_chat
velora make:pwa
```

This writes `web/manifest.json` and `web/service_worker.js` and registers the worker in `web/index.html` — see [Web & PWA](pwa.md) for what the generated service worker caches and how to test it offline.

### Running it

```bash
cd examples/velora_chat
flutter pub get
flutter run -d chrome   # or any connected device
```

Toggle the `Switch` in the app bar to offline, send a message (it shows a clock icon while `'pending'`), then toggle back online and watch it flip to a check mark as the mock server acknowledges it — with an outbox badge counting down as pending writes flush.

---

## claude_clone — theming & core reference app

`examples/claude_clone` is the other example app in this repo: a Claude-style AI chat UI demonstrating Velora's *core* DX layer — a brand-specific `ThemeExtension` system, light/dark mode persistence, auth guards, attachments, and the module/controller/page structure every Velora app follows. Where `velora_chat` is the offline/local-data reference, `claude_clone` is the theming/core reference — read it for how to structure routes, controllers, and app-owned mock data sources before swapping in a real backend.

---

**See also:** [velora_db →](packages/db.md) and [velora_offline →](packages/offline.md) for the packages this app wires together, and [Web & PWA →](pwa.md) for what `make:pwa` generates.
