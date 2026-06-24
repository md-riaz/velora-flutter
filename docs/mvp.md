# MVP Scope

Velora MVP focuses on Laravel-like productivity for Flutter apps.

## In scope

- Flutter runtime package in `packages/velora`.
- Dart CLI in `packages/velora_cli`.
- Starter Flutter app in `examples/velora_starter`.
- Laravel REST API defaults.
- Sanctum token authentication defaults.
- Role and permission helpers.
- GetX routing, dependency injection, controllers, and services.
- CRUD-oriented scaffolding.

## Out of scope for MVP

- Firebase.
- Supabase.
- GraphQL.
- Large documentation site.
- Early package split into many optional libraries.

## Architecture anchor

GetxService owns shared and business state. Controllers coordinate UI state and user actions only.
