import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';
import '../theme/velora_tokens_context.dart';

/// A semantic status level shared by the components that communicate state —
/// [VeloraBadge], [VeloraAlert], and friends.
///
/// Each level maps to a color pair (a fill color and a legible "on" color)
/// that's resolved from the active theme: [error] comes from Material's
/// [ColorScheme] (`error`/`onError`), while [success]/[warning]/[info] come
/// from [VeloraTokens] (which Material's scheme doesn't define). Resolving
/// through the theme — rather than hard-coding hex — means a component
/// automatically tracks light/dark mode and any token overrides.
enum VeloraStatus {
  /// A successful / positive outcome (a saved change, a completed task).
  success,

  /// A cautionary state that isn't yet an error (a nearing limit, a
  /// deprecation).
  warning,

  /// A neutral, informational message.
  info,

  /// A failure / destructive state (a rejected request, a validation error).
  error,
}

/// The two colors a [VeloraStatus] resolves to against the current theme: a
/// [color] (the strong/fill color) and an [onColor] (legible content drawn on
/// top of [color]).
@immutable
class VeloraStatusColors {
  /// The strong/fill color for this status (used for solid badges, alert
  /// accents, icons).
  final Color color;

  /// A color legible when drawn on top of [color] (text/icons inside a solid
  /// badge).
  final Color onColor;

  /// Creates a resolved status color pair.
  const VeloraStatusColors({required this.color, required this.onColor});
}

/// Resolves a [VeloraStatus] to concrete colors from the ambient theme.
extension VeloraStatusResolver on VeloraStatus {
  /// Looks up this status's color pair from [VeloraTokens] (success/warning/
  /// info) or the [ColorScheme] (error) on the theme above [context].
  VeloraStatusColors colors(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case VeloraStatus.success:
        return VeloraStatusColors(
          color: tokens.success,
          onColor: tokens.onSuccess,
        );
      case VeloraStatus.warning:
        return VeloraStatusColors(
          color: tokens.warning,
          onColor: tokens.onWarning,
        );
      case VeloraStatus.info:
        return VeloraStatusColors(color: tokens.info, onColor: tokens.onInfo);
      case VeloraStatus.error:
        return VeloraStatusColors(
          color: scheme.error,
          onColor: scheme.onError,
        );
    }
  }

  /// The default leading icon for this status, used by [VeloraAlert] and any
  /// other component that shows a status glyph.
  IconData get icon {
    switch (this) {
      case VeloraStatus.success:
        return Icons.check_circle_outline;
      case VeloraStatus.warning:
        return Icons.warning_amber_outlined;
      case VeloraStatus.info:
        return Icons.info_outline;
      case VeloraStatus.error:
        return Icons.error_outline;
    }
  }
}
