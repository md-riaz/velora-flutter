import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

/// Showcases velora_ui's Layer 5 navigation components:
/// [VeloraTabs], [VeloraNavBar], and [VeloraNavRail].
///
/// [VeloraScaffold] composes these (plus an app bar and body) into a full
/// page, but this gallery demos each piece directly rather than nesting a
/// second `Scaffold` inside the gallery's own scrolling body.
///
/// Every control here is controlled by local state and wired through
/// `setState`, so switching tabs and tapping destinations actually work when
/// you interact with the gallery.
class NavSection extends StatefulWidget {
  /// Creates the navigation showcase section.
  const NavSection({super.key});

  @override
  State<NavSection> createState() => _NavSectionState();
}

class _NavSectionState extends State<NavSection> {
  int _selectedTab = 1;
  int _selectedNav = 0;
  int _selectedRail = 0;

  static const _tabs = ['Day', 'Week', 'Month'];

  static const _destinations = [
    VeloraNavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    VeloraNavDestination(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Search',
    ),
    VeloraNavDestination(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Alerts',
    ),
    VeloraNavDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VeloraSectionHeader(
          title: 'Tabs',
          subtitle: 'A pill segmented control for switching in-content views',
        ),
        VeloraTabs(
          tabs: _tabs,
          selectedIndex: _selectedTab,
          onChanged: (index) => setState(() => _selectedTab = index),
        ),
        SizedBox(height: tokens.spacingSm),
        Text(
          'Showing: ${_tabs[_selectedTab]}',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Nav bar',
          subtitle: 'A flat bottom navigation bar for compact/mobile layouts',
        ),
        VeloraCard(
          padding: EdgeInsets.zero,
          child: VeloraNavBar(
            destinations: _destinations,
            selectedIndex: _selectedNav,
            onDestinationSelected: (index) =>
                setState(() => _selectedNav = index),
          ),
        ),
        SizedBox(height: tokens.spacingSm),
        Text(
          'Selected: ${_destinations[_selectedNav].label}',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Nav rail',
          subtitle:
              'The wide-screen counterpart, with leading/trailing slots '
              'for a logo and settings action',
        ),
        SizedBox(
          height: 420,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VeloraCard(
                padding: EdgeInsets.zero,
                child: VeloraNavRail(
                  destinations: _destinations,
                  selectedIndex: _selectedRail,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedRail = index),
                  leading: const VeloraAvatar(name: 'Velora', size: 32),
                  trailing: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    onPressed: () {},
                  ),
                ),
              ),
              SizedBox(width: tokens.spacingMd),
              Expanded(
                child: Center(
                  child: Text(
                    'Selected: ${_destinations[_selectedRail].label}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
