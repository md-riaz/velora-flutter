# Velora

Laravel-like productivity for Flutter apps.

Velora is a batteries-included Flutter DX framework for Android, iOS, and Web apps. It works with any JSON API — REST or otherwise — and handles bearer-token auth, storage, routing, permissions, notifications, and more so you can focus on building features.

## Packages

- `packages/velora` — runtime framework package.
- `packages/velora_cli` — scaffolding CLI.
- `examples/claude_clone` — hand-built reference example app.

## MVP scope

- Constructor-injected runtime: controllers extend `VeloraController` / `VeloraFormController` / `VeloraPaginatedController`; services are plain classes wired by the module factories `velora new` / `make:module` generate.
- Facade-style API: `Velora.api`, `Velora.auth`, `Velora.storage`, `Velora.nav`, `Velora.toast`, `Velora.permission`.
- Bearer-token auth; app-level mock data sources for local UI/API testing (see [Getting Started](docs/getting-started.md)).
- Role and permission UI helpers backed by server-enforced authorization.
- CRUD module scaffolding and conventions for controller -> service -> repository -> data source.
- Notification module scaffolding with remote push, local notification, in-app notification center, and noop/mock adapter conventions.
- AI-ready generated app context in `.ai/`.
- Official installable packages via `velora install <package>`: `velora_offline` (offline-first data layer), `velora_db` (reactive local database), `velora_env` (env config/flavors), plus `velora_fcm` / `velora_local_notifications` for push and on-device notifications.

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
dart run velora_cli make:auth
dart run velora_cli make:module users --crud
dart run velora_cli make:notifications
dart run velora_cli install:push --fcm
dart run velora_cli install:push --local
```

## Docs

Start with `docs/README.md` for architecture, auth/logout safety, API, permissions, scaffolding, notifications, commands, and AI-ready notes.
