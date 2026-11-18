import 'package:velora/velora.dart';

import 'desktop_service.dart';

/// Carries [VeloraDesktopConfig] on [VeloraConfig.extensions] so
/// `VeloraDesktopPlugin()` can be constructed without repeating it.
class VeloraDesktopConfigExtension extends VeloraConfigExtension {
  const VeloraDesktopConfigExtension(
    this.config, {
    this.windowsNotificationGuid,
    this.windowsAppUserModelId,
  });

  final VeloraDesktopConfig config;

  /// COM activator CLSID Windows uses to route toast activations back to this
  /// app.
  final String? windowsNotificationGuid;

  /// Identity of the app in Windows notifications and the Start menu.
  final String? windowsAppUserModelId;
}
