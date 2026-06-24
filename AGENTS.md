# AGENTS.md

## Velora rules

- Follow `velora.md`, `velora.part2.md`, and `next2.md`.
- If they conflict, `velora.part2.md` wins for architecture; `next2.md` wins for logout safety.
- Use GetX-first design.
- Shared/business/session state lives in `GetxService`.
- Controllers contain local UI state and screen actions only.
- Repositories/data sources handle data access only.
- Keep MVP focused: no Firebase, Supabase, GraphQL, offline sync, payments, chat, push notifications, or visual builders.
- Public API should remain facade-like and simple.

## Verification

Run focused checks for touched packages when code changes. Docs-only changes do not require analyze/test commands unless specifically requested.

```sh
flutter analyze packages/velora
flutter analyze examples/velora_starter
dart analyze packages/velora_cli
```
