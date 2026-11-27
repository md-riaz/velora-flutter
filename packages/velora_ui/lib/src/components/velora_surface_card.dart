import 'package:flutter/material.dart';

import '../tokens/velora_tokens.dart';

/// A [Material]-backed card surface safe for [ListTile], [InkWell], and ink
/// splashes.
///
/// Unlike a plain [Container] with a [BoxDecoration], [SurfaceCard] wraps its
/// content in `Material(type: MaterialType.card, ...)` with
/// `clipBehavior: Clip.antiAlias`, so nested [ListTile]s and [InkWell]s render
/// their ink splashes cleanly without triggering Flutter's
/// `"ListTile background color or ink splashes may be invisible"` assertion.
class SurfaceCard extends StatelessWidget {
  /// The card's content.
  final Widget child;

  /// Optional inner padding applied inside the card surface.
  final EdgeInsetsGeometry? padding;

  /// Optional outer margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Corner radius for the card shape. Defaults to `DesignTokens.radiusLg`
  /// when [DesignTokens] is present in the theme, or `16`.
  final BorderRadiusGeometry? borderRadius;

  /// Background color of the card surface. Defaults to `cardTheme.color` or
  /// `colorScheme.surfaceContainerLow`.
  final Color? color;

  /// Elevation of the card surface. Defaults to `0`.
  final double elevation;

  /// Optional border side. When omitted, defaults to a 1px
  /// `colorScheme.outlineVariant` border when [elevation] is `0`, or
  /// [BorderSide.none] when elevated.
  final BorderSide? borderSide;

  /// Optional tap callback. When provided, wraps the card content in an
  /// [InkWell] inside the [Material] surface.
  final VoidCallback? onTap;

  /// Creates a Material-backed surface card.
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.elevation = 0,
    this.borderSide,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.extension<DesignTokens>();
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(tokens?.radiusLg ?? 16);
    final effectiveColor =
        color ?? theme.cardTheme.color ?? scheme.surfaceContainerLow;
    final effectiveSide =
        borderSide ??
        (elevation == 0
            ? BorderSide(color: scheme.outlineVariant)
            : BorderSide.none);

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }

    Widget card = Material(
      type: MaterialType.card,
      color: effectiveColor,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveRadius,
        side: effectiveSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
