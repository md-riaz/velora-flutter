# Contributing Notes

Keep Velora changes focused on MVP productivity.

- Prefer conventions over configuration.
- Keep runtime work in `packages/velora` unless CLI or starter code is required.
- Follow the architecture in [`architecture.md`](architecture.md) — it is the canonical layering guide. (`velora.part2.md` is a superseded design deliberation, kept only for history.)
- Choose a home for state by scope: screen state → controller; shared records → an app- or feature-scoped in-memory service by default (reach for the reactive data layer, `velora_db`, only when they must persist, work offline, or survive restart); app-wide session state → a session service; feature-scoped business data → a plain injected service. See [Where shared state lives](architecture.md#where-shared-state-lives). Reach for `GetxService` when state is genuinely app-wide session state — not as the default home for every shared value.
- Velora builds on GetX; the framework's opinions (constructor injection for feature DI, plain classes for business services) are defaults with rationale, not bans on GetX idioms. See [Velora and GetX](architecture.md#velora-and-getx). Frame guidance the same way — the reason first, the rule second.
- Keep controllers small and UI-focused.
- Avoid broad docs or package splits unless requested.
