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
