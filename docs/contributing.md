# Contributing Notes

Keep Velora changes focused on MVP productivity.

- Prefer conventions over configuration.
- Keep runtime work in `packages/velora` unless CLI or starter code is required.
- Follow the architecture in [`architecture.md`](architecture.md) — it is the canonical layering guide. (`velora.part2.md` is a superseded design deliberation, kept only for history.)
- Choose a home for state by scope: screen state → controller; shared records → the reactive data layer (`velora_db`); app-wide session state → a session service; feature-scoped business data → a plain injected service. See [Where shared state lives](architecture.md#where-shared-state-lives). Don't reflexively put everything in a `GetxService`.
- Keep controllers small and UI-focused.
- Avoid broad docs or package splits unless requested.
