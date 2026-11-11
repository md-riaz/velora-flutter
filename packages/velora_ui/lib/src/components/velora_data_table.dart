import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/velora_tokens_context.dart';
import 'velora_skeleton.dart';

/// Which column a [VeloraDataTable] is sorted by, and in which direction.
///
/// The table never sorts rows itself. It shows this state in the header and
/// reports the state the user asked for through
/// [VeloraDataTable.onSortChanged]; the caller sorts (or re-queries) and
/// passes the new rows and the new state back in.
@immutable
class VeloraSortState {
  /// The [VeloraDataColumn.id] of the sorted column.
  final String columnId;

  /// Whether the sort is ascending.
  final bool ascending;

  /// Creates a sort state.
  const VeloraSortState(this.columnId, {this.ascending = true});

  @override
  bool operator ==(Object other) =>
      other is VeloraSortState &&
      other.columnId == columnId &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(columnId, ascending);

  @override
  String toString() =>
      'VeloraSortState($columnId, ${ascending ? 'ascending' : 'descending'})';
}

/// One column of a [VeloraDataTable].
@immutable
class VeloraDataColumn<T> {
  /// Stable identifier, reported back in [VeloraSortState.columnId].
  final String id;

  /// Header text. Also labels the value in the compact (stacked) layout and
  /// in screen-reader announcements.
  final String label;

  /// Builds the cell for [row].
  final Widget Function(T row) cell;

  /// Whether the header offers sorting. Requires
  /// [VeloraDataTable.onSortChanged].
  final bool sortable;

  /// Right-aligns the header and cell, for numbers.
  final bool numeric;

  /// Relative width in the wide layout.
  final int flex;

  /// Creates a column definition.
  const VeloraDataColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.sortable = false,
    this.numeric = false,
    this.flex = 1,
  }) : assert(flex > 0, 'VeloraDataColumn.flex must be positive.');
}

/// A responsive, controlled data table for CRUD and admin screens.
///
/// Presentational only: it does not fetch, sort, filter, or page. The caller
/// owns [rows], [selected], and [sort], and gets told what the user asked
/// for through [onSelectionChanged], [onSortChanged], and [onRowTap].
///
/// **Layouts.** At or above [compactBreakpoint] the table renders a header
/// and one row per item; if the columns need more than the available width
/// (see [minColumnWidth]) the table scrolls horizontally instead of
/// squeezing. Below the breakpoint each row becomes a stacked card with
/// every value labelled, so nothing is clipped on a phone.
///
/// **States.** [error] replaces the body. [loading] with no rows shows
/// skeleton rows; [loading] with rows keeps them visible under a progress
/// bar, so a refresh does not blank the screen. No rows and not loading
/// shows [empty].
///
/// **Keyboard.** Each row is one focus stop. Up/Down move between rows,
/// Enter activates [onRowTap], and Space toggles selection. Sort headers and
/// the select-all checkbox are reachable with Tab.
///
/// **Selection** is by row equality: [selected] should contain the same
/// objects (or `==`-equal ones) that are in [rows]. It may also contain rows
/// that are not on the current page; those are preserved.
///
/// The table lays out every row it is given, so pass one page of rows and
/// put paging controls in [footer] (see `VeloraPagination`).
class VeloraDataTable<T> extends StatefulWidget {
  /// The rows to show, already sorted and paged by the caller.
  final List<T> rows;

  /// Column definitions, in display order.
  final List<VeloraDataColumn<T>> columns;

  /// The currently selected rows.
  final Set<T> selected;

  /// Called with the new selection. When null, the table is not selectable.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// Whether more than one row can be selected. When false, selecting a row
  /// replaces the selection and no select-all checkbox is shown.
  final bool multiSelect;

  /// The current sort, shown in the header.
  final VeloraSortState? sort;

  /// Called with the sort the user asked for.
  final ValueChanged<VeloraSortState>? onSortChanged;

  /// Called when a row is tapped or activated with Enter.
  final ValueChanged<T>? onRowTap;

  /// Builds trailing per-row actions, such as an overflow menu.
  final Widget Function(T row)? rowActions;

  /// Describes a row for screen readers, e.g. `(u) => u.name`. Used in
  /// "Select …" labels.
  final String Function(T row)? rowLabel;

  /// Whether data is being loaded or refreshed.
  final bool loading;

  /// Shown instead of rows when loading failed. Typically a `VeloraAlert`
  /// or a `VeloraEmptyState` with a retry action.
  final Widget? error;

  /// Shown when there are no rows and the table is not loading.
  final Widget? empty;

  /// Shown under the rows. The pagination slot.
  final Widget? footer;

  /// Width below which the stacked card layout is used.
  final double compactBreakpoint;

  /// Minimum width given to each column (times its flex) before the wide
  /// layout scrolls horizontally.
  final double minColumnWidth;

  /// How many skeleton rows to show while loading with no rows.
  final int skeletonRows;

  /// Creates a data table.
  const VeloraDataTable({
    super.key,
    required this.rows,
    required this.columns,
    this.selected = const {},
    this.onSelectionChanged,
    this.multiSelect = true,
    this.sort,
    this.onSortChanged,
    this.onRowTap,
    this.rowActions,
    this.rowLabel,
    this.loading = false,
    this.error,
    this.empty,
    this.footer,
    this.compactBreakpoint = 600,
    this.minColumnWidth = 120,
    this.skeletonRows = 3,
  });

  @override
  State<VeloraDataTable<T>> createState() => _VeloraDataTableState<T>();
}

class _MoveRowIntent extends Intent {
  const _MoveRowIntent(this.delta);
  final int delta;
}

class _ToggleRowIntent extends Intent {
  const _ToggleRowIntent();
}

class _VeloraDataTableState<T> extends State<VeloraDataTable<T>> {
  final List<FocusNode> _rowNodes = [];
  int? _focusedRow;

  bool get _selectable => widget.onSelectionChanged != null;

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(covariant VeloraDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  void _syncNodes() {
    while (_rowNodes.length < widget.rows.length) {
      _rowNodes.add(FocusNode(debugLabel: 'VeloraDataTable row'));
    }
    while (_rowNodes.length > widget.rows.length) {
      _rowNodes.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _rowNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _toggle(T row) {
    final onChanged = widget.onSelectionChanged;
    if (onChanged == null) return;
    final isSelected = widget.selected.contains(row);
    if (!widget.multiSelect) {
      onChanged(isSelected ? <T>{} : <T>{row});
      return;
    }
    final next = Set<T>.of(widget.selected);
    isSelected ? next.remove(row) : next.add(row);
    onChanged(next);
  }

  void _toggleAll() {
    final onChanged = widget.onSelectionChanged;
    if (onChanged == null) return;
    final next = Set<T>.of(widget.selected);
    final allSelected = widget.rows.every(widget.selected.contains);
    allSelected ? next.removeAll(widget.rows) : next.addAll(widget.rows);
    onChanged(next);
  }

  void _requestSort(VeloraDataColumn<T> column) {
    final current = widget.sort;
    final ascending = current?.columnId == column.id
        ? !current!.ascending
        : true;
    widget.onSortChanged?.call(
      VeloraSortState(column.id, ascending: ascending),
    );
  }

  void _moveFocus(int from, int delta) {
    final target = from + delta;
    if (target < 0 || target >= _rowNodes.length) return;
    _rowNodes[target].requestFocus();
  }

  String _describe(T row, int index) =>
      widget.rowLabel?.call(row) ?? 'row ${index + 1}';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < widget.compactBreakpoint;
        final body = _buildBody(context, constraints, compact);
        final footer = widget.footer;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reserve the bar's height so a refresh does not shift rows.
            SizedBox(
              height: 2,
              child: widget.loading && widget.rows.isNotEmpty
                  ? const LinearProgressIndicator(minHeight: 2)
                  : null,
            ),
            body,
            ?footer,
          ],
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    BoxConstraints constraints,
    bool compact,
  ) {
    final tokens = context.veloraTokens;
    final error = widget.error;
    if (error != null) {
      return Padding(padding: EdgeInsets.all(tokens.spacingMd), child: error);
    }
    if (widget.rows.isEmpty) {
      if (widget.loading) {
        return Semantics(
          label: 'Loading',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.skeletonRows; i++)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spacingMd,
                    vertical: tokens.spacingSm,
                  ),
                  child: const VeloraSkeleton(height: 20),
                ),
            ],
          ),
        );
      }
      final empty = widget.empty;
      return Padding(
        padding: EdgeInsets.all(tokens.spacingLg),
        child:
            empty ??
            Text(
              'No results',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
      );
    }
    return compact ? _buildCards(context) : _buildWide(context, constraints);
  }

  // --- Wide layout ---------------------------------------------------------

  Widget _buildWide(BuildContext context, BoxConstraints constraints) {
    final scheme = Theme.of(context).colorScheme;
    final totalFlex = widget.columns.fold<int>(0, (sum, c) => sum + c.flex);
    final needed =
        totalFlex * widget.minColumnWidth +
        (_selectable ? 56 : 0) +
        (widget.rowActions != null ? 56 : 0);
    final available = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : needed;

    final table = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        Divider(height: 1, color: scheme.outlineVariant),
        for (var i = 0; i < widget.rows.length; i++) ...[
          _buildRow(context, i, compact: false),
          if (i < widget.rows.length - 1)
            Divider(height: 1, color: scheme.outlineVariant),
        ],
      ],
    );

    if (needed <= available) return table;
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: needed, child: table),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: scheme.onSurfaceVariant);
    final allSelected =
        widget.rows.isNotEmpty && widget.rows.every(widget.selected.contains);
    final someSelected = widget.rows.any(widget.selected.contains);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          if (_selectable)
            SizedBox(
              width: 56,
              child: widget.multiSelect
                  ? Checkbox(
                      value: allSelected ? true : (someSelected ? null : false),
                      tristate: true,
                      onChanged: (_) => _toggleAll(),
                      semanticLabel: 'Select all rows',
                    )
                  : null,
            ),
          for (final column in widget.columns)
            Expanded(
              flex: column.flex,
              child: _buildHeaderCell(context, column, style),
            ),
          if (widget.rowActions != null) const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    VeloraDataColumn<T> column,
    TextStyle? style,
  ) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final sorted = widget.sort?.columnId == column.id;
    final canSort = column.sortable && widget.onSortChanged != null;
    final alignment = column.numeric
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacingSm,
        vertical: tokens.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          Flexible(
            child: Text(
              column.label,
              style: style?.copyWith(color: sorted ? scheme.primary : null),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canSort) ...[
            SizedBox(width: tokens.spacingXs),
            Icon(
              sorted
                  ? (widget.sort!.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 16,
              color: sorted ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );

    if (!canSort) {
      return Semantics(header: true, child: content);
    }
    final direction = sorted
        ? (widget.sort!.ascending ? 'sorted ascending' : 'sorted descending')
        : 'not sorted';
    return Semantics(
      container: true,
      header: true,
      button: true,
      label: '${column.label}, $direction',
      onTap: () => _requestSort(column),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _requestSort(column),
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: content,
      ),
    );
  }

  // --- Rows (both layouts) -------------------------------------------------

  Widget _buildRow(BuildContext context, int index, {required bool compact}) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final row = widget.rows[index];
    final isSelected = widget.selected.contains(row);
    final focused = _focusedRow == index;
    final onRowTap = widget.onRowTap;
    final VoidCallback? onTap = onRowTap != null
        ? () => onRowTap(row)
        : (_selectable ? () => _toggle(row) : null);

    final checkbox = _selectable
        ? ExcludeFocus(
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => _toggle(row),
              semanticLabel: 'Select ${_describe(row, index)}',
            ),
          )
        : null;
    final actions = widget.rowActions?.call(row);

    final Widget content = compact
        ? _buildCardContent(context, row, checkbox, actions)
        : ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                if (checkbox != null) SizedBox(width: 56, child: checkbox),
                for (final column in widget.columns)
                  Expanded(
                    flex: column.flex,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacingSm,
                        vertical: tokens.spacingSm,
                      ),
                      child: Align(
                        alignment: column.numeric
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: column.cell(row),
                      ),
                    ),
                  ),
                if (widget.rowActions != null)
                  SizedBox(width: 56, child: Center(child: actions)),
              ],
            ),
          );

    final radius = BorderRadius.circular(
      compact ? tokens.radiusMd : tokens.radiusSm,
    );
    final decorated = DecoratedBox(
      // Painted above the row so the focus ring is never hidden by a cell.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: focused ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.4)
            : (compact ? scheme.surfaceContainerLow : Colors.transparent),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          focusNode: _rowNodes[index],
          onTap: onTap,
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              setState(() => _focusedRow = index);
            } else if (_focusedRow == index) {
              setState(() => _focusedRow = null);
            }
          },
          child: content,
        ),
      ),
    );

    return Semantics(
      container: true,
      selected: _selectable ? isSelected : null,
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _MoveRowIntent(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _MoveRowIntent(-1),
          if (_selectable)
            const SingleActivator(LogicalKeyboardKey.space):
                const _ToggleRowIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _MoveRowIntent: CallbackAction<_MoveRowIntent>(
              onInvoke: (intent) => _moveFocus(index, intent.delta),
            ),
            _ToggleRowIntent: CallbackAction<_ToggleRowIntent>(
              onInvoke: (_) => _toggle(row),
            ),
          },
          child: decorated,
        ),
      ),
    );
  }

  // --- Compact layout ------------------------------------------------------

  Widget _buildCards(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final List<VeloraDataColumn<T>> sortable = widget.onSortChanged == null
        ? []
        : widget.columns.where((c) => c.sortable).toList();
    final showToolbar =
        sortable.isNotEmpty || (_selectable && widget.multiSelect);
    final allSelected = widget.rows.every(widget.selected.contains);
    final someSelected = widget.rows.any(widget.selected.contains);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showToolbar)
          Row(
            children: [
              if (_selectable && widget.multiSelect)
                Checkbox(
                  value: allSelected ? true : (someSelected ? null : false),
                  tristate: true,
                  onChanged: (_) => _toggleAll(),
                  semanticLabel: 'Select all rows',
                ),
              const Spacer(),
              if (sortable.isNotEmpty)
                PopupMenuButton<String>(
                  tooltip: 'Sort',
                  icon: Icon(Icons.sort, color: scheme.onSurfaceVariant),
                  onSelected: (id) =>
                      _requestSort(sortable.firstWhere((c) => c.id == id)),
                  itemBuilder: (context) => [
                    for (final column in sortable)
                      CheckedPopupMenuItem<String>(
                        value: column.id,
                        checked: widget.sort?.columnId == column.id,
                        child: Text(
                          widget.sort?.columnId == column.id
                              ? '${column.label} '
                                    '(${widget.sort!.ascending ? 'ascending' : 'descending'})'
                              : column.label,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        for (var i = 0; i < widget.rows.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spacingSm),
            child: _buildRow(context, i, compact: true),
          ),
      ],
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    T row,
    Widget? checkbox,
    Widget? actions,
  ) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: scheme.onSurfaceVariant);

    return Padding(
      padding: EdgeInsets.all(tokens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?checkbox,
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacingSm,
                vertical: tokens.spacingXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < widget.columns.length; i++) ...[
                    if (i > 0) SizedBox(height: tokens.spacingSm),
                    Text(widget.columns[i].label, style: labelStyle),
                    SizedBox(height: tokens.spacingXs / 2),
                    widget.columns[i].cell(row),
                  ],
                ],
              ),
            ),
          ),
          ?actions,
        ],
      ),
    );
  }
}

/// Previous/next paging controls for a [VeloraDataTable.footer].
///
/// Controlled: shows [page] of [pageCount] and reports the page the user
/// asked for. The caller loads that page and passes the new [page] back.
class VeloraPagination extends StatelessWidget {
  /// The current page, starting at 1.
  final int page;

  /// The total number of pages.
  final int pageCount;

  /// Called with the requested page. When null, both buttons are disabled.
  final ValueChanged<int>? onPageChanged;

  /// Creates pagination controls.
  const VeloraPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
  }) : assert(page >= 1, 'VeloraPagination.page starts at 1.'),
       assert(pageCount >= 1, 'VeloraPagination.pageCount must be >= 1.');

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final scheme = Theme.of(context).colorScheme;
    final onChanged = onPageChanged;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              'Page $page of $pageCount',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          SizedBox(width: tokens.spacingSm),
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Icons.chevron_left),
            onPressed: onChanged != null && page > 1
                ? () => onChanged(page - 1)
                : null,
          ),
          IconButton(
            tooltip: 'Next page',
            icon: const Icon(Icons.chevron_right),
            onPressed: onChanged != null && page < pageCount
                ? () => onChanged(page + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
