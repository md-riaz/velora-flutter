/// The seams between [VeloraDesktopCoordinator] and the platform. Each port
/// is implemented once over a desktop package and once as a fake; none of
/// them exposes a package type.
library;

import 'desktop_service.dart';

/// The app's main window.
abstract interface class VeloraDesktopWindowPort {
  /// Starts intercepting close requests. Returns `false` when the platform has
  /// no window (e.g. headless or test). [onCloseRequested] returns whether
  /// the window may close.
  Future<bool> attach({required bool Function() onCloseRequested});

  Future<void> show({required bool focus});

  Future<void> hide();

  /// Asks the window to close; [attach]'s callback still decides.
  Future<void> close();

  Future<void> detach();
}

/// The tray icon.
abstract interface class VeloraDesktopTrayPort {
  /// Creates the icon and its menu. Returns `false` when the platform has no
  /// tray.
  Future<bool> setup({
    required VeloraTrayConfig config,
    required void Function() onActivate,
    required void Function() onShow,
    required void Function() onQuit,
  });

  Future<void> dispose();
}

/// Launching the app at login.
abstract interface class VeloraDesktopAutoStartPort {
  /// Prepares the entry. Returns `false` when the platform cannot do it.
  Future<bool> setup({
    required String appId,
    required String appName,
    required List<String> arguments,
  });

  Future<void> setEnabled(bool enabled);

  Future<bool> isEnabled();
}

/// One running copy of the app.
abstract interface class VeloraDesktopSingleInstancePort {
  /// Claims the primary role. In a second copy this hands [arguments] to the
  /// primary and ends the process. Returns `false` when unsupported.
  Future<bool> ensure({
    required String appId,
    required List<String> arguments,
    required void Function(List<String> arguments) onSecondaryLaunch,
  });
}

/// Links that open the app.
abstract interface class VeloraDesktopLinkPort {
  /// The link that started the app, if any.
  Future<Uri?> initialLink();

  /// Links received while running.
  Stream<Uri> get links;
}

/// A change in the system's power state.
enum VeloraPowerSignal { suspending, resumed }

/// Sleep and wake notifications.
abstract interface class VeloraDesktopPowerPort {
  /// Starts listening. Returns `false` when unsupported.
  Future<bool> start();

  Stream<VeloraPowerSignal> get signals;

  Future<void> stop();
}
