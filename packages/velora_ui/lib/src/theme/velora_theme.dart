import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';

/// A named, original Velora brand: a seed [Color] fed to
/// [ColorScheme.fromSeed] to generate the full Material 3 [ColorScheme],
/// paired with the [VeloraTokens] to use for each [Brightness].
///
/// Presets are original Velora palettes — not copies of Flutter's default
/// blue, Material's demo seed, or any other product's brand color. See the
/// dartdoc on [VeloraThemePreset.aurora] and [VeloraThemePreset.meadow] for
/// the reasoning behind each hue.
@immutable
class VeloraThemePreset {
  /// A short, human-readable name for this preset (used in docs/UI, not
  /// persisted anywhere by this package).
  final String name;

  /// The brand seed color passed to [ColorScheme.fromSeed]. Material 3
  /// derives the entire tonal palette — primary/secondary/tertiary,
  /// surfaces, outlines — from this single color per [Brightness].
  final Color seed;

  /// The [VeloraTokens] to attach for [Brightness.light].
  final VeloraTokens lightTokens;

  /// The [VeloraTokens] to attach for [Brightness.dark].
  final VeloraTokens darkTokens;

  /// Creates a theme preset. Prefer the ready-made [aurora]/[meadow]
  /// constants unless you need a fully custom brand color.
  const VeloraThemePreset({
    required this.name,
    required this.seed,
    this.lightTokens = VeloraTokens.light,
    this.darkTokens = VeloraTokens.dark,
  });

  /// Returns [lightTokens] or [darkTokens] for the given [brightness].
  VeloraTokens tokensFor(Brightness brightness) {
    return brightness == Brightness.dark ? darkTokens : lightTokens;
  }

  /// **Velora's default brand preset — "Aurora".**
  ///
  /// Seed: `#5B4FE6`, a saturated indigo-violet. Velora's name evokes
  /// "velvet" and "aurora" — this is the aurora half: a twilight-sky violet
  /// that reads as confident and modern without borrowing from Flutter's
  /// default blue (`#2196F3`), Material 3's own demo seed (`#6750A4`), or
  /// any other product's brand hue. `ColorScheme.fromSeed` expands it into
  /// a full Material 3 tonal palette for both [Brightness]es.
  static const aurora = VeloraThemePreset(
    name: 'Velora Aurora',
    seed: Color(0xFF5B4FE6),
  );

  /// **Velora's secondary brand preset — "Meadow".**
  ///
  /// Seed: `#1E8A6E`, a grounded teal-green. Offered as an alternate,
  /// calmer identity for apps that want a growth/productivity feel instead
  /// of Aurora's violet. Same [VeloraTokens] defaults — only the seed
  /// (and therefore the generated [ColorScheme]) differs.
  static const meadow = VeloraThemePreset(
    name: 'Velora Meadow',
    seed: Color(0xFF1E8A6E),
  );
}

/// Builds a Material 3 [ThemeData] carrying Velora's design tokens.
///
/// The [ColorScheme] is generated from [preset]'s seed color via
/// [ColorScheme.fromSeed] (Material 3's recommended approach — one brand
/// color in, a full accessible tonal palette out); [VeloraTokens] then rides
/// alongside it in [ThemeData.extensions] for everything the scheme doesn't
/// cover (spacing, radius, success/warning/info, elevation, motion).
///
/// ```dart
/// MaterialApp(
///   theme: buildVeloraTheme(),
///   darkTheme: buildVeloraTheme(brightness: Brightness.dark),
/// );
/// ```
ThemeData buildVeloraTheme({
  Brightness brightness = Brightness.light,
  VeloraThemePreset preset = VeloraThemePreset.aurora,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: preset.seed,
    brightness: brightness,
  );
  final tokens = preset.tokensFor(brightness);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    extensions: <ThemeExtension<dynamic>>[tokens],
  );
}

/// Convenience static helpers for Velora's default theme (the [aurora]
/// preset), mirroring the `ClaudeTheme.light()`/`.dark()` shape used by
/// `examples/claude_clone` — the common case of "just give me light and
/// dark `ThemeData`" without touching [buildVeloraTheme] or
/// [VeloraThemePreset] directly.
///
/// ```dart
/// MaterialApp(
///   theme: VeloraTheme.light(),
///   darkTheme: VeloraTheme.dark(),
/// );
/// ```
abstract final class VeloraTheme {
  /// The default Velora light theme ([VeloraThemePreset.aurora]).
  static ThemeData light() => buildVeloraTheme(brightness: Brightness.light);

  /// The default Velora dark theme ([VeloraThemePreset.aurora]).
  static ThemeData dark() => buildVeloraTheme(brightness: Brightness.dark);
}
