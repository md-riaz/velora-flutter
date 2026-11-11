import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_nav_bar.dart';
import 'velora_nav_destination.dart';
import 'velora_nav_rail.dart';

/// The window-width class a [VeloraAdaptiveShell] lays out for.
enum VeloraShellBreakpoint {
  /// Phones: bottom navigation.
  compact,

  /// Tablets and small windows: navigation rail.
  medium,

  /// Desktop and wide windows: navigation rail plus the secondary pane.
  expanded;

  /// Classifies [width] in logical pixels.
  static VeloraShellBreakpoint forWidth(
    double width, {
    double medium = 600,
    double expanded = 1024,
  }) {
    if (width >= expanded) return VeloraShellBreakpoint.expanded;
    if (width >= medium) return VeloraShellBreakpoint.medium;
    return VeloraShellBreakpoint.compact;
  }
}

/// An app shell that swaps its navigation for the available width: a
/// [VeloraNavBar] at the bottom when compact, a [VeloraNavRail] at the side
/// when medium or expanded.
///
/// The shell knows nothing about routes. The caller owns [selectedIndex],
/// maps each [VeloraNavDestination] to its own router, and passes the
/// current page as [body]. Anything that should select a destination — a
/// tap, a deep link, a notification — does so by changing [selectedIndex].
///
/// **State survives resizing.** [body] and [secondaryPane] keep their
/// `State` when the window crosses a breakpoint and the navigation moves.
///
/// **Slots.** [status] is a full-width strip under the app bar for
/// caller-supplied connectivity or sync state; the shell does not detect
/// either. [railLeading] and [railTrailing] hold things like an account
/// switcher. [secondaryPane] is shown only when expanded; at narrower widths
/// the caller decides where that content goes (see [VeloraMasterDetailShell]
/// for list/detail).
///
/// Keyboard: destinations are Tab stops, in order, before the body.
class VeloraAdaptiveShell extends StatefulWidget {
  /// The top-level destinations.
  final List<VeloraNavDestination> destinations;

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

  /// Optional side pane, shown only at [VeloraShellBreakpoint.expanded].
  final Widget? secondaryPane;

  /// Width of [secondaryPane].
  final double secondaryPaneWidth;

  /// Shown above the rail destinations.
  final Widget? railLeading;

  /// Pinned to the bottom of the rail.
  final Widget? railTrailing;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Width at which the rail replaces the bottom bar.
  final double mediumBreakpoint;

  /// Width at which [secondaryPane] appears.
  final double expandedBreakpoint;

  /// Creates an adaptive shell.
  VeloraAdaptiveShell({
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
    this.mediumBreakpoint = 600,
    this.expandedBreakpoint = 1024,
  }) : assert(
         destinations.isNotEmpty,
         'VeloraAdaptiveShell requires at least one destination.',
       ),
       assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'VeloraAdaptiveShell selectedIndex must identify a destination.',
       ),
       assert(
         mediumBreakpoint <= expandedBreakpoint,
         'mediumBreakpoint must not exceed expandedBreakpoint.',
       );

  @override
  State<VeloraAdaptiveShell> createState() => _VeloraAdaptiveShellState();
}

class _VeloraAdaptiveShellState extends State<VeloraAdaptiveShell> {
  // Global keys move the subtrees, with their State, when the layout around
  // them changes at a breakpoint.
  final GlobalKey _bodyKey = GlobalKey(debugLabel: 'VeloraAdaptiveShell body');
  final GlobalKey _paneKey = GlobalKey(debugLabel: 'VeloraAdaptiveShell pane');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = VeloraShellBreakpoint.forWidth(
          constraints.maxWidth,
          medium: widget.mediumBreakpoint,
          expanded: widget.expandedBreakpoint,
        );
        final compact = breakpoint == VeloraShellBreakpoint.compact;
        final pane = widget.secondaryPane;
        final showPane =
            pane != null && breakpoint == VeloraShellBreakpoint.expanded;
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
              VeloraNavRail(
                destinations: widget.destinations,
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
          body: SafeArea(child: content),
          floatingActionButton: widget.floatingActionButton,
          bottomNavigationBar: compact
              ? VeloraNavBar(
                  destinations: widget.destinations,
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: widget.onDestinationSelected,
                )
              : null,
        );
      },
    );
  }
}

/// A list/detail layout: side by side when there is room, one at a time when
/// there is not.
///
/// The caller owns the selection. Pass the detail for the selected item as
/// [detail], or null when nothing is selected. At or above [breakpoint] the
/// [master] and the detail (or [placeholder]) sit side by side. Below it the
/// detail covers the master while one is selected.
///
/// Closing the detail is the caller's job too: the shell calls
/// [onCloseDetail] on system back and on Escape, and the caller clears its
/// selection. When the detail closes, focus returns to whatever was focused
/// in [master] — typically the row that opened it.
///
/// [master] and [detail] keep their `State` across breakpoint changes, and
/// [master] stays mounted (scroll position included) while covered.
class VeloraMasterDetailShell extends StatefulWidget {
  /// The list side.
  final Widget master;

  /// The detail for the current selection, or null when there is none.
  final Widget? detail;

  /// Shown beside [master] in the wide layout when [detail] is null.
  final Widget? placeholder;

  /// Called on system back or Escape while [detail] is showing.
  final VoidCallback? onCloseDetail;

  /// Width at which both sides are shown together.
  final double breakpoint;

  /// Width of [master] in the wide layout.
  final double masterWidth;

  /// Creates a master/detail shell.
  const VeloraMasterDetailShell({
    super.key,
    required this.master,
    this.detail,
    this.placeholder,
    this.onCloseDetail,
    this.breakpoint = 840,
    this.masterWidth = 360,
  });

  @override
  State<VeloraMasterDetailShell> createState() =>
      _VeloraMasterDetailShellState();
}

class _VeloraMasterDetailShellState extends State<VeloraMasterDetailShell> {
  final GlobalKey _masterKey = GlobalKey(debugLabel: 'VeloraMasterDetail list');
  final GlobalKey _detailKey = GlobalKey(
    debugLabel: 'VeloraMasterDetail detail',
  );
  final FocusScopeNode _masterScope = FocusScopeNode(
    debugLabel: 'VeloraMasterDetail list scope',
  );
  final FocusScopeNode _detailScope = FocusScopeNode(
    debugLabel: 'VeloraMasterDetail detail scope',
  );

  @override
  void didUpdateWidget(covariant VeloraMasterDetailShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final opened = oldWidget.detail == null && widget.detail != null;
    final closed = oldWidget.detail != null && widget.detail == null;
    if (!opened && !closed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A FocusScopeNode remembers its last focused child, so this puts
      // focus back on the row that opened the detail.
      (closed ? _masterScope : _detailScope).requestFocus();
    });
  }

  @override
  void dispose() {
    _masterScope.dispose();
    _detailScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = widget.detail;
    final hasDetail = detail != null;

    final master = FocusScope(
      key: _masterKey,
      node: _masterScope,
      child: widget.master,
    );
    final detailPane = hasDetail
        ? FocusScope(key: _detailKey, node: _detailScope, child: detail)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= widget.breakpoint;
        final Widget layout;
        if (wide) {
          layout = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: widget.masterWidth, child: master),
              VerticalDivider(width: 1, color: scheme.outlineVariant),
              Expanded(
                child:
                    detailPane ?? widget.placeholder ?? const SizedBox.shrink(),
              ),
            ],
          );
        } else {
          layout = Stack(
            fit: StackFit.expand,
            children: [
              // Kept mounted so the list keeps its scroll position.
              Offstage(
                offstage: hasDetail,
                child: ExcludeFocus(excluding: hasDetail, child: master),
              ),
              if (detailPane != null)
                ColoredBox(color: scheme.surface, child: detailPane),
            ],
          );
        }

        return PopScope(
          canPop: !hasDetail || wide,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onCloseDetail?.call();
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              if (hasDetail)
                const SingleActivator(LogicalKeyboardKey.escape): () =>
                    widget.onCloseDetail?.call(),
            },
            child: layout,
          ),
        );
      },
    );
  }
}

/// A full-width status strip for [VeloraAdaptiveShell.status].
///
/// Purely presentational: the caller decides when the app is offline,
/// syncing, or back online and passes the text. Announced to screen readers
/// as a live region, so a change is read out without moving focus.
class VeloraStatusStrip extends StatelessWidget {
  /// What to tell the user, e.g. "Offline — changes will sync later".
  final String message;

  /// Optional leading icon.
  final IconData? icon;

  /// Shows a small spinner instead of [icon], for in-progress states.
  final bool busy;

  /// Optional trailing widget, e.g. a Retry button.
  final Widget? action;

  /// Creates a status strip.
  const VeloraStatusStrip({
    super.key,
    required this.message,
    this.icon,
    this.busy = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurfaceVariant;
    return Semantics(
      container: true,
      liveRegion: true,
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingMd,
            vertical: tokens.spacingSm,
          ),
          child: Row(
            children: [
              if (busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 16, color: color),
              if (busy || icon != null) SizedBox(width: tokens.spacingSm),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: color),
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}
