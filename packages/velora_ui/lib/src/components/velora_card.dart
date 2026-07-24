import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A padded, rounded surface — the default container for grouped content in a
/// Velora app.
///
/// It derives its radius from [VeloraTokens.radiusLg], its padding from
/// [VeloraTokens.spacingMd], and its shadow from [VeloraTokens.shadowSm], so
/// cards stay visually consistent across the app. Pass [onTap] to make the
/// whole card tappable (with a ripple clipped to the rounded corners); pass
/// [padding] to override the default inset (e.g. `EdgeInsets.zero` for a card
/// whose child paints edge-to-edge).
class VeloraCard extends StatelessWidget {
  /// The card's contents.
  final Widget child;

  /// Inner padding around [child]. Defaults to `EdgeInsets.all(spacingMd)`.
  final EdgeInsetsGeometry? padding;

  /// Called when the card is tapped. If null, the card is not interactive.
  final VoidCallback? onTap;

  /// The card's fill color. Defaults to the theme's `surfaceContainerLow`.
  final Color? color;

  /// Whether to draw the token shadow beneath the card. Defaults to true;
  /// set to false for a flat card that relies on [color] contrast alone.
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
        color: color ?? scheme.surfaceContainerLow,
        borderRadius: radius,
        boxShadow: elevated ? tokens.shadowSm : null,
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
