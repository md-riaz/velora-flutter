import 'package:flutter/material.dart';

/// Velora's type scale — the single biggest signal that a Velora app is *not*
/// a stock-Material app.
///
/// Material's default [TextTheme] (Roboto, even weights, loose tracking) is
/// what makes untuned Flutter apps look identical. Velora replaces it with a
/// deliberately tuned scale: **tight tracking and heavier weights on
/// headings** (the modern "display" look), **generous line-height on body
/// copy** for readability, and **semi-bold, positively-tracked labels** so
/// buttons and chips read as intentional UI rather than default text.
///
/// The scale is font-agnostic — it sets only size/weight/letter-spacing/
/// height, so it works on the platform default face and instantly adopts a
/// brand font when one is supplied via [fontFamily]. Colors are *not* set
/// here; [buildVeloraTheme] applies `ColorScheme`-driven colors so the scale
/// tracks light/dark automatically.
TextTheme veloraTextTheme({String? fontFamily}) {
  TextStyle s(double size, FontWeight weight, double tracking, double height) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: tracking,
      height: height,
    );
  }

  // Weights used across the scale. Headlines lean bold; labels lean
  // semi-bold; body stays regular.
  const bold = FontWeight.w700;
  const semi = FontWeight.w600;
  const regular = FontWeight.w400;

  return TextTheme(
    // Display — big marketing/hero type. Tight negative tracking is the
    // hallmark of a considered display face.
    displayLarge: s(57, bold, -1.0, 1.12),
    displayMedium: s(45, bold, -0.5, 1.16),
    displaySmall: s(36, bold, -0.25, 1.22),

    // Headlines — section and screen titles.
    headlineLarge: s(32, bold, -0.5, 1.25),
    headlineMedium: s(28, bold, -0.4, 1.29),
    headlineSmall: s(24, bold, -0.25, 1.33),

    // Titles — card headers, list headers, app-bar title.
    titleLarge: s(22, bold, -0.2, 1.27),
    titleMedium: s(16, semi, 0.0, 1.5),
    titleSmall: s(14, semi, 0.1, 1.43),

    // Body — the reading sizes, with roomy line-height.
    bodyLarge: s(16, regular, 0.15, 1.5),
    bodyMedium: s(14, regular, 0.2, 1.5),
    bodySmall: s(12, regular, 0.2, 1.4),

    // Labels — buttons, chips, tabs. Semi-bold + positive tracking so they
    // read as UI, not prose.
    labelLarge: s(14, semi, 0.3, 1.2),
    labelMedium: s(12, semi, 0.4, 1.2),
    labelSmall: s(11, semi, 0.5, 1.2),
  );
}
