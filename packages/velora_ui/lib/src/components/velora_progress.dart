import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A themed progress indicator — a thin rounded bar via
/// [VeloraProgress.linear], or a spinner via [VeloraProgress.circular].
///
/// Determinate when [value] is non-null (0.0-1.0); indeterminate (an
/// animated, unbounded sweep/scroll) when [value] is null. The active
/// portion is drawn in the theme's `primary` color and the track in
/// `surfaceContainerHighest`, matching the fill/track convention used
/// elsewhere in the kit; the linear bar's rounded ends come from
/// [VeloraTokens.radiusPill] (via a clip, since [LinearProgressIndicator]
/// itself only supports square ends).
class VeloraProgress extends StatelessWidget {
  /// The progress fraction, between 0.0 and 1.0. Null renders an
  /// indeterminate indicator instead.
  final double? value;

  /// The diameter of a [VeloraProgress.circular] indicator. Ignored by
  /// [VeloraProgress.linear], which always fills the available width.
  final double size;

  /// Whether this instance is the [circular] shape (true) or the [linear]
  /// one (false). Set by the named constructors below.
  final bool _circular;

  /// Creates a linear, full-width progress bar.
  const VeloraProgress.linear({super.key, this.value})
    : size = 0,
      _circular = false;

  /// Creates a circular, spinner-style progress indicator of the given
  /// [size] (diameter, defaults to 32).
  const VeloraProgress.circular({super.key, this.value, this.size = 32})
    : _circular = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;

    final valueColor = AlwaysStoppedAnimation<Color>(scheme.primary);

    if (_circular) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          value: value,
          valueColor: valueColor,
          backgroundColor: scheme.surfaceContainerHighest,
          strokeWidth: 3,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusPill),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        valueColor: valueColor,
        backgroundColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
