import 'dart:async';
import 'dart:io';

import 'package:velora/velora.dart';

import 'adapters/auto_start_adapter.dart';
import 'adapters/link_adapter.dart';
import 'adapters/power_adapter.dart';
import 'adapters/single_instance_adapter.dart';
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
      service = VeloraDesktopCoordinator(
        config: resolved,
        window: WindowManagerAdapter(),
        tray: TrayManagerAdapter(),
        autoStart: NativeApiAutoStartAdapter(),
        singleInstance: WindowsSingleInstanceAdapter(),
        links: AppLinksAdapter(),
        power: PowerStateMonitorAdapter(),
      );
    } else {
      service = _InertDesktopService();
    }

    context.put<VeloraDesktopService>(service);
    await service.initialize();

    context.onBeforeLogout(service.dispose);
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
  Future<void> setAutoStart(bool enabled) async {
    throw UnsupportedError('Auto-start is not available on this platform.');
  }

  @override
  Future<bool> isAutoStartEnabled() async => false;

  @override
  Future<void> dispose() => _events.close();
}
