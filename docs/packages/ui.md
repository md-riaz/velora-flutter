# velora_ui

**What you'll do:** Install `velora_ui`, plug `VeloraTheme.light()`/`.dark()` into your `MaterialApp`, and read Velora's design tokens anywhere via `context.veloraTokens`.

---

## What it does

`velora_ui` is Velora's own, original design system — **token-first theming**, expressed the Flutter way. It's informed by (not copied from) the architecture surveyed in the internal `velora-ui-design-reference` planning note, but the palette, token taxonomy, and API are entirely Velora's: no external branding, no borrowed theme names.

This package ships two layers today — the **token + theme foundation** (Layer 1) and a **core component set** (Layer 2) built on top of it. What you get:

**Layer 1 — tokens & theme:**

- **`VeloraTokens`** — a [`ThemeExtension`](https://api.flutter.dev/flutter/material/ThemeExtension-class.html) carrying the design tokens that don't already live in Flutter's `ColorScheme`/`TextTheme`: spacing, radius, semantic colors (success/warning/info), elevation presets, and motion durations.
- **`VeloraThemePreset`** — a named Velora brand (a seed color + light/dark `VeloraTokens`), used to build a full Material 3 `ColorScheme` via `ColorScheme.fromSeed`.
- **`buildVeloraTheme(...)`** — builds a `ThemeData` (Material 3, `useMaterial3: true`) from a preset and a `Brightness`, with the matching `VeloraTokens` attached via `ThemeData.extensions`.
- **`VeloraTheme.light()` / `VeloraTheme.dark()`** — convenience helpers for the default preset, mirroring the `ClaudeTheme.light()`/`.dark()` shape already used in `examples/claude_clone`.
- **`context.veloraTokens`** — a `BuildContext` extension getter that reads the `VeloraTokens` off the current `Theme`.

**Layer 2 — components:** a focused set of presentational widgets (`VeloraButton`, `VeloraCard`, `VeloraBadge`, `VeloraChip`, `VeloraAlert`, `VeloraEmptyState`, `VeloraSkeleton`) that each read their colors, spacing, radius, and motion from the active theme — see [Components](#components) below.

`velora_ui` is **not** a [Velora plugin](../plugins.md) and doesn't wire into `Velora.boot(plugins: [...])` — it's just Flutter theming, applied via your app's `theme:`/`darkTheme:` arguments (or a `VeloraApp` wrapper, if your app uses one), exactly like any other `ThemeData`.

## Install

```yaml
dependencies:
  velora_ui:
    path: packages/velora_ui # or the pub.dev version once published
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

MaterialApp(
  theme: VeloraTheme.light(),
  darkTheme: VeloraTheme.dark(),
  themeMode: ThemeMode.system,
  home: const MyHomePage(),
);
```

Read tokens anywhere below that `MaterialApp`:

```dart
Widget build(BuildContext context) {
  final tokens = context.veloraTokens;

  return Container(
    padding: EdgeInsets.all(tokens.spacingMd),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      boxShadow: tokens.shadowSm,
    ),
    child: Text(
      'Saved',
      style: TextStyle(color: tokens.success),
    ),
  );
}
```

If you need a specific brand preset (or brightness) rather than the default, call `buildVeloraTheme(...)` directly:

```dart
buildVeloraTheme(brightness: Brightness.dark, preset: VeloraThemePreset.meadow);
```

## Token categories

`VeloraTokens` only carries what Material's `ColorScheme`/`TextTheme` don't already give you — everything else (primary/secondary/surface colors, the type scale) comes for free from `ColorScheme.fromSeed` in `buildVeloraTheme`.

| Category | Fields | Notes |
|---|---|---|
| Spacing | `spacingXs` … `spacingXxl` (4 / 8 / 16 / 24 / 32 / 48) | Logical pixels; use directly or via `EdgeInsets`. |
| Radius | `radiusSm` / `radiusMd` / `radiusLg` / `radiusPill` (4 / 8 / 16 / 999) | For `BorderRadius.circular(...)`; `radiusPill` always renders as a stadium shape. |
| Semantic colors | `success`/`onSuccess`, `warning`/`onWarning`, `info`/`onInfo` | The three states Material's `ColorScheme` doesn't define (it only has `error`/`onError`). Different values per `Brightness`. |
| Elevation | `elevation1` … `elevation4` (doubles) + `shadowSm`/`shadowMd` (`BoxShadow` presets) | For custom-painted surfaces that want a shadow without a full `Material`/`Card` widget. |
| Motion | `motionFast` / `motionNormal` / `motionSlow` (120ms / 220ms / 360ms) | `Duration`s for implicit/explicit animations, kept consistent app-wide. |

All fields are `final`; `copyWith(...)` overrides individual tokens, and `lerp(...)` interpolates between two token sets (used automatically by Flutter when animating between themes).

## The palette

Velora's name evokes "velvet" and "aurora" — the default preset leans into the latter.

- **`VeloraThemePreset.aurora`** (default) — seed `#5B4FE6`, a saturated indigo-violet. A twilight-sky hue that's confident and modern without echoing Flutter's default blue (`#2196F3`), Material 3's own demo seed (`#6750A4`), or any other product's brand color.
- **`VeloraThemePreset.meadow`** — seed `#1E8A6E`, a grounded teal-green, offered as a calmer, growth/productivity-flavored alternate identity.

Each seed expands into a full Material 3 tonal `ColorScheme` via `ColorScheme.fromSeed` — you don't hand-pick every surface color, just the one brand hue. Semantic colors (hand-picked, not derived from the seed) for the default token set:

| Token | Light | Dark |
|---|---|---|
| `success` / `onSuccess` | `#1E7D46` / `#FFFFFF` | `#6FDC9D` / `#063823` |
| `warning` / `onWarning` | `#8A5300` / `#FFFFFF` | `#FFC46B` / `#452B00` |
| `info` / `onInfo` | `#1A5FB4` / `#FFFFFF` | `#9CC8FF` / `#0B3564` |

## Components

Every Layer 2 widget is a pure presentational widget that reads its colors, spacing, radius, and motion from the active theme (`context.veloraTokens` + `ColorScheme`) — so it tracks light/dark and any token override automatically, and never hard-codes a hex value. They depend only on `flutter` (no Velora core needed), so you can drop them into any Flutter app that applies a Velora theme.

| Component | What it's for | Highlights |
|---|---|---|
| `VeloraButton` | The primary action control. | `variant` (primary/secondary/outline/ghost/danger), `size` (small/medium/large), built-in `loading` spinner (also swallows taps), optional `icon`, `fullWidth`. |
| `VeloraCard` | A padded, rounded surface for grouped content. | Token radius/padding/shadow; optional `onTap` (ripple clipped to the corners); `elevated` and `color` overrides. |
| `VeloraBadge` | A small status pill — a count or a state label. | `VeloraStatus`-driven color; `solid` or `soft` style; optional leading `icon`. |
| `VeloraChip` | An interactive filter/selection/tag chip. | `selected` state, `onTap` to toggle, `onDeleted` for a dismiss affordance, optional `icon`. |
| `VeloraAlert` | An inline semantic message banner. | `VeloraStatus` accent + default icon, optional `title`, optional `onClose` button (caller controls visibility). |
| `VeloraEmptyState` | A centered "nothing here yet" placeholder. | Muted `icon`, `title`, optional `message`, optional `action` (typically a `VeloraButton`). |
| `VeloraSkeleton` | A loading placeholder. | Gentle opacity pulse (`motionSlow`); auto-static under `MediaQuery.disableAnimations`; `.circle(...)` and `.text(...)` constructors. |

`VeloraStatus` (`success` / `warning` / `info` / `error`) is the shared enum behind the status-driven components; it resolves to concrete colors from `VeloraTokens` (success/warning/info) or the `ColorScheme` (error) via `status.colors(context)`.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const VeloraAlert(
      status: VeloraStatus.success,
      title: 'Saved',
      message: 'Your changes were saved.',
    ),
    SizedBox(height: context.veloraTokens.spacingMd),
    VeloraButton(
      label: 'Continue',
      icon: Icons.arrow_forward,
      loading: controller.isLoading.value,
      onPressed: controller.submit,
    ),
  ],
);
```

## What's next

This package will keep growing in layers:

- **Layer 1** — tokens + theme (`VeloraTokens`, `VeloraThemePreset`, `buildVeloraTheme`).
- **Layer 2** — the core component set above (buttons, cards, badges, chips, alerts, empty states, skeletons).
- **Layer 3 (next)** — form fields wired to `VeloraFormController` so validation/error state flows through the framework's existing form layer, plus more components (inputs, dialogs/sheets, list tiles, tabs, data tables).

---

**See also:** [Plugins →](../plugins.md) for how `velora_ui` differs from a `VeloraPlugin` package (it wires via `theme:`, not `Velora.boot(plugins:)`).
