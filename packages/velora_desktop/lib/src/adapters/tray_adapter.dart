import 'package:nativeapi/nativeapi.dart' as nativeapi;
import 'package:nativeapi_flutter/nativeapi_flutter.dart' show ImageAsset;

import '../desktop_ports.dart';
import '../desktop_service.dart';

/// [VeloraDesktopTrayPort] over nativeapi [nativeapi.TrayIcon].
///
/// tray_manager 0.8 re-exports nativeapi types — we go through nativeapi
/// directly for the same reason as the window adapter.
class TrayManagerAdapter implements VeloraDesktopTrayPort {
  TrayManagerAdapter();

  nativeapi.TrayIcon? _icon;
  nativeapi.ListenerId? _listenerId;

  @override
  Future<void> setIcon(String assetPath) async {
    _icon?.icon = ImageAsset.fromAsset(assetPath);
  }

  @override
  Future<void> setTooltip(String? tooltip) async {
    _icon?.setTooltip(tooltip);
  }

  @override
  Future<void> setMenuItems({
    required String showLabel,
    required String quitLabel,
    required List<VeloraTrayMenuItem> items,
    required void Function() onShow,
    required void Function() onQuit,
  }) async {
    final icon = _icon;
    if (icon == null) return;

    final menu = nativeapi.Menu.create();
    if (menu == null) return;

    final showItem = nativeapi.MenuItem.createWithLabelAndType(
      showLabel,
      nativeapi.MenuItemType.normal,
    );
    showItem?.addListener((event) {
      if (event is nativeapi.MenuItemClickedEvent) onShow();
    });
    if (showItem != null) menu.addItem(showItem);

    if (items.isNotEmpty) {
      final sep = nativeapi.MenuItem.createWithLabelAndType(
        '',
        nativeapi.MenuItemType.separator,
      );
      if (sep != null) menu.addItem(sep);

      for (final item in items) {
        final type = item.checked != null
            ? nativeapi.MenuItemType.checkbox
            : nativeapi.MenuItemType.normal;
        final native = nativeapi.MenuItem.createWithLabelAndType(
          item.label,
          type,
        );
        if (native == null) continue;
        native.isEnabled = item.enabled;
        if (item.checked != null) {
          native.state = item.checked!
              ? nativeapi.MenuItemState.checked
              : nativeapi.MenuItemState.unchecked;
        }
        final onTap = item.onTap;
        if (onTap != null) {
          native.addListener((event) {
            if (event is nativeapi.MenuItemClickedEvent) onTap();
          });
        }
        menu.addItem(native);
      }
    }

    final quitSep = nativeapi.MenuItem.createWithLabelAndType(
      '',
      nativeapi.MenuItemType.separator,
    );
    if (quitSep != null) menu.addItem(quitSep);

    final quitItem = nativeapi.MenuItem.createWithLabelAndType(
      quitLabel,
      nativeapi.MenuItemType.normal,
    );
    quitItem?.addListener((event) {
      if (event is nativeapi.MenuItemClickedEvent) onQuit();
    });
    if (quitItem != null) menu.addItem(quitItem);

    icon.setContextMenu(menu);
  }

  @override
  Future<bool> setup({
    required VeloraTrayConfig config,
    required void Function() onActivate,
    required void Function() onShow,
    required void Function() onQuit,
  }) async {
    _icon = nativeapi.TrayIcon.create();
    if (_icon == null) return false;

    _icon!.icon = ImageAsset.fromAsset(config.iconAsset);
    if (config.tooltip != null) _icon!.setTooltip(config.tooltip);

    final showItem = nativeapi.MenuItem.createWithLabelAndType(
      config.showLabel,
      nativeapi.MenuItemType.normal,
    );
    final separator = nativeapi.MenuItem.createWithLabelAndType(
      '',
      nativeapi.MenuItemType.separator,
    );
    final quitItem = nativeapi.MenuItem.createWithLabelAndType(
      config.quitLabel,
      nativeapi.MenuItemType.normal,
    );
    final menu = nativeapi.Menu.create();
    if (menu == null || showItem == null || quitItem == null) return false;

    showItem.addListener((event) {
      if (event is nativeapi.MenuItemClickedEvent) onShow();
    });
    quitItem.addListener((event) {
      if (event is nativeapi.MenuItemClickedEvent) onQuit();
    });
    menu.addItem(showItem);
    if (separator != null) menu.addItem(separator);
    menu.addItem(quitItem);
    _icon!.setContextMenu(menu);
    _icon!.setContextMenuTrigger(nativeapi.ContextMenuTrigger.rightClicked);

    _listenerId = _icon!.addListener((event) {
      if (event is nativeapi.TrayIconClickedEvent ||
          event is nativeapi.TrayIconDoubleClickedEvent) {
        onActivate();
      }
    });

    return true;
  }

  @override
  Future<void> dispose() async {
    final icon = _icon;
    if (icon == null) return;
    final id = _listenerId;
    if (id != null) icon.removeListener(id);
    icon.dispose();
    _icon = null;
  }
}
