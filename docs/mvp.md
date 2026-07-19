# MVP Scope

Velora MVP focuses on Laravel-like productivity for Flutter apps.

## In scope

- Flutter runtime package in `packages/velora`.
- Dart CLI in `packages/velora_cli`.
- Reference Flutter app in `examples/claude_clone`.
- Laravel REST API defaults.
- Sanctum token authentication defaults.
- Role and permission helpers.
- GetX routing, dependency injection, controllers, and services.
- CRUD-oriented scaffolding.

## Already shipped beyond the original MVP

- Multi-page documentation site (built with mkdocs; see `docs/`).
- Package split into focused libraries: `velora` (runtime), `velora_cli` (scaffolding), `velora_lints`, and `velora_offline`.

## Out of scope for MVP

- Firebase.
- Supabase.
- GraphQL.

## Architecture anchor

Controllers extend `VeloraController` / `VeloraFormController` / `VeloraPaginatedController` and own their own screen-local Rx state. Services are plain classes wired by constructor injection in each module's factory — no app-level `GetxService`, no `Bindings` subclasses.
