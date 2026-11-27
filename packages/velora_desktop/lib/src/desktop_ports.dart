/// The seams between [VeloraDesktopCoordinator] and the platform. Each port
/// is implemented once over a desktop package and once as a fake; none of
/// them exposes a package type.
library;

import 'dart:ui';

import 'desktop_service.dart';

/// A window's position and size in screen coordinates.
class WindowBounds {
  const WindowBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory WindowBounds.fromJson(Map<String, Object?> json) => WindowBounds(
    x: (json['x']! as num).toDouble(),
    y: (json['y']! as num).toDouble(),
    width: (json['width']! as num).toDouble(),
    height: (json['height']! as num).toDouble(),
  );

  final double x;
  final double y;
  final double width;
  final double height;

  Map<String, Object?> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  @override
  bool operator ==(Object other) =>
      other is WindowBounds &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'WindowBounds($x, $y, $width x $height)';
}

/// The app's main window.
abstract interface class VeloraDesktopWindowPort {
  /// Starts intercepting close requests. Returns `false` when the platform has
  /// no window (e.g. headless or test). [onCloseRequested] returns whether
  /// the window may close.
  Future<bool> attach({required bool Function() onCloseRequested});

  Future<void> show({required bool focus});

  Future<void> hide();

  Future<void> setMinimumSize(Size size);

  Future<void> setSize(Size size);

  Future<void> setTitleBarStyle(VeloraTitleBarStyle style);

  Future<void> setWindowButtonVisibility(bool visible);

  /// Asks the window to close; [attach]'s callback still decides.
  Future<void> close();

  Future<void> detach();

  /// The window's current bounds, or `null` when unavailable.
  Future<WindowBounds?> getBounds();

  Future<void> setBounds(WindowBounds bounds);
}

/// Small string key-value storage, used to remember the window bounds.
abstract interface class VeloraDesktopStoragePort {
  Future<String?> get(String key);

  Future<void> set(String key, String value);
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

  /// Replaces the tray icon image. [assetPath] is a Flutter asset path.
  Future<void> setIcon(String assetPath);

  /// Updates the hover tooltip.
  Future<void> setTooltip(String? tooltip);

  /// Rebuilds the context menu with custom items between Show and Quit.
  Future<void> setMenuItems({
    required String showLabel,
    required String quitLabel,
    required List<VeloraTrayMenuItem> items,
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
