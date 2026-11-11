# Contributing Notes

Keep Velora changes focused on MVP productivity.

The workspace requires Flutter >=3.47.0 / Dart >=3.13.0. Run `tool/check_baseline.sh` and `tool/pub_get_all.sh` after cloning; CI runs both, plus `dart format --output=none --set-exit-if-changed packages examples`. See [Toolchain baseline](toolchain.md).

- Prefer conventions over configuration.
- Keep runtime work in `packages/velora` unless CLI or starter code is required.
- Follow the architecture in [`architecture.md`](architecture.md) — it is the canonical layering guide. (`velora.part2.md` is a superseded design deliberation, kept only for history.)
- Choose a home for state by scope: screen state → controller; shared records → an app- or feature-scoped in-memory service by default (reach for the reactive data layer, `velora_db`, only when they must persist, work offline, or survive restart); app-wide session state → a session service; feature-scoped business data → a plain injected service. See [Where shared state lives](architecture.md#where-shared-state-lives). Reach for `GetxService` when state is genuinely app-wide session state — not as the default home for every shared value.
- Velora builds on GetX; the framework's opinions (constructor injection for feature DI, plain classes for business services) are defaults with rationale, not bans on GetX idioms. See [Velora and GetX](architecture.md#velora-and-getx). Frame guidance the same way — the reason first, the rule second.
- Keep controllers small and UI-focused.
- Avoid broad docs or package splits unless requested.
- Docs ship with the code. A change to a public contract — a `velora_ui` export, a CLI command or flag, an installable package, a generated file, a documented constructor or enum, the architecture, a deprecation — updates the matching registry and page in the same PR. Run `tool/check_docs.sh --write`, commit the regenerated tables, and never hand-edit a `<!-- generated:… -->` block. The full mapping is in `AGENTS.md` under *Documentation is part of the change*.
