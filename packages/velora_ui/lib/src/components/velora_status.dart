import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';

enum StatusTone {
  success,
  warning,
  info,
  error;

  IconData get icon => switch (this) {
    success => Icons.check_circle_outline,
    warning => Icons.warning_amber_outlined,
    info => Icons.info_outline,
    error => Icons.error_outline,
  };
}

@immutable
class StatusColorPair {
  final Color color;
  final Color onColor;
  const StatusColorPair(this.color, this.onColor);
  StatusColorPair lerp(StatusColorPair other, double t) => StatusColorPair(
    Color.lerp(color, other.color, t)!,
    Color.lerp(onColor, other.onColor, t)!,
  );
}

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final StatusColorPair success, warning, info, error;
  const StatusColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.error,
  });
  factory StatusColors.fromScheme(ColorScheme scheme, DesignTokens tokens) {
    StatusColorPair pair(Color seed) {
      final derived = ColorScheme.fromSeed(
        seedColor: Color.lerp(seed, scheme.primary, 0.12)!,
        brightness: scheme.brightness,
      );
      return StatusColorPair(derived.primary, derived.onPrimary);
    }

    return StatusColors(
      success: pair(tokens.success),
      warning: pair(tokens.warning),
      info: pair(tokens.info),
      error: StatusColorPair(scheme.error, scheme.onError),
    );
  }
  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ??
      (throw StateError('StatusColors missing from theme'));
  StatusColorPair forTone(StatusTone tone) => switch (tone) {
    StatusTone.success => success,
    StatusTone.warning => warning,
    StatusTone.info => info,
    StatusTone.error => error,
  };
  @override
  StatusColors copyWith({
    StatusColorPair? success,
    StatusColorPair? warning,
    StatusColorPair? info,
    StatusColorPair? error,
  }) => StatusColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    error: error ?? this.error,
  );
  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) =>
      other is! StatusColors
      ? this
      : StatusColors(
          success: success.lerp(other.success, t),
          warning: warning.lerp(other.warning, t),
          info: info.lerp(other.info, t),
          error: error.lerp(other.error, t),
        );
}
