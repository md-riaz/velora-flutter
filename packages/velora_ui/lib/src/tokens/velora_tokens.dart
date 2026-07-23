import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Velora's design tokens, expressed as a Flutter [ThemeExtension].
///
/// [ColorScheme] and [TextTheme] already cover most of what a Material 3
/// theme needs (primary/secondary/surface colors, type scale, ...) — those
/// are generated from a brand seed color by [ColorScheme.fromSeed] and don't
/// need to be duplicated here. [VeloraTokens] carries everything Velora's
/// design system needs *in addition* to that: spacing, radius, a few
/// semantic colors Material's scheme doesn't define (success/warning/info),
/// elevation presets, and motion durations.
///
/// Attach a token set to a [ThemeData] via its `extensions:` list (see
/// `buildVeloraTheme` in `velora_theme.dart`), then read it back anywhere
/// below that `Theme` with `Theme.of(context).extension<VeloraTokens>()!` —
/// or, more conveniently, via the `context.veloraTokens` extension getter.
///
/// All fields are `final` and every token set here is `const`, so the
/// default token sets ([VeloraTokens.light] / [VeloraTokens.dark]) can be
/// used directly as compile-time constants.
@immutable
class VeloraTokens extends ThemeExtension<VeloraTokens> {
  // ---------------------------------------------------------------------
  // Spacing — a linear-ish scale for padding/gaps. Values are logical
  // pixels, meant to be used directly (`SizedBox(height: tokens.spacingMd)`)
  // or via `EdgeInsets.all(tokens.spacingMd)`.
  // ---------------------------------------------------------------------

  /// Extra-small spacing (4px by default) — tight gaps between closely
  /// related inline elements (e.g. an icon and its label).
  final double spacingXs;

  /// Small spacing (8px by default) — the default gap inside compact
  /// widgets (chip content padding, list tile leading/title gap).
  final double spacingSm;

  /// Medium spacing (16px by default) — the default outer padding for
  /// most content containers (cards, page padding, form fields).
  final double spacingMd;

  /// Large spacing (24px by default) — separation between distinct
  /// sections on the same screen.
  final double spacingLg;

  /// Extra-large spacing (32px by default) — separation between major
  /// page regions.
  final double spacingXl;

  /// Extra-extra-large spacing (48px by default) — page-level top/bottom
  /// breathing room, empty-state layouts.
  final double spacingXxl;

  // ---------------------------------------------------------------------
  // Radius — corner rounding scale, in logical pixels, for
  // `BorderRadius.circular(...)`.
  // ---------------------------------------------------------------------

  /// Small radius (4px by default) — chips, small buttons, tags.
  final double radiusSm;

  /// Medium radius (8px by default) — the default for inputs and
  /// secondary surfaces.
  final double radiusMd;

  /// Large radius (16px by default) — cards, sheets, dialogs.
  final double radiusLg;

  /// "Pill" / fully-rounded radius (999px by default) — large enough that
  /// it always renders as a stadium/pill shape regardless of the widget's
  /// height (buttons, badges, search fields).
  final double radiusPill;

  // ---------------------------------------------------------------------
  // Semantic colors — outside Material's [ColorScheme] (which only has
  // `error`/`onError`), Velora also needs success/warning/info pairs for
  // banners, snackbars, form validation, and status badges.
  // ---------------------------------------------------------------------

  /// Color denoting a successful/positive state.
  final Color success;

  /// Color for content/icons drawn on top of [success].
  final Color onSuccess;

  /// Color denoting a cautionary state that isn't yet an error.
  final Color warning;

  /// Color for content/icons drawn on top of [warning].
  final Color onWarning;

  /// Color denoting a neutral, informational state.
  final Color info;

  /// Color for content/icons drawn on top of [info].
  final Color onInfo;

  // ---------------------------------------------------------------------
  // Elevation — a small set of shadow-blur presets, expressed both as raw
  // `double` steps (for APIs that just want a magnitude) and as ready-made
  // [BoxShadow] lists (for `Container(decoration: BoxDecoration(boxShadow:
  // ...))`-style usage).
  // ---------------------------------------------------------------------

  /// Elevation step 1 — subtle lift (e.g. a resting card).
  final double elevation1;

  /// Elevation step 2 — a raised surface (e.g. a hovered/pressed card, an
  /// app bar with content scrolled beneath it).
  final double elevation2;

  /// Elevation step 3 — an overlay surface (e.g. a menu, a tooltip).
  final double elevation3;

  /// Elevation step 4 — a modal surface (e.g. a dialog, a bottom sheet).
  final double elevation4;

  /// Ready-made shadow for [elevation1]/[elevation2]-level surfaces.
  final List<BoxShadow> shadowSm;

  /// Ready-made shadow for [elevation3]/[elevation4]-level surfaces.
  final List<BoxShadow> shadowMd;

  // ---------------------------------------------------------------------
  // Motion — durations for implicit/explicit animations, so timing stays
  // consistent across the whole app instead of being hand-picked per widget.
  // ---------------------------------------------------------------------

  /// Fast motion (120ms by default) — micro-interactions (ripples, icon
  /// toggles, small state flips).
  final Duration motionFast;

  /// Normal motion (220ms by default) — the default for most transitions
  /// (page elements fading/sliding in, expanding a panel).
  final Duration motionNormal;

  /// Slow motion (360ms by default) — larger, more deliberate transitions
  /// (route transitions, full-screen reveals).
  final Duration motionSlow;

  /// Creates a token set. All fields are required — use [light] or [dark]
  /// for Velora's default values, then [copyWith] to override individual
  /// tokens.
  const VeloraTokens({
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.spacingXxl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusPill,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.elevation1,
    required this.elevation2,
    required this.elevation3,
    required this.elevation4,
    required this.shadowSm,
    required this.shadowMd,
    required this.motionFast,
    required this.motionNormal,
    required this.motionSlow,
  });

  /// Spacing, radius, elevation, and motion are brightness-independent, so
  /// [light] and [dark] share every field except the semantic colors and
  /// shadows below.
  static const double _spacingXs = 4;
  static const double _spacingSm = 8;
  static const double _spacingMd = 16;
  static const double _spacingLg = 24;
  static const double _spacingXl = 32;
  static const double _spacingXxl = 48;

  static const double _radiusSm = 4;
  static const double _radiusMd = 8;
  static const double _radiusLg = 16;
  static const double _radiusPill = 999;

  static const double _elevation1 = 1;
  static const double _elevation2 = 3;
  static const double _elevation3 = 6;
  static const double _elevation4 = 8;

  static const Duration _motionFast = Duration(milliseconds: 120);
  static const Duration _motionNormal = Duration(milliseconds: 220);
  static const Duration _motionSlow = Duration(milliseconds: 360);

  /// Velora's default light-mode token set.
  static const light = VeloraTokens(
    spacingXs: _spacingXs,
    spacingSm: _spacingSm,
    spacingMd: _spacingMd,
    spacingLg: _spacingLg,
    spacingXl: _spacingXl,
    spacingXxl: _spacingXxl,
    radiusSm: _radiusSm,
    radiusMd: _radiusMd,
    radiusLg: _radiusLg,
    radiusPill: _radiusPill,
    success: Color(0xFF1E7D46),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5300),
    onWarning: Color(0xFFFFFFFF),
    info: Color(0xFF1A5FB4),
    onInfo: Color(0xFFFFFFFF),
    elevation1: _elevation1,
    elevation2: _elevation2,
    elevation3: _elevation3,
    elevation4: _elevation4,
    shadowSm: [
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
    shadowMd: [
      BoxShadow(
        color: Color(0x29000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    motionFast: _motionFast,
    motionNormal: _motionNormal,
    motionSlow: _motionSlow,
  );

  /// Velora's default dark-mode token set. Spacing/radius/elevation/motion
  /// match [light]; only the semantic colors and shadow opacities change so
  /// they read correctly against dark surfaces.
  static const dark = VeloraTokens(
    spacingXs: _spacingXs,
    spacingSm: _spacingSm,
    spacingMd: _spacingMd,
    spacingLg: _spacingLg,
    spacingXl: _spacingXl,
    spacingXxl: _spacingXxl,
    radiusSm: _radiusSm,
    radiusMd: _radiusMd,
    radiusLg: _radiusLg,
    radiusPill: _radiusPill,
    success: Color(0xFF6FDC9D),
    onSuccess: Color(0xFF063823),
    warning: Color(0xFFFFC46B),
    onWarning: Color(0xFF452B00),
    info: Color(0xFF9CC8FF),
    onInfo: Color(0xFF0B3564),
    elevation1: _elevation1,
    elevation2: _elevation2,
    elevation3: _elevation3,
    elevation4: _elevation4,
    shadowSm: [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
    shadowMd: [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    motionFast: _motionFast,
    motionNormal: _motionNormal,
    motionSlow: _motionSlow,
  );

  @override
  VeloraTokens copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? spacingXxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusPill,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    double? elevation1,
    double? elevation2,
    double? elevation3,
    double? elevation4,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    Duration? motionFast,
    Duration? motionNormal,
    Duration? motionSlow,
  }) {
    return VeloraTokens(
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      spacingXxl: spacingXxl ?? this.spacingXxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusPill: radiusPill ?? this.radiusPill,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      elevation1: elevation1 ?? this.elevation1,
      elevation2: elevation2 ?? this.elevation2,
      elevation3: elevation3 ?? this.elevation3,
      elevation4: elevation4 ?? this.elevation4,
      shadowSm: shadowSm ?? this.shadowSm,
      shadowMd: shadowMd ?? this.shadowMd,
      motionFast: motionFast ?? this.motionFast,
      motionNormal: motionNormal ?? this.motionNormal,
      motionSlow: motionSlow ?? this.motionSlow,
    );
  }

  @override
  VeloraTokens lerp(ThemeExtension<VeloraTokens>? other, double t) {
    if (other is! VeloraTokens) return this;
    return VeloraTokens(
      spacingXs: lerpDouble(spacingXs, other.spacingXs, t)!,
      spacingSm: lerpDouble(spacingSm, other.spacingSm, t)!,
      spacingMd: lerpDouble(spacingMd, other.spacingMd, t)!,
      spacingLg: lerpDouble(spacingLg, other.spacingLg, t)!,
      spacingXl: lerpDouble(spacingXl, other.spacingXl, t)!,
      spacingXxl: lerpDouble(spacingXxl, other.spacingXxl, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      elevation1: lerpDouble(elevation1, other.elevation1, t)!,
      elevation2: lerpDouble(elevation2, other.elevation2, t)!,
      elevation3: lerpDouble(elevation3, other.elevation3, t)!,
      elevation4: lerpDouble(elevation4, other.elevation4, t)!,
      // BoxShadow lists aren't smoothly interpolable in general (they can
      // differ in length), so — same as most ThemeExtension shadow fields
      // in the wild — this just snaps to whichever endpoint `t` is closer
      // to rather than blending blur/offset/color frame-by-frame.
      shadowSm: t < 0.5 ? shadowSm : other.shadowSm,
      shadowMd: t < 0.5 ? shadowMd : other.shadowMd,
      motionFast: _lerpDuration(motionFast, other.motionFast, t),
      motionNormal: _lerpDuration(motionNormal, other.motionNormal, t),
      motionSlow: _lerpDuration(motionSlow, other.motionSlow, t),
    );
  }

  /// Interpolates two [Duration]s by lerping their millisecond counts —
  /// there's no `Duration.lerp` in the SDK, so this is [VeloraTokens]'
  /// equivalent for the motion tokens.
  static Duration _lerpDuration(Duration a, Duration b, double t) {
    final ms = lerpDouble(
      a.inMilliseconds.toDouble(),
      b.inMilliseconds.toDouble(),
      t,
    )!;
    return Duration(milliseconds: ms.round());
  }
}
