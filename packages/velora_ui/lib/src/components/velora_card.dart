import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A padded, rounded surface — the default container for grouped content in a
/// Velora app.
///
/// Velora's card is flat by design: a hairline `outlineVariant` border does
/// the work Material's drop shadow usually does, so the surface reads as
/// "grouped" without looking lifted off the page. It derives its radius from
/// [VeloraTokens.radiusLg] and its padding from [VeloraTokens.spacingMd]; when
/// [elevated] is true a soft shadow (scaled off [VeloraTokens.elevation2]) is
/// layered on top of the border for surfaces that should read as raised (e.g.
/// above a scrolling list). Pass [onTap] to make the whole card tappable
/// (with a ripple clipped to the rounded corners); pass [padding] to override
/// the default inset (e.g. `EdgeInsets.zero` for a card whose child paints
/// edge-to-edge).
class VeloraCard extends StatelessWidget {
  /// The card's contents.
  final Widget child;

  /// Inner padding around [child]. Defaults to `EdgeInsets.all(spacingMd)`.
  final EdgeInsetsGeometry? padding;

  /// Called when the card is tapped. If null, the card is not interactive.
  final VoidCallback? onTap;

  /// The card's fill color. Defaults to the theme's `surface`.
  final Color? color;

  /// Whether to layer a soft shadow on top of the card's hairline border.
  /// Defaults to true. The card is flat and bordered either way — this only
  /// adds the extra lift for surfaces that should read as raised.
  final bool elevated;

  /// Creates a Velora card.
  const VeloraCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radiusLg);

    final content = Padding(
      padding: padding ?? EdgeInsets.all(tokens.spacingMd),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.08),
                  blurRadius: tokens.elevation2 * 2,
                  offset: Offset(0, tokens.elevation2 / 2),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, borderRadius: radius, child: content),
      ),
    );
  }
}
