import 'package:nativeapi/nativeapi.dart' as nativeapi;

import '../desktop_ports.dart';

/// [VeloraDesktopAutoStartPort] over nativeapi's [nativeapi.LaunchAtLogin].
///
/// Uses nativeapi instead of `launch_at_startup` to avoid the win32 ^5 vs ^6
/// conflict with `flutter_secure_storage`.
class NativeApiAutoStartAdapter implements VeloraDesktopAutoStartPort {
  NativeApiAutoStartAdapter();

  nativeapi.LaunchAtLogin? _launcher;

  @override
  Future<bool> setup({
    required String appId,
    required String appName,
    required List<String> arguments,
  }) async {
    try {
      _launcher = nativeapi.LaunchAtLogin.createWithIdAndDisplayName(
        appId,
        appName,
      );
      return _launcher != null;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final launcher = _launcher;
    if (launcher == null) throw UnsupportedError('Auto-start not set up.');
    if (enabled) {
      launcher.enable();
    } else {
      launcher.disable();
    }
  }

  @override
  Future<bool> isEnabled() async {
    final launcher = _launcher;
    if (launcher == null) return false;
    return launcher.isEnabled;
  }
}
