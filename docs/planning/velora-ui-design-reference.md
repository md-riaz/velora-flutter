# Planning note: `velora_ui` design-system reference

> **Status:** planning / not implemented. This is a reference for a future
> `velora_ui` kit, captured so the direction isn't lost. Nothing here ships yet.

## Inspiration: Meta's Astryx

[Astryx](https://github.com/facebook/astryx) (`facebook/astryx`, MIT-licensed) is
an open-source design system for React + StyleX. Notable traits worth learning
from:

- **Token-first theming** — components are driven by design tokens, with several
  ready-made, customizable themes plus dark mode.
- **"Guidance over enforcement" / open internals** — components are composable at
  any level rather than locked behind top-level APIs; styles are overridable
  without vendor lock-in.
- **CLI tooling** — component scaffolding and docs generation.
- **No build plugin required** — pre-built styles + typed components.
- 150+ accessible components, ready-to-ship templates.

### Framing (important)

We **adapt the architecture and principles**, we do **not** clone it. Build an
**original** Flutter kit with Velora's own identity:

- Do **not** reuse the "Astryx" name, Meta branding, its theme names
  (butter/matcha/gothic/…), or copy proprietary visual assets.
- Astryx is MIT-licensed: if any code/docs are ever directly reused, include
  attribution. The intent here is an original Flutter implementation *informed
  by* Astryx's structure, not a port.
- StyleX/React specifics don't translate — take the *ideas*, express them the
  Flutter way.

## What to adapt, translated to Flutter / Velora

| Astryx idea | Velora / Flutter expression |
|---|---|
| Design tokens as source of truth | A `VeloraTokens` `ThemeExtension` (color, spacing, radius, typography, elevation, motion). Consumed via `Theme.of(context).extension<VeloraTokens>()`. `examples/claude_clone` already uses `ThemeExtension` (`claude_extensions.dart`) — generalize that pattern. |
| Several ready-made themes + dark mode | A small set of Velora-branded theme presets (original palettes/names) with light/dark variants, swappable at boot. Ties into the existing `VeloraApp` theme args + `ThemeService` persistence (already toggles/persists light/dark). |
| Guidance over enforcement / open internals | Components accept style overrides and expose composable sub-parts (builders/slots); never hard-lock layout. Default to Material 3 under the hood but allow overrides. |
| CLI scaffolding | Extend `velora_cli`: e.g. `velora make:ui <component>` or ship the kit as `velora install velora_ui` (it's a `VeloraPlugin`-free widget package — no boot wiring, just widgets + the token `ThemeExtension`). |
| Ready-to-ship templates | Our `examples/` apps already play this role (claude_clone, velora_chat, …). |

## Proposed shape

- New package `packages/velora_ui` (installable via `velora install velora_ui`).
- Layer 1 — **tokens/theme**: `VeloraTokens` `ThemeExtension` + a few theme
  presets + a helper to build `ThemeData` from tokens.
- Layer 2 — **components** (start core, grow later): Button, TextField/Input,
  Card, Dialog/BottomSheet, Chip/Badge, ListTile, Avatar, Banner/Alert,
  Skeleton/Loading, EmptyState, Tabs, DataTable. Reuse existing Velora pieces
  where they exist (toast/loader already in core).
- Layer 3 — **form fields** wired to `VeloraFormController` so validation/error
  state flows through the framework's existing form layer.

## Open decisions (resolve when we start)

- Build on Material 3 widgets vs. custom-painted primitives (lean Material 3 for
  MVP; tokens still central).
- Token taxonomy + naming (align with Flutter `ColorScheme`/`TextTheme` where
  sensible so it composes with stock widgets).
- How many theme presets to ship, and their (original) names.
- Whether components stay render-agnostic or assume Material.

## Related

- Tracked as a future item in the example/kit roadmap (after the example suite:
  velora_chat → velora_db cached-repo demo → …).
- Existing theming reference in-repo: `examples/claude_clone/lib/resources/theme/`.
