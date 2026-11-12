# Velora

Laravel-like productivity for Flutter apps.

Velora is a batteries-included Flutter DX framework for Android, iOS, and Web apps. It works with any JSON API — REST or otherwise — and handles bearer-token auth, storage, routing, permissions, notifications, and more so you can focus on building features.

Requires Flutter 3.47.0+ / Dart 3.13.0+ — see [Toolchain baseline](docs/toolchain.md).

## Packages

- `packages/velora` — runtime framework package.
- `packages/velora_cli` — scaffolding CLI.
- `examples/claude_clone` — hand-built reference example app.
- `examples/velora_chat` — WhatsApp-style offline-first messaging demo built on `velora_db` + `velora_offline` (see [Example apps](docs/examples.md)).
- `examples/velora_catalog` — network-first catalog/reader demo built on `velora_db`'s `VeloraCachedRepository` (see [Example apps](docs/examples.md)).
- `examples/velora_ui_gallery` — showcase app for the `velora_ui` design system ([live demo](https://md-riaz.github.io/velora-flutter/gallery/)).

## MVP scope

- Constructor-injected runtime: controllers extend `VeloraController` / `VeloraFormController` / `VeloraPaginatedController`; services are plain classes wired by the module factories `velora new` / `make:module` generate.
- Facade-style API: `Velora.api`, `Velora.auth`, `Velora.storage`, `Velora.nav`, `Velora.toast`, `Velora.permission`.
- Bearer-token auth; app-level mock data sources for local UI/API testing (see [Getting Started](docs/getting-started.md)).
- Role and permission UI helpers backed by server-enforced authorization.
- CRUD module scaffolding and conventions for controller -> service -> repository -> data source.
- Notification module scaffolding with remote push, local notification, in-app notification center, and noop/mock adapter conventions.
- AI-ready generated app context in `.ai/`.
- Official installable packages via `velora install <package>` — see [Installable packages](#installable-packages).

## Installable packages

<!-- generated:installable-packages source=packages/velora_cli/lib/velora_cli.dart — do not edit; run tool/check_docs.sh --write -->
| Package | What it is | Wiring | Docs |
|---|---|---|---|
| `velora_offline` | Offline-first data layer: connectivity, write outbox, optimistic repository over velora_db. | `plugins: [VeloraOfflinePlugin()]` (automatic) | [offline](docs/packages/offline.md) |
| `velora_db` | Reactive local database on drift (native and web WASM SQLite). | `plugins: [VeloraDbPlugin()]` (automatic) | [db](docs/packages/db.md) |
| `velora_env` | `.env` config and dev/staging/prod flavors. | `plugins: [VeloraEnvPlugin()]` (automatic) | [env](docs/packages/env.md) |
| `velora_fcm` | Firebase Cloud Messaging push adapter. | `pushAdapter: VeloraFcmAdapter()` (manual) | [fcm](docs/packages/fcm.md) |
| `velora_local_notifications` | On-device local notifications adapter. | `localAdapter: VeloraLocalNotificationsAdapter()` (manual) | [local-notifications](docs/packages/local-notifications.md) |
| `velora_desktop` | Desktop lifecycle: close-to-tray, single instance, protocol activation, auto-start, suspend/resume. | Manual — construct `VeloraDesktopCoordinator` in `main()` | [desktop](docs/packages/desktop.md) |
| `velora_ui` | Token-first design system: theme, tokens, and components. | `theme: VeloraTheme.light()` on your app (manual) | [ui](docs/packages/ui.md) |
<!-- /generated:installable-packages -->

## Architecture rule

Controllers extend `VeloraController` (or `VeloraFormController` / `VeloraPaginatedController`) and own screen-only UI state. Services are plain classes owning business logic. Repositories own data access. Everything is wired by plain constructor dependency injection in each module's factory — no `Get.lazyPut`, no `Bindings` subclass required. See [Architecture](docs/architecture.md) for the full walkthrough.

```text
View -> Controller -> Service -> Repository -> DataSource -> Velora core
```

`examples/claude_clone` is a hand-built reference app showing this pattern at a larger scale, including app-owned mock data sources swapped in for local development.

## CLI examples

Run CLI commands from `packages/velora_cli` during local development:

```sh
cd packages/velora_cli
dart run velora_cli doctor
dart run velora_cli new admin_panel
dart run velora_cli make:auth --sanctum
dart run velora_cli make:module users --crud
dart run velora_cli make:notifications
dart run velora_cli make:pwa
dart run velora_cli install:push --fcm
dart run velora_cli install:push --local
dart run velora_cli install velora_db
```

## Docs

Start with `docs/README.md` for architecture, auth/logout safety, API, permissions, scaffolding, notifications, commands, and AI-ready notes.
