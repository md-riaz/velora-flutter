import 'package:flutter/material.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_nav_destination.dart';

/// A flat bottom navigation bar — a row of [VeloraNavDestination]s, each an
/// icon above a label, with the active one picked out in `primary`.
///
/// Controlled: the caller owns [selectedIndex] and is notified of taps via
/// [onDestinationSelected] rather than the bar managing its own state. The
/// bar sits on the theme's surface color with a hairline `outlineVariant`
/// border along its top edge — the same flat-surface, hairline-separator
/// identity [VeloraDivider] and [VeloraCard] use — and insets itself for the
/// bottom safe area (the home indicator on notched devices) automatically.
///
/// Each item shows [VeloraNavDestination.selectedIcon] (falling back to
/// [VeloraNavDestination.icon]) when selected, behind a soft
/// `primaryContainer` pill; unselected items show `icon` in
/// `onSurfaceVariant`. The whole item — icon and label — is one tap target.
class VeloraNavBar extends StatelessWidget {
  /// The destinations to show, left to right.
  final List<VeloraNavDestination> destinations;

  /// The index of the currently-selected destination.
  final int selectedIndex;

  /// Called with a destination's index when it's tapped.
  final ValueChanged<int> onDestinationSelected;

  /// Creates a Velora bottom nav bar.
  const VeloraNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _VeloraNavBarItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VeloraNavBarItem extends StatelessWidget {
  final VeloraNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _VeloraNavBarItem({
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

    return Semantics(
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
