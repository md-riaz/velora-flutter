/// Velora UI — an original, token-first design system for Velora apps.
///
/// This is **Layer 1**: the token + theme foundation. It provides
/// [VeloraTokens] (a [ThemeExtension](https://api.flutter.dev/flutter/material/ThemeExtension-class.html)
/// carrying spacing/radius/semantic-color/elevation/motion tokens),
/// original Velora theme presets, and [buildVeloraTheme]/[VeloraTheme] to
/// build a Material 3 `ThemeData` that carries them. Components (buttons,
/// inputs, cards, ...) are a future layer — not part of this package yet.
library;

export 'src/theme/velora_theme.dart';
export 'src/theme/velora_tokens_context.dart';
export 'src/tokens/velora_tokens.dart';
