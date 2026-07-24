/// Velora UI — an original, token-first design system for Velora apps.
///
/// **Layer 1** is the token + theme foundation: [VeloraTokens] (a
/// [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html)
/// carrying spacing/radius/semantic-color/elevation/motion tokens), original
/// Velora theme presets, and [buildVeloraTheme]/[VeloraTheme] to build a
/// Material 3 `ThemeData` that carries them.
///
/// **Layer 2** is the core component set built on those tokens — every widget
/// reads its colors, spacing, radius, and motion from the active theme
/// (`context.veloraTokens` + `ColorScheme`), so the kit stays visually
/// consistent and tracks light/dark automatically:
///
/// - [VeloraButton] — variants (primary/secondary/outline/ghost/danger),
///   sizes, a built-in loading state, and optional icon.
/// - [VeloraCard] — a padded, rounded, optionally tappable surface.
/// - [VeloraBadge] — a small status pill (solid or soft) driven by
///   [VeloraStatus].
/// - [VeloraChip] — an interactive, selectable/removable chip.
/// - [VeloraAlert] — a semantic message banner (success/warning/info/error).
/// - [VeloraEmptyState] — a centered "nothing here yet" placeholder.
/// - [VeloraSkeleton] — a pulsing loading placeholder.
///
/// **Layer 3** adds the form inputs — all controlled (value + `onChanged` +
/// `errorText`), so they bind cleanly to any controller, including a
/// `VeloraFormController` field:
///
/// - [VeloraTextField] — single/multi-line text input with a built-in
///   obscure-text toggle.
/// - [VeloraSelect] — a dropdown/select field.
/// - [VeloraCheckbox] / [VeloraSwitch] — labeled boolean rows.
/// - [VeloraRadioGroup] — a single-select group of options.
library;

export 'src/components/velora_alert.dart';
export 'src/components/velora_badge.dart';
export 'src/components/velora_button.dart';
export 'src/components/velora_card.dart';
export 'src/components/velora_checkbox.dart';
export 'src/components/velora_chip.dart';
export 'src/components/velora_empty_state.dart';
export 'src/components/velora_radio_group.dart';
export 'src/components/velora_select.dart';
export 'src/components/velora_skeleton.dart';
export 'src/components/velora_status.dart';
export 'src/components/velora_switch.dart';
export 'src/components/velora_text_field.dart';
export 'src/theme/velora_theme.dart';
export 'src/theme/velora_tokens_context.dart';
export 'src/tokens/velora_tokens.dart';
