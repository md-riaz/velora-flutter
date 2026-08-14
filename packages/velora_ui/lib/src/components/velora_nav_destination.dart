import 'package:flutter/material.dart';

/// A single destination in a [VeloraNavBar] or [VeloraNavRail] — an icon
/// (with an optional distinct selected variant) and a label.
///
/// This is a plain, immutable model shared by both navigation surfaces, not a
/// widget itself: build a `List<VeloraNavDestination>` once and hand it to
/// whichever of [VeloraNavBar] (compact/mobile) or [VeloraNavRail]
/// (wide-screen) fits the current layout — both read [selectedIndex] from the
/// caller, so switching between them at a breakpoint doesn't require
/// duplicating the destination list.
@immutable
class VeloraNavDestination {
  /// The icon shown when this destination is not selected.
  final IconData icon;

  /// An optional distinct icon shown when this destination is selected (e.g.
  /// an outlined [icon] paired with a filled variant here). Falls back to
  /// [icon] when null.
  final IconData? selectedIcon;

  /// The destination's label.
  final String label;

  /// Creates a Velora nav destination.
  const VeloraNavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
