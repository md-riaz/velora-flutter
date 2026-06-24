import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'claude_colors.dart';
import 'claude_extensions.dart';

/// Claude brand theme built on top of [VeloraTheme.fromScheme].
///
/// Rather than using [ColorScheme.fromSeed] (which tints every surface from
/// one seed), we supply a fully hand-crafted [ColorScheme] so the warm
/// surfaces, outline tones, and surface hierarchy exactly match Claude's
/// product identity.  The [ClaudeTokens] extension adds chat-specific
/// tokens (bubbles, input bar, code blocks) that live outside Material's
/// standard palette.
class ClaudeTheme {
  static ThemeData light() {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: ClaudeColors.primary,
      onPrimary: ClaudeColors.onPrimary,
      primaryContainer: Color(0xFFF5D9C5),
      onPrimaryContainer: Color(0xFF4A1900),
      secondary: Color(0xFF886557),
      onSecondary: ClaudeColors.onPrimary,
      secondaryContainer: Color(0xFFEED5C9),
      onSecondaryContainer: Color(0xFF351D14),
      tertiary: Color(0xFF4A7C8E),
      onTertiary: ClaudeColors.onPrimary,
      tertiaryContainer: Color(0xFFCAE7F4),
      onTertiaryContainer: Color(0xFF002733),
      error: Color(0xFFBA1A1A),
      onError: ClaudeColors.onPrimary,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: ClaudeColors.surfaceLight,
      onSurface: Color(0xFF1C1B19),
      surfaceContainerHighest: ClaudeColors.surfaceContainerHighLight,
      surfaceContainerHigh: ClaudeColors.surfaceContainerLight,
      surfaceContainer: Color(0xFFF8F6F1),
      surfaceContainerLow: ClaudeColors.bgLight,
      surfaceContainerLowest: ClaudeColors.bgLight,
      onSurfaceVariant: Color(0xFF52504A),
      outline: ClaudeColors.outlineLight,
      outlineVariant: Color(0xFFD4CFC6),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF313029),
      onInverseSurface: Color(0xFFF3F0E8),
      inversePrimary: ClaudeColors.primaryLight,
    );

    return VeloraTheme.fromScheme(
      colorScheme: scheme,
      cardBorderRadius: 16,
      inputBorderRadius: 12,
      buttonBorderRadius: 10,
      extensions: [ClaudeTokens.light],
    );
  }

  static ThemeData dark() {
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: ClaudeColors.primaryLight,
      onPrimary: ClaudeColors.onPrimaryDark,
      primaryContainer: ClaudeColors.primaryDark,
      onPrimaryContainer: Color(0xFFFFDBCC),
      secondary: Color(0xFFD4B9AC),
      onSecondary: Color(0xFF4E2E22),
      secondaryContainer: Color(0xFF694437),
      onSecondaryContainer: Color(0xFFEED5C9),
      tertiary: Color(0xFF8BCDE0),
      onTertiary: Color(0xFF003543),
      tertiaryContainer: Color(0xFF1F5D6F),
      onTertiaryContainer: Color(0xFFCAE7F4),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: ClaudeColors.surfaceDark,
      onSurface: Color(0xFFE8E4DC),
      surfaceContainerHighest: ClaudeColors.surfaceContainerHighDark,
      surfaceContainerHigh: ClaudeColors.surfaceContainerDark,
      surfaceContainer: Color(0xFF27261F),
      surfaceContainerLow: Color(0xFF1F1E1C),
      surfaceContainerLowest: ClaudeColors.bgDark,
      onSurfaceVariant: Color(0xFFCDC8BF),
      outline: ClaudeColors.outlineDark,
      outlineVariant: Color(0xFF4A4740),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE8E4DC),
      onInverseSurface: Color(0xFF313029),
      inversePrimary: ClaudeColors.primary,
    );

    return VeloraTheme.fromScheme(
      colorScheme: scheme,
      cardBorderRadius: 16,
      inputBorderRadius: 12,
      buttonBorderRadius: 10,
      extensions: [ClaudeTokens.dark],
    );
  }
}
