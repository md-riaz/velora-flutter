import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A compact, interactive chip for filters, selections, and tags.
///
/// Unlike [VeloraBadge] (a passive status label), a chip is interactive: it
/// can be [selected] and toggled via [onTap], and/or dismissed via
/// [onDeleted]. Selected chips fill with the theme's primary color; unselected
/// chips show a tinted/outlined resting state. All colors and rounding come
/// from the theme's [ColorScheme] and [VeloraTokens].
class VeloraChip extends StatelessWidget {
  /// The chip's label.
  final String label;

  /// Whether the chip is in its selected/active state.
  final bool selected;

  /// Called when the chip body is tapped (typically toggles [selected]). If
  /// null, the chip body is not tappable.
  final VoidCallback? onTap;

  /// Called when the chip's trailing delete affordance is tapped. If null, no
  /// delete icon is shown.
  final VoidCallback? onDeleted;

  /// An optional icon shown before the label (e.g. a filter glyph, an avatar
  /// stand-in).
  final IconData? icon;

  /// Creates a Velora chip.
  const VeloraChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radiusPill);

    final Color background;
    final Color foreground;
    final Border? border;
    if (selected) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
      border = null;
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
      border = Border.all(color: scheme.outlineVariant);
    }

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingSm + tokens.spacingXs,
        vertical: tokens.spacingXs + 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            SizedBox(width: tokens.spacingXs),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDeleted != null) ...[
            SizedBox(width: tokens.spacingXs),
            // A nested InkWell so the delete affordance has its own tap
            // target independent of the chip-body tap.
            InkResponse(
              onTap: onDeleted,
              radius: 14,
              child: Icon(Icons.close, size: 16, color: foreground),
            ),
          ],
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: border,
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
