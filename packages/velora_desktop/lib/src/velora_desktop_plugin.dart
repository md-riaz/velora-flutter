import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart';

import 'adapters/auto_start_adapter.dart';
import 'adapters/link_adapter.dart';
import 'adapters/power_adapter.dart';
import 'adapters/single_instance_adapter.dart';
import 'adapters/storage_adapter.dart';
import 'adapters/tray_adapter.dart';
import 'adapters/window_adapter.dart';
import 'desktop_config_extension.dart';
import 'desktop_coordinator.dart';
import 'desktop_event.dart';
import 'desktop_service.dart';

/// Wires desktop lifecycle (close-to-tray, single instance, protocol links,
/// auto-start, power events) into a Velora app.
///
/// ```dart
/// await Velora.boot(
///   config: myConfig,
///   plugins: [VeloraDesktopPlugin(config: desktopConfig)],
/// );
/// ```
///
/// Without [config], the plugin reads [VeloraDesktopConfigExtension] from
/// [VeloraConfig.extensions]. On non-desktop platforms an inert service is
/// registered so [VeloraDesktop] calls stay safe.
class VeloraDesktopPlugin extends VeloraPlugin {
  const VeloraDesktopPlugin({this.config});

  final VeloraDesktopConfig? config;

  @override
  String get name => 'velora_desktop';

  @override
  Future<void> register(VeloraContext context) async {
    final VeloraDesktopService service;
    if (_isDesktop) {
      final resolved =
          config ??
          context.configExtension<VeloraDesktopConfigExtension>()?.config;
      if (resolved == null) {
        throw StateError(
          'VeloraDesktopPlugin needs a VeloraDesktopConfig, passed directly '
          'or as a VeloraDesktopConfigExtension on VeloraConfig.extensions.',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      service = VeloraDesktopCoordinator(
        config: resolved,
        window: WindowManagerAdapter(),
        tray: TrayManagerAdapter(),
        autoStart: NativeApiAutoStartAdapter(),
        singleInstance: WindowsSingleInstanceAdapter(),
        storage: SharedPreferencesStorageAdapter(prefs),
        links: AppLinksAdapter(),
        power: PowerStateMonitorAdapter(),
      );
    } else {
      service = _InertDesktopService();
    }

    context.put<VeloraDesktopService>(service);
    // The desktop service is app-wide (tray, window, protocol links), not
    // user-scoped, so it is intentionally not disposed on logout: it could not
    // be revived after re-login.
    await service.initialize();
  }

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

class _InertDesktopService implements VeloraDesktopService {
  final _events = StreamController<VeloraDesktopEvent>.broadcast();

  @override
  Stream<VeloraDesktopEvent> get events => _events.stream;

  @override
  VeloraDesktopCapabilities get capabilities =>
      const VeloraDesktopCapabilities();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show({bool focus = true}) async {}

  @override
  Future<void> hide() async {}

  @override
  Future<void> quit() async {}

  @override
  void reportNotificationActivation({
    required String id,
    Map<String, Object?> data = const {},
  }) {
    // No-op on non-desktop platforms.
  }

  @override
  Future<void> setAutoStart(bool enabled) async {
    throw UnsupportedError('Auto-start is not available on this platform.');
  }

  @override
  Future<bool> isAutoStartEnabled() async => false;

  @override
  Future<void> setTrayIcon(String assetPath) async {
    throw UnsupportedError('Tray is not available on this platform.');
  }

  @override
  Future<void> setTrayTooltip(String? tooltip) async {
    throw UnsupportedError('Tray is not available on this platform.');
  }

  @override
  Future<void> setTrayMenuItems(List<VeloraTrayMenuItem> items) async {
    throw UnsupportedError('Tray is not available on this platform.');
  }

  @override
  Future<void> dispose() => _events.close();
}
