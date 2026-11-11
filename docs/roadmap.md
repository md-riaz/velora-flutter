# Roadmap

## MVP

- Core Velora runtime package.
- CLI scaffolding package.
- Reference Flutter app (`examples/claude_clone`).
- Laravel Sanctum auth defaults.
- API, storage, navigation, toast, permission, form, and error helpers.
- Constructor-injected controller/service/repository layer.

## Shipped

- Package split into `velora`, `velora_cli`, `velora_lints`, `velora_offline`, `velora_db`, `velora_env`, `velora_fcm`, `velora_local_notifications`, and `velora_ui`.
- Design system (`velora_ui`): tokens and theme, core components, form inputs, layout, navigation, feedback/overlays, and data table, stepper/wizard, and adaptive shell — see [velora_ui](packages/ui.md) for the component list.
- Push and on-device notifications through the optional `velora_fcm` and `velora_local_notifications` adapters.
- `.env` config and flavors (`velora_env`).
- Toolchain baseline of Flutter 3.47 / Dart 3.13 — see [Toolchain baseline](toolchain.md).
- Multi-page documentation site (mkdocs).
- Reactive local database (`velora_db`) on drift — native and web (WASM SQLite, persisted via OPFS/IndexedDB), with an Eloquent-style query API plus `watch*` reactive reads.
- Offline-first data layer (`velora_offline`) — connectivity awareness, an offline outbox for writes that replays on reconnect, and a reactive, optimistic offline-first repository layered over `velora_db`.
- Installable, offline-capable web (PWA): `velora make:pwa` scaffolds a manifest and a service worker that caches the app shell and `velora_db`'s WASM assets.
- Version-aware lookup in the CLI: `velora search`, `component`, `docs`, and `manifest` answer from a project's installed packages, with JSON envelopes and stable error codes — see [Agent Tooling](agent-tooling.md).

## Later

Not shipped. Tracked as GitHub issues, and subject to change.

- CRUD page templates in `velora make:module` built on the `velora_ui` data table and shell.
- Page templates (`velora template`), structured accessibility/theme metadata per component, and an MCP wrapper over the same lookup commands.
- Splitting optional core capabilities into focused packages.
- Realtime, desktop lifecycle, and Windows notification support.
- More backend presets.
