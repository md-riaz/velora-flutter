# Velora

Laravel-like productivity for Flutter apps.

Velora is a batteries-included Flutter DX framework for Android, iOS, and Web apps. It works with any JSON API — REST or otherwise — and handles bearer-token auth, storage, routing, permissions, notifications, and more so you can focus on building features.

## Packages

- `packages/velora` — runtime framework package.
- `packages/velora_cli` — scaffolding CLI.
- `examples/velora_starter` — demo starter app.

## MVP scope

- GetX-first runtime with shared/business/session state in `GetxService`.
- Facade-style API: `Velora.api`, `Velora.auth`, `Velora.storage`, `Velora.nav`, `Velora.toast`, `Velora.permission`.
- Bearer-token auth with a mock mode for local UI/API testing.
- Role and permission UI helpers backed by server-enforced authorization.
- CRUD module scaffolding and starter conventions for service -> repository -> data source.
- Notification module scaffolding with remote push, local notification, in-app notification center, and noop/mock adapter conventions.
- AI-ready generated app context in `.ai/`.

## Architecture rule

`GetxService` owns shared/business/session state. Controllers own screen-only UI state. Repositories own data access. This follows the corrected plan in `velora.part2.md`.

```text
View -> Controller -> GetxService -> Repository -> DataSource -> Velora core
```

The starter app demonstrates local mock API testing: demo login writes a bearer token and user to Velora storage, and the Users module binds a mock remote data source. Swap that data source for a real API-backed implementation when connecting to your backend.

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
