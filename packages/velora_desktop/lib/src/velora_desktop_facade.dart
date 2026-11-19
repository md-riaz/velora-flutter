import 'dart:async';

import 'package:velora/velora.dart';

import 'desktop_event.dart';
import 'desktop_service.dart';

/// Package-level facade for the service `VeloraDesktopPlugin` registers.
/// Kept out of core `Velora` so the framework stays agnostic of this plugin.
class VeloraDesktop {
  const VeloraDesktop._();

  static VeloraDesktopService get service => Get.find<VeloraDesktopService>();

  static Stream<VeloraDesktopEvent> get events => service.events;

  static VeloraDesktopCapabilities get capabilities => service.capabilities;

  static Future<void> show() => service.show();

  static Future<void> hide() => service.hide();

  static Future<void> quit() => service.quit();

  static void reportNotificationActivation({
    required String id,
    Map<String, Object?> data = const {},
  }) => service.reportNotificationActivation(id: id, data: data);

  static Future<void> setTrayIcon(String assetPath) =>
      service.setTrayIcon(assetPath);

  static Future<void> setTrayTooltip(String? tooltip) =>
      service.setTrayTooltip(tooltip);

  static Future<void> setTrayMenuItems(List<VeloraTrayMenuItem> items) =>
      service.setTrayMenuItems(items);
}
