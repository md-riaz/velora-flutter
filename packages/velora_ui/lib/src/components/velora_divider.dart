import 'package:flutter/material.dart';

/// A thin themed separator — horizontal by default, or vertical via
/// [vertical].
///
/// Draws a hairline in the theme's `outlineVariant` color — the same subdued
/// separator color Material's own [Divider]/[VerticalDivider] use — so it
/// stays consistent with the rest of the theme automatically without
/// needing a Velora-specific token. [indent] and [endIndent] inset the line
/// from its leading/trailing edge, with the same meaning as
/// [Divider.indent]/[Divider.endIndent].
class VeloraDivider extends StatelessWidget {
  /// When true, renders a vertical divider (for use inside a [Row]) instead
  /// of the default horizontal one (for use inside a [Column]).
  final bool vertical;

  /// Space before the line's leading edge. Defaults to 0.
  final double indent;

  /// Space after the line's trailing edge. Defaults to 0.
  final double endIndent;

  /// An override color for the line. Defaults to the theme's
  /// `outlineVariant`.
  final Color? color;

  /// Creates a Velora divider.
  const VeloraDivider({
    super.key,
    this.vertical = false,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = color ?? scheme.outlineVariant;

    if (vertical) {
      return VerticalDivider(
        width: 1,
        thickness: 1,
        indent: indent,
        endIndent: endIndent,
        color: lineColor,
      );
    }
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: lineColor,
    );
  }
}
