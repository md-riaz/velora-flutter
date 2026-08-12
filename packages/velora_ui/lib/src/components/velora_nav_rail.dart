import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_nav_destination.dart';

/// A flat, wide-screen side navigation rail — the [VeloraNavBar]'s vertical
/// counterpart for tablet/desktop layouts, sharing the same
/// [VeloraNavDestination] model, [selectedIndex], and
/// [onDestinationSelected] callback so a single destination list can drive
/// either surface at a layout breakpoint.
///
/// A vertical column of items (icon above label), with a hairline
/// `outlineVariant` border along its trailing edge. The active destination
/// shows [VeloraNavDestination.selectedIcon] (falling back to
/// [VeloraNavDestination.icon]) behind a soft `primaryContainer` pill and
/// `primary`-colored label; inactive items use `onSurfaceVariant`. Optional
/// [leading] (e.g. a logo) and [trailing] (e.g. a settings button) widgets
/// sit above the destinations and pinned to the bottom, respectively.
class VeloraNavRail extends StatelessWidget {
  /// The destinations to show, top to bottom.
  final List<VeloraNavDestination> destinations;

  /// The index of the currently-selected destination.
  final int selectedIndex;

  /// Called with a destination's index when it's tapped.
  final ValueChanged<int> onDestinationSelected;

  /// An optional widget shown above the destinations (e.g. a logo/avatar).
  final Widget? leading;

  /// An optional widget pinned to the bottom of the rail (e.g. a settings
  /// button).
  final Widget? trailing;

  /// Creates a Velora nav rail.
  const VeloraNavRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        width: 88,
        child: Column(
          children: [
            if (leading != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacingMd),
                child: leading,
              ),
            for (var i = 0; i < destinations.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacingXs),
                child: _VeloraNavRailItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
            const Spacer(),
            if (trailing != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacingMd),
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }
}

class _VeloraNavRailItem extends StatelessWidget {
  final VeloraNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _VeloraNavRailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacingSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(tokens.radiusPill),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spacingMd,
                  vertical: tokens.spacingXs,
                ),
                child: Icon(
                  selected
                      ? (destination.selectedIcon ?? destination.icon)
                      : destination.icon,
                  color: color,
                  size: 22,
                ),
              ),
            ),
            SizedBox(height: tokens.spacingXs / 2),
            Text(
              destination.label,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
