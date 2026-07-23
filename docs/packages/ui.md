# velora_ui

**What you'll do:** Install `velora_ui`, plug `VeloraTheme.light()`/`.dark()` into your `MaterialApp`, and read Velora's design tokens anywhere via `context.veloraTokens`.

---

## What it does

`velora_ui` is Velora's own, original design system — **token-first theming**, expressed the Flutter way. It's informed by (not copied from) the architecture surveyed in the internal `velora-ui-design-reference` planning note, but the palette, token taxonomy, and API are entirely Velora's: no external branding, no borrowed theme names.

This package ships **Layer 1 only: the token + theme foundation**. There are no buttons, cards, or inputs yet — that's a follow-up layer built on top of this one. What you get today:

- **`VeloraTokens`** — a [`ThemeExtension`](https://api.flutter.dev/flutter/material/ThemeExtension-class.html) carrying the design tokens that don't already live in Flutter's `ColorScheme`/`TextTheme`: spacing, radius, semantic colors (success/warning/info), elevation presets, and motion durations.
- **`VeloraThemePreset`** — a named Velora brand (a seed color + light/dark `VeloraTokens`), used to build a full Material 3 `ColorScheme` via `ColorScheme.fromSeed`.
- **`buildVeloraTheme(...)`** — builds a `ThemeData` (Material 3, `useMaterial3: true`) from a preset and a `Brightness`, with the matching `VeloraTokens` attached via `ThemeData.extensions`.
- **`VeloraTheme.light()` / `VeloraTheme.dark()`** — convenience helpers for the default preset, mirroring the `ClaudeTheme.light()`/`.dark()` shape already used in `examples/claude_clone`.
- **`context.veloraTokens`** — a `BuildContext` extension getter that reads the `VeloraTokens` off the current `Theme`.

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

## What's next

This package will grow in layers:

- **Layer 1 (this release)** — tokens + theme (`VeloraTokens`, `VeloraThemePreset`, `buildVeloraTheme`).
- **Layer 2** — components built on Material 3 widgets and Velora's tokens (buttons, inputs, cards, dialogs, chips, list tiles, banners, skeleton/loading states, empty states).
- **Layer 3** — form fields wired to `VeloraFormController` so validation/error state flows through the framework's existing form layer.

---

**See also:** [Plugins →](../plugins.md) for how `velora_ui` differs from a `VeloraPlugin` package (it wires via `theme:`, not `Velora.boot(plugins:)`).
