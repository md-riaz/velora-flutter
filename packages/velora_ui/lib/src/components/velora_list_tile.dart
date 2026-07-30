import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';

/// A token-styled row for a titled list item — an optional [leading] widget
/// (an icon, a [VeloraAvatar]), a required [title], an optional [subtitle],
/// and an optional [trailing] widget (an icon, a [VeloraBadge], a chevron).
///
/// Pass [onTap] to make the whole row tappable (with a ripple clipped to the
/// token radius, the same [Material]/[InkWell] pairing [VeloraCard] uses);
/// leave it null for a static, informational row. Spacing and radius come
/// from [VeloraTokens]; text styles come from the ambient [TextTheme] with
/// [ColorScheme]-driven colors.
class VeloraListTile extends StatelessWidget {
  /// An optional leading widget, typically an [Icon] or a [VeloraAvatar].
  final Widget? leading;

  /// The row's primary text.
  final String title;

  /// Optional secondary text shown below [title].
  final String? subtitle;

  /// An optional trailing widget, typically an [Icon], a [VeloraBadge], or a
  /// chevron.
  final Widget? trailing;

  /// Called when the row is tapped. If null, the row is not interactive.
  final VoidCallback? onTap;

  /// Creates a Velora list tile.
  const VeloraListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radiusMd);

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingMd,
        vertical: tokens.spacingSm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: tokens.spacingSm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: tokens.spacingSm),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}
