import 'package:flutter/material.dart';

/// A thin, token-styled wrapper around Material's [Tooltip].
///
/// [VeloraTooltip] doesn't carry any styling of its own — the background,
/// text style, radius, and padding all come from the active theme's
/// `TooltipThemeData` (set up by `buildVeloraTheme`). This widget exists
/// purely so a Velora screen can reach for `VeloraTooltip` alongside the
/// rest of the kit rather than reaching back into `package:flutter`.
///
/// ```dart
/// VeloraTooltip(
///   message: 'Copy to clipboard',
///   child: IconButton(icon: const Icon(Icons.copy), onPressed: copy),
/// )
/// ```
class VeloraTooltip extends StatelessWidget {
  /// The text shown on long-press/hover.
  final String message;

  /// The widget the tooltip wraps.
  final Widget child;

  /// Creates a Velora tooltip.
  const VeloraTooltip({super.key, required this.message, required this.child});

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: message, child: child);
  }
}
