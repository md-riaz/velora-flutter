import 'package:flutter/material.dart';

import 'velora_nav_destination.dart';

/// The window-width class a [AdaptiveShell] lays out for.
enum ShellBreakpoint {
  /// Phones: bottom navigation.
  compact,

  /// Tablets and small windows: navigation rail.
  medium,

  /// Desktop and wide windows: navigation rail plus the secondary pane.
  expanded;

  /// Classifies [width] in logical pixels.
  static ShellBreakpoint forWidth(
    double width, {
    double medium = 600,
    double expanded = 1024,
  }) {
    if (width >= expanded) return ShellBreakpoint.expanded;
    if (width >= medium) return ShellBreakpoint.medium;
    return ShellBreakpoint.compact;
  }
}

/// An app shell that swaps its navigation for the available width: a
/// a Material widget at the bottom when compact, a Material widget at the side
/// when medium or expanded.
///
/// The shell knows nothing about routes. The caller owns [selectedIndex],
/// maps each [ShellDestination] to its own router, and passes the
/// current page as [body]. Anything that should select a destination — a
/// tap, a deep link, a notification — does so by changing [selectedIndex].
///
/// **State survives resizing.** [body] keeps its `State` when the window
/// crosses a breakpoint and the navigation moves. [secondaryPane] is
/// unmounted below the expanded breakpoint, so its `State` is not preserved
/// there; hold any pane state (form, focus, scroll) in a parent the caller
/// owns.
///
/// **Slots.** [status] is a full-width strip under the app bar for
/// caller-supplied connectivity or sync state; the shell does not detect
/// either. [railLeading] and [railTrailing] hold things like an account
/// switcher. [secondaryPane] is shown only when expanded; at narrower widths
/// the caller decides where that content goes.
///
/// Keyboard: destinations are Tab stops, in order, before the body.
class AdaptiveShell extends StatefulWidget {
  /// The top-level destinations.
  final List<ShellDestination> destinations;

  /// Index of the selected destination.
  final int selectedIndex;

  /// Called with a destination's index when it is chosen.
  final ValueChanged<int> onDestinationSelected;

  /// The current page.
  final Widget body;

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  /// Optional strip under the app bar, e.g. an offline banner.
  final Widget? status;

  /// Optional side pane, shown only at [ShellBreakpoint.expanded].
  final Widget? secondaryPane;

  /// Width of [secondaryPane].
  final double secondaryPaneWidth;

  /// Shown above the rail destinations.
  final Widget? railLeading;

  /// Pinned to the bottom of the rail.
  final Widget? railTrailing;

  /// Optional floating action button.
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomInset;
  final bool extendedRail;
  final NavigationRailLabelType? railLabelType;

  /// Width at which the rail replaces the bottom bar.
  final double mediumBreakpoint;

  /// Width at which [secondaryPane] appears.
  final double expandedBreakpoint;

  /// Creates an adaptive shell.
  AdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.appBar,
    this.status,
    this.secondaryPane,
    this.secondaryPaneWidth = 360,
    this.railLeading,
    this.railTrailing,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset,
    this.extendedRail = false,
    this.railLabelType,
    this.mediumBreakpoint = 600,
    this.expandedBreakpoint = 1024,
  }) : assert(
         destinations.isNotEmpty,
         'AdaptiveShell requires at least one destination.',
       ),
       assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'AdaptiveShell selectedIndex must identify a destination.',
       ),
       assert(
         mediumBreakpoint <= expandedBreakpoint,
         'mediumBreakpoint must not exceed expandedBreakpoint.',
       );

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  // Global keys move the subtrees, with their State, when the layout around
  // them changes at a breakpoint.
  final GlobalKey _bodyKey = GlobalKey(debugLabel: 'AdaptiveShell body');
  final GlobalKey _paneKey = GlobalKey(debugLabel: 'AdaptiveShell pane');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = ShellBreakpoint.forWidth(
          constraints.maxWidth,
          medium: widget.mediumBreakpoint,
          expanded: widget.expandedBreakpoint,
        );
        final compact = breakpoint == ShellBreakpoint.compact;
        final pane = widget.secondaryPane;
        final showPane = pane != null && breakpoint == ShellBreakpoint.expanded;
        final status = widget.status;

        Widget content = KeyedSubtree(key: _bodyKey, child: widget.body);
        if (showPane) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: content),
              VerticalDivider(width: 1, color: scheme.outlineVariant),
              SizedBox(
                width: widget.secondaryPaneWidth,
                child: KeyedSubtree(key: _paneKey, child: pane),
              ),
            ],
          );
        }
        if (status != null) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              status,
              Expanded(child: content),
            ],
          );
        }
        if (!compact) {
          content = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavigationRail(
                extended: widget.extendedRail,
                labelType:
                    widget.railLabelType ??
                    (widget.extendedRail
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all),
                destinations: widget.destinations
                    .map(
                      (d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon ?? d.icon),
                        label: Text(d.label),
                      ),
                    )
                    .toList(),
                selectedIndex: widget.selectedIndex,
                onDestinationSelected: widget.onDestinationSelected,
                leading: widget.railLeading,
                trailing: widget.railTrailing,
              ),
              Expanded(child: content),
            ],
          );
        }

        return Scaffold(
          appBar: widget.appBar,
          drawer: widget.drawer,
          endDrawer: widget.endDrawer,
          backgroundColor: widget.backgroundColor,
          floatingActionButtonLocation: widget.floatingActionButtonLocation,
          resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
          body: SafeArea(child: content),
          floatingActionButton: widget.floatingActionButton,
          bottomNavigationBar: compact
              ? NavigationBar(
                  destinations: widget.destinations
                      .map(
                        (d) => NavigationDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon ?? d.icon),
                          label: d.label,
                        ),
                      )
                      .toList(),
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: widget.onDestinationSelected,
                )
              : null,
        );
      },
    );
  }
}
