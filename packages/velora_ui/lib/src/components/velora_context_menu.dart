import 'package:flutter/material.dart';

/// A unified right-click (`onSecondaryTapDown`) and touch long-press
/// (`onLongPressStart`) context menu wrapper.
///
/// Uses [showMenu] positioned against `Overlay.of(context)` so the menu anchors
/// accurately to the pointer or touch coordinates at any window width.
class ContextMenuRegion<T> extends StatelessWidget {
  /// The widget that triggers the context menu on secondary tap or long press.
  final Widget child;

  /// Static menu entries to display. Provide either [items] or [itemBuilder].
  final List<PopupMenuEntry<T>>? items;

  /// Lazy menu entry builder, called when the menu opens. Takes precedence
  /// over [items] if both are provided.
  final List<PopupMenuEntry<T>> Function(BuildContext context)? itemBuilder;

  /// Called when the user selects a menu item.
  final ValueChanged<T>? onSelected;

  /// Called when the menu is dismissed without selecting an item.
  final VoidCallback? onCanceled;

  /// Whether context menu gestures are active. Defaults to `true`.
  final bool enabled;

  /// Creates a context menu region.
  const ContextMenuRegion({
    super.key,
    required this.child,
    this.items,
    this.itemBuilder,
    this.onSelected,
    this.onCanceled,
    this.enabled = true,
  }) : assert(
         items != null || itemBuilder != null,
         'ContextMenuRegion requires either items or itemBuilder.',
       );

  Future<void> _showAt(BuildContext context, Offset globalPosition) async {
    if (!enabled) return;
    final menuItems = itemBuilder?.call(context) ?? items ?? const [];
    if (menuItems.isEmpty) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final localPosition = overlay.globalToLocal(globalPosition);
    final position = RelativeRect.fromRect(
      Rect.fromPoints(localPosition, localPosition),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<T>(
      context: context,
      position: position,
      items: menuItems,
    );
    if (selected != null) {
      onSelected?.call(selected);
    } else {
      onCanceled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapDown: enabled
          ? (details) => _showAt(context, details.globalPosition)
          : null,
      onLongPressStart: enabled
          ? (details) => _showAt(context, details.globalPosition)
          : null,
      child: child,
    );
  }
}
