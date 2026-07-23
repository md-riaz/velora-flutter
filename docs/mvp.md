# MVP Scope

Velora MVP focuses on Laravel-like productivity for Flutter apps.

## In scope

- Flutter runtime package in `packages/velora`.
- Dart CLI in `packages/velora_cli`.
- Reference Flutter app in `examples/claude_clone`.
- Laravel REST API defaults.
- Sanctum token authentication defaults.
- Role and permission helpers.
- GetX declarative routing (`GetPage`/`Navigator`).
- Dependency injection via plain constructor injection in each module's factory, controllers, and services.
- CRUD-oriented scaffolding.

## Already shipped beyond the original MVP

- Multi-page documentation site (built with mkdocs; see `docs/`).
- Package split into focused libraries: `velora` (runtime), `velora_cli` (scaffolding), `velora_lints`, `velora_offline`, `velora_db`, `velora_env`, `velora_fcm`, and `velora_local_notifications`.
- Reactive local database (`velora_db`) on drift — native and web (WASM SQLite), with an Eloquent-style API and `watch*` reactive reads.
- Offline-first data layer (`velora_offline`): connectivity, an offline write outbox, and a reactive, optimistic offline-first repository over `velora_db`.
- Installable, offline-capable web (PWA) via `velora make:pwa` (manifest + a service worker caching the app shell and `velora_db`'s WASM assets).

## Out of scope for MVP

- Firebase as a general backend (Firestore/Auth) — though `velora_fcm` provides an optional Firebase Cloud Messaging push adapter.
- Supabase.
- GraphQL.

## Architecture anchor

Controllers extend `VeloraController` / `VeloraFormController` / `VeloraPaginatedController` and own their own screen-local Rx state. Services are plain classes wired by constructor injection in each module's factory — no app-level `GetxService`, no `Bindings` subclasses.
