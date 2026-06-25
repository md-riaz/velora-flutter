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

## Framework / App layer boundary

Before adding or moving any code, read [`docs/framework-app-boundary.md`](docs/framework-app-boundary.md).

The short version:
- **Framework** (`packages/velora/`) owns horizontal infrastructure: HTTP, auth, routing, storage, theme, pagination, feature flags, permissions, notifications, generic UI primitives, controller bases. Zero domain or brand knowledge.
- **App** owns domain models, data sources, controllers, pages, brand theme, route definitions, and any capability needed by only one app (YAGNI).

**Decision shortcut** — if the code would need to be rewritten for a different-domain app, it's app-layer. If it references a domain model, route name, or brand token, it's app-layer. When unsure, consult the gray-zone verdicts table in the doc.

Key patterns enforced in the demo (`examples/claude_theme_demo/`):
- Feature flags registered once in `main()`, not in controllers.
- All mutation methods guard local-state updates with `if (error.value.isNotEmpty) return;` after `await run(...)`.
- Optimistic updates roll back on failure.
- `loadEarlier` preserves scroll position via `maxScrollExtent` delta jump.

## Verification

Run focused checks for touched packages when code changes. Docs-only changes do not require analyze/test commands unless specifically requested.

```sh
flutter analyze packages/velora
flutter analyze examples/velora_starter
dart analyze packages/velora_cli
```
