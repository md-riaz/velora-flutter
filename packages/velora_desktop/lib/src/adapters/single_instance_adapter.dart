import 'dart:io';

import 'package:windows_single_instance/windows_single_instance.dart';

import '../desktop_ports.dart';

/// [VeloraDesktopSingleInstancePort] over `windows_single_instance`.
class WindowsSingleInstanceAdapter implements VeloraDesktopSingleInstancePort {
  @override
  Future<bool> ensure({
    required String appId,
    required List<String> arguments,
    required void Function(List<String> arguments) onSecondaryLaunch,
  }) async {
    if (!Platform.isWindows) return false;
    await WindowsSingleInstance.ensureSingleInstance(
      arguments,
      appId,
      onSecondWindow: onSecondaryLaunch,
    );
    return true;
  }
}
