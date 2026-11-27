import 'package:flutter/material.dart';

/// A responsive master-detail layout.
///
/// When the available width is at least [breakpoint] (840 logical pixels by
/// default, matching Material 3's expanded window class), [masterBuilder] and
/// the detail pane are rendered side-by-side in a [Row]. If [masterWidth] is
/// provided, the master pane uses that fixed width; otherwise [masterFlex] and
/// [detailFlex] control the split.
///
/// Below [breakpoint], only the master pane is rendered. Selecting an item via
/// the `onSelect` callback passed to [masterBuilder] pushes a route containing
/// [detailBuilder] onto the nearest [Navigator].
class MasterDetail<T extends Object?> extends StatefulWidget {
  /// Builds the master pane. Call `onSelect(item)` when an item is chosen.
  final Widget Function(BuildContext context, ValueChanged<T> onSelect)
  masterBuilder;

  /// Builds the detail pane for [selected].
  final Widget Function(BuildContext context, T selected) detailBuilder;

  /// Optional controlled selection. When non-null, takes precedence over
  /// internal selection state.
  final T? selected;

  /// Optional initial selection when [selected] is uncontrolled.
  final T? initialSelected;

  /// Called whenever an item is selected in either compact or wide layout.
  final ValueChanged<T>? onSelected;

  /// Optional widget shown in the detail pane on wide screens when no item is
  /// selected.
  final Widget? emptyDetail;

  /// Width threshold (in logical pixels) at which the side-by-side layout
  /// activates. Defaults to `840`.
  final double breakpoint;

  /// Optional fixed width for the master pane in wide layout. When null,
  /// [masterFlex] and [detailFlex] determine the pane proportions.
  final double? masterWidth;

  /// Flex factor for the master pane when [masterWidth] is null. Defaults to 1.
  final int masterFlex;

  /// Flex factor for the detail pane in wide layout. Defaults to 2.
  final int detailFlex;

  /// Whether to render a [VerticalDivider] between master and detail panes on
  /// wide screens. Defaults to `true`.
  final bool showDivider;

  /// Optional custom route builder used when pushing the detail pane on compact
  /// screens. Defaults to [MaterialPageRoute].
  final Route<void> Function(BuildContext context, Widget detail)?
  detailRouteBuilder;

  /// Creates a responsive master-detail layout.
  const MasterDetail({
    super.key,
    required this.masterBuilder,
    required this.detailBuilder,
    this.selected,
    this.initialSelected,
    this.onSelected,
    this.emptyDetail,
    this.breakpoint = 840,
    this.masterWidth,
    this.masterFlex = 1,
    this.detailFlex = 2,
    this.showDivider = true,
    this.detailRouteBuilder,
  }) : assert(masterFlex > 0, 'masterFlex must be positive.'),
       assert(detailFlex > 0, 'detailFlex must be positive.');

  @override
  State<MasterDetail<T>> createState() => _MasterDetailState<T>();
}

class _MasterDetailState<T extends Object?> extends State<MasterDetail<T>> {
  T? _internalSelected;

  @override
  void initState() {
    super.initState();
    _internalSelected = widget.initialSelected;
  }

  T? get _activeSelected => widget.selected ?? _internalSelected;

  void _handleSelect(BuildContext context, T item, bool isWide) {
    if (widget.selected == null) {
      setState(() => _internalSelected = item);
    }
    widget.onSelected?.call(item);

    if (!isWide) {
      final detail = widget.detailBuilder(context, item);
      final route =
          widget.detailRouteBuilder?.call(context, detail) ??
          MaterialPageRoute<void>(builder: (_) => detail);
      Navigator.of(context).push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= widget.breakpoint;
        final master = widget.masterBuilder(
          context,
          (item) => _handleSelect(context, item, isWide),
        );

        if (!isWide) {
          return master;
        }

        final active = _activeSelected;
        final detail = active != null
            ? widget.detailBuilder(context, active)
            : (widget.emptyDetail ?? const SizedBox.shrink());

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.masterWidth != null)
              SizedBox(width: widget.masterWidth, child: master)
            else
              Expanded(flex: widget.masterFlex, child: master),
            if (widget.showDivider)
              VerticalDivider(width: 1, color: scheme.outlineVariant),
            Expanded(flex: widget.detailFlex, child: detail),
          ],
        );
      },
    );
  }
}
