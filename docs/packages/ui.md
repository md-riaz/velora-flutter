# velora_ui

**What you'll do:** Install `velora_ui`, plug `VeloraTheme.light()`/`.dark()` into your `MaterialApp`, and read Velora's design tokens anywhere via `context.veloraTokens`.

---

## What it does

`velora_ui` is Velora's own, original design system — **token-first theming**, expressed the Flutter way. It's informed by (not copied from) the architecture surveyed in the internal `velora-ui-design-reference` planning note, but the palette, token taxonomy, and API are entirely Velora's: no external branding, no borrowed theme names.

The package ships six layers, all exported from `package:velora_ui/velora_ui.dart`:

<!-- generated:ui-layers source=packages/velora_ui/components.json — do not edit; run tool/check_docs.sh --write -->
| Layer | Focus | Exports |
|---|---|---|
| 1 | Tokens & theme | `VeloraTokens`, `VeloraThemePreset`, `buildVeloraTheme`, `VeloraTheme`, `veloraTextTheme`, `VeloraTokensContext` |
| 2 | Core components | `VeloraButton`, `VeloraButtonVariant`, `VeloraButtonSize`, `VeloraCard`, `VeloraBadge`, `VeloraBadgeStyle`, `VeloraChip`, `VeloraAlert`, `VeloraEmptyState`, `VeloraSkeleton`, `VeloraStatus`, `VeloraStatusColors`, `VeloraStatusResolver` |
| 3 | Form inputs | `VeloraTextField`, `VeloraSelect`, `VeloraSelectOption`, `VeloraCheckbox`, `VeloraSwitch`, `VeloraRadioGroup`, `VeloraRadioOption` |
| 4 | Layout & content display | `VeloraAvatar`, `VeloraListTile`, `VeloraSectionHeader`, `VeloraDivider`, `VeloraProgress` |
| 5 | Navigation & scaffolding | `VeloraNavDestination`, `VeloraNavBar`, `VeloraNavRail`, `VeloraTabs`, `VeloraScaffold` |
| 6 | Feedback & overlays | `VeloraDialog`, `VeloraBottomSheet`, `VeloraToast`, `VeloraTooltip` |
<!-- /generated:ui-layers -->

Every component reads its colors, spacing, radius, and motion from the active theme, and depends only on `flutter`. What you get:

**Layer 1 — tokens & theme:**

- **`VeloraTokens`** — a [`ThemeExtension`](https://api.flutter.dev/flutter/material/ThemeExtension-class.html) carrying the design tokens that don't already live in Flutter's `ColorScheme`/`TextTheme`: spacing, radius, semantic colors (success/warning/info), elevation presets, and motion durations.
- **`VeloraThemePreset`** — a named Velora brand (a seed color + light/dark `VeloraTokens`), used to build a full Material 3 `ColorScheme` via `ColorScheme.fromSeed`.
- **`buildVeloraTheme(...)`** — builds a `ThemeData` (Material 3, `useMaterial3: true`) from a preset and a `Brightness`, with the matching `VeloraTokens` attached via `ThemeData.extensions`.
- **`VeloraTheme.light()` / `VeloraTheme.dark()`** — convenience helpers for the default preset, mirroring the `ClaudeTheme.light()`/`.dark()` shape already used in `examples/claude_clone`.
- **`context.veloraTokens`** — a `BuildContext` extension getter (`VeloraTokensContext`) that reads the `VeloraTokens` off the current `Theme`.
- **`veloraTextTheme(...)`** — the type scale `buildVeloraTheme` applies; call it directly to build a `TextTheme` with your own `fontFamily`.

**Layer 2 — components:** a focused set of presentational widgets (`VeloraButton`, `VeloraCard`, `VeloraBadge`, `VeloraChip`, `VeloraAlert`, `VeloraEmptyState`, `VeloraSkeleton`) that each read their colors, spacing, radius, and motion from the active theme — see [Components](#components) below.

**Layer 3 — form inputs:** controlled input widgets (`VeloraTextField`, `VeloraSelect`, `VeloraCheckbox`, `VeloraSwitch`, `VeloraRadioGroup`) with a `value` + `onChanged` + `errorText` API that binds to any controller — including a `VeloraFormController` field — see [Form inputs](#form-inputs) below.

**Layer 4 — layout & content display:** `VeloraAvatar`, `VeloraListTile`, `VeloraSectionHeader`, `VeloraDivider`, `VeloraProgress` — see [Layout and content display](#layout-and-content-display).

**Layer 5 — navigation & scaffolding:** `VeloraNavBar`, `VeloraNavRail`, `VeloraTabs`, `VeloraScaffold`, sharing the `VeloraNavDestination` model — see [Navigation and scaffolding](#navigation-and-scaffolding).

**Layer 6 — feedback & overlays:** `VeloraDialog`, `VeloraBottomSheet`, `VeloraToast`, `VeloraTooltip` — see [Feedback and overlays](#feedback-and-overlays).

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

`VeloraStatus` (`success` / `warning` / `info` / `error`) is the shared enum behind the status-driven components; it resolves to a `VeloraStatusColors` from `VeloraTokens` (success/warning/info) or the `ColorScheme` (error) via `status.colors(context)` (the `VeloraStatusResolver` extension). The button and badge options are the `VeloraButtonVariant`, `VeloraButtonSize`, and `VeloraBadgeStyle` enums.

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
    // Wrap the reactive read in Obx so the button rebuilds when the flag
    // changes (reading `.value` outside Obx never re-subscribes).
    Obx(
      () => VeloraButton(
        label: 'Continue',
        icon: Icons.arrow_forward,
        loading: controller.isLoading.value,
        onPressed: controller.submit,
      ),
    ),
  ],
);
```

## Form inputs

Layer 3 adds the controlled form inputs. Each is **presentational and
framework-agnostic** (depends only on `flutter`) but exposes the exact shape a
form controller wants: a current `value`, an `onChanged` callback, and a
nullable `errorText`. Because `VeloraFormController` (in `package:velora`)
exposes per-field values and errors, wiring a field to the framework's form
layer is just passing those through — no coupling in either direction.

| Input | Notes |
|---|---|
| `VeloraTextField` | Single/multi-line text. `label`/`hint`/`helperText`/`errorText`, `prefixIcon`/`suffixIcon`, a built-in show/hide toggle when `obscureText` is true, plus the usual `keyboardType`/`maxLines`/`inputFormatters`. Manages its own `TextEditingController` if you don't pass one. |
| `VeloraSelect<T>` | A dropdown over `VeloraSelectOption<T>`s, matching `VeloraTextField`'s decoration and error styling. |
| `VeloraCheckbox` | A labeled, full-row-tappable checkbox with optional `subtitle` and `errorText`. |
| `VeloraSwitch` | A settings-style labeled switch row. |
| `VeloraRadioGroup<T>` | A vertical single-select group of `VeloraRadioOption<T>`s with an optional group `label` and `errorText`. |

Sketch of binding a text field to a `VeloraFormController`, whose `firstError(field)` returns the first validation message for a field (or null when valid):

```dart
class SignUpController extends VeloraFormController {
  final email = TextEditingController();
  // ...submit() calls setErrors(...) from the server's 422 response.
}

// In the view:
Obx(
  () => VeloraTextField(
    label: 'Email',
    controller: c.email,
    keyboardType: TextInputType.emailAddress,
    errorText: c.firstError('email'), // reactive; null when valid
  ),
);
```

The inputs never reach into the framework themselves — you decide how `value`/
`onChanged`/`errorText` map to your controller, so the same widgets work with a
plain `setState`, a GetX controller, or `VeloraFormController`.

## Layout and content display

Layer 4 arranges other widgets rather than collecting input.

| Component | What it's for | Parameters |
|---|---|---|
| `VeloraAvatar` | A circular photo, initials, or icon avatar. | `image`, `name` (initials fallback), `size`, `backgroundColor`, `foregroundColor`. |
| `VeloraListTile` | A token-styled row. | `leading`, `title`, `subtitle`, `trailing`, `onTap`. |
| `VeloraSectionHeader` | A titled header for a content section. | `title`, `subtitle`, `action` (trailing widget). |
| `VeloraDivider` | A thin themed separator. | `vertical`, `indent`, `endIndent`, `color`. |
| `VeloraProgress` | A progress indicator. | `VeloraProgress.linear(value:)` and `VeloraProgress.circular(value:, size:)`; a null `value` is indeterminate. |

## Navigation and scaffolding

Layer 5 is controlled, like the form inputs: the caller owns the selected index and passes it back in. The widgets hold no navigation state and know nothing about routes.

| Component | What it's for | Parameters |
|---|---|---|
| `VeloraNavDestination` | Immutable icon + label model shared by the bar and rail. | `icon`, `selectedIcon`, `label`. |
| `VeloraNavBar` | Bottom navigation for compact layouts. | `destinations`, `selectedIndex`, `onDestinationSelected`. |
| `VeloraNavRail` | Side navigation for wide layouts. | Same three, plus `leading` and `trailing`. |
| `VeloraTabs` | A pill segmented control for switching views within a screen. | `tabs`, `selectedIndex`, `onChanged`. |
| `VeloraScaffold` | A thin `Scaffold` wrapper. | `title`, `actions`, `leading`, `body`, `bottomNavigationBar`, `floatingActionButton`. |

```dart
VeloraScaffold(
  title: 'Inbox',
  body: pages[index],
  bottomNavigationBar: VeloraNavBar(
    destinations: const [
      VeloraNavDestination(icon: Icons.inbox_outlined, label: 'Inbox'),
      VeloraNavDestination(icon: Icons.settings_outlined, label: 'Settings'),
    ],
    selectedIndex: index,
    onDestinationSelected: (i) => setState(() => index = i),
  ),
);
```

## Feedback and overlays

Layer 6 covers what interrupts or floats above the current screen. The chrome comes from `buildVeloraTheme`'s `dialogTheme`, `snackBarTheme`, `tooltipTheme`, and `bottomSheetTheme`, so apply a Velora theme for these to look right.

| Component | What it's for | API |
|---|---|---|
| `VeloraDialog` | A token-styled modal. | Widget with `title`, `message`, `content`, `actions`, `icon`, `status`; `VeloraDialog.show(context, ...)`; `VeloraDialog.confirm(context, ...)` with `confirmLabel`, `cancelLabel`, `destructive`. |
| `VeloraBottomSheet` | A modal bottom sheet. | `VeloraBottomSheet.show(context, builder:, title:, showDragHandle:, isScrollControlled:, isDismissible:)`. |
| `VeloraToast` | Transient `ScaffoldMessenger` feedback. | `VeloraToast.show(context, ...)` with an optional `VeloraStatus` icon and action. |
| `VeloraTooltip` | A themed wrapper around Material's `Tooltip`. | `message`, `child`. |

`VeloraToast` needs a `ScaffoldMessenger` above it and a `BuildContext`. `Velora.toast` in `package:velora` is the separate, context-free facade for controllers; `velora_ui` does not depend on it.

## Not included

No data table, stepper/wizard, or adaptive app shell ships yet. There is also no dedicated `VeloraFormController` binding helper; wire fields by hand as shown under [Form inputs](#form-inputs).

---

**See also:** [Plugins →](../plugins.md) for how `velora_ui` differs from a `VeloraPlugin` package (it wires via `theme:`, not `Velora.boot(plugins:)`).
