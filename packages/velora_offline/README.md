# velora_offline

Offline-first data layer for Velora apps: connectivity awareness, a write outbox that replays on reconnect, and an optimistic offline-first repository over `velora_db`.

Wired as `Velora.boot(plugins: [VeloraOfflinePlugin()])`; `velora install velora_offline` does this for you.

Requires Flutter >=3.47.0 / Dart >=3.13.0. Not published to pub.dev yet; use a git or path dependency.

Full guide: [`docs/packages/offline.md`](../../docs/packages/offline.md).
