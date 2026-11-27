/// In-memory fakes of every port, for unit-testing the coordinator without
/// any desktop package.
library;

import 'dart:async';
import 'dart:ui';

import 'desktop_ports.dart';
import 'desktop_service.dart';

/// In-memory [VeloraDesktopWindowPort].
class FakeWindowPort implements VeloraDesktopWindowPort {
  bool attached = false;
  bool visible = true;
  bool focused = true;
  bool closed = false;
  bool Function()? onCloseRequested;
  WindowBounds? currentBounds;
  Size? minimumSize;
  Size? size;
  VeloraTitleBarStyle titleBarStyle = VeloraTitleBarStyle.normal;
  bool windowButtonVisibility = true;

  /// Set to `false` before [attach] to simulate a platform without a window.
  bool supported = true;

  @override
  Future<bool> attach({required bool Function() onCloseRequested}) async {
    if (!supported) return false;
    attached = true;
    this.onCloseRequested = onCloseRequested;
    return true;
  }

  @override
  Future<void> show({required bool focus}) async {
    visible = true;
    if (focus) focused = true;
  }

  @override
  Future<void> hide() async {
    visible = false;
    focused = false;
  }

  @override
  Future<void> setMinimumSize(Size size) async => minimumSize = size;

  @override
  Future<void> setSize(Size size) async => this.size = size;

  @override
  Future<void> setTitleBarStyle(VeloraTitleBarStyle style) async {
    titleBarStyle = style;
  }

  @override
  Future<void> setWindowButtonVisibility(bool visible) async {
    windowButtonVisibility = visible;
  }

  @override
  Future<void> close() async {
    final mayClose = onCloseRequested?.call() ?? true;
    if (mayClose) closed = true;
  }

  @override
  Future<WindowBounds?> getBounds() async => currentBounds;

  @override
  Future<void> setBounds(WindowBounds bounds) async => currentBounds = bounds;

  @override
  Future<void> detach() async {
    onCloseRequested = null;
    attached = false;
  }
}

/// In-memory [VeloraDesktopStoragePort].
class FakeDesktopStoragePort implements VeloraDesktopStoragePort {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async => values[key] = value;
}

/// In-memory [VeloraDesktopTrayPort].
class FakeTrayPort implements VeloraDesktopTrayPort {
  bool ready = false;
  bool disposed = false;
  void Function()? onActivate;
  void Function()? onShow;
  void Function()? onQuit;

  /// Set to `false` before [setup] to simulate a platform without tray.
  bool supported = true;

  String? iconAsset;
  String? tooltip;
  List<VeloraTrayMenuItem> menuItems = [];
  void Function()? menuOnShow;
  void Function()? menuOnQuit;

  @override
  Future<void> setIcon(String assetPath) async {
    iconAsset = assetPath;
  }

  @override
  Future<void> setTooltip(String? tooltip) async {
    this.tooltip = tooltip;
  }

  @override
  Future<void> setMenuItems({
    required String showLabel,
    required String quitLabel,
    required List<VeloraTrayMenuItem> items,
    required void Function() onShow,
    required void Function() onQuit,
  }) async {
    menuItems = items;
    menuOnShow = onShow;
    menuOnQuit = onQuit;
  }

  @override
  Future<bool> setup({
    required VeloraTrayConfig config,
    required void Function() onActivate,
    required void Function() onShow,
    required void Function() onQuit,
  }) async {
    if (!supported) return false;
    ready = true;
    this.onActivate = onActivate;
    this.onShow = onShow;
    this.onQuit = onQuit;
    return true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    ready = false;
  }
}

/// In-memory [VeloraDesktopAutoStartPort].
class FakeAutoStartPort implements VeloraDesktopAutoStartPort {
  bool ready = false;
  bool enabled = false;
  bool supported = true;

  @override
  Future<bool> setup({
    required String appId,
    required String appName,
    required List<String> arguments,
  }) async {
    if (!supported) return false;
    ready = true;
    return true;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    this.enabled = enabled;
  }

  @override
  Future<bool> isEnabled() async => enabled;
}

/// In-memory [VeloraDesktopSingleInstancePort].
class FakeSingleInstancePort implements VeloraDesktopSingleInstancePort {
  bool claimed = false;
  bool supported = true;
  void Function(List<String>)? onSecondaryLaunch;

  @override
  Future<bool> ensure({
    required String appId,
    required List<String> arguments,
    required void Function(List<String> arguments) onSecondaryLaunch,
  }) async {
    if (!supported) return false;
    claimed = true;
    this.onSecondaryLaunch = onSecondaryLaunch;
    return true;
  }
}

/// In-memory [VeloraDesktopLinkPort].
class FakeLinkPort implements VeloraDesktopLinkPort {
  FakeLinkPort({this.initial});

  final Uri? initial;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> initialLink() async => initial;

  @override
  Stream<Uri> get links => _controller.stream;

  void add(Uri uri) => _controller.add(uri);

  Future<void> dispose() => _controller.close();
}

/// In-memory [VeloraDesktopPowerPort].
class FakePowerPort implements VeloraDesktopPowerPort {
  bool started = false;
  bool supported = true;
  final StreamController<VeloraPowerSignal> _controller =
      StreamController<VeloraPowerSignal>.broadcast();

  @override
  Future<bool> start() async {
    if (!supported) return false;
    started = true;
    return true;
  }

  @override
  Stream<VeloraPowerSignal> get signals => _controller.stream;

  void add(VeloraPowerSignal signal) => _controller.add(signal);

  @override
  Future<void> stop() async {
    started = false;
    await _controller.close();
  }
}
