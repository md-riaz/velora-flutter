# Roadmap

## MVP

- Core Velora runtime package.
- CLI scaffolding package.
- Reference Flutter app (`examples/claude_clone`).
- Laravel Sanctum auth defaults.
- API, storage, navigation, toast, permission, form, and error helpers.
- Constructor-injected controller/service/repository layer.

## Shipped

- Package split into `velora`, `velora_cli`, `velora_lints`, `velora_offline`, `velora_db`, `velora_env`, `velora_fcm`, and `velora_local_notifications`.
- Multi-page documentation site (mkdocs).
- Reactive local database (`velora_db`) on drift — native and web (WASM SQLite, persisted via OPFS/IndexedDB), with an Eloquent-style query API plus `watch*` reactive reads.
- Offline-first data layer (`velora_offline`) — connectivity awareness, an offline outbox for writes that replays on reconnect, and a reactive, optimistic offline-first repository layered over `velora_db`.
- Installable, offline-capable web (PWA): `velora make:pwa` scaffolds a manifest and a service worker that caches the app shell and `velora_db`'s WASM assets.

## Later

- Expanded UI kit.
- More backend presets.
