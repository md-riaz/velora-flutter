import 'dart:async';

import 'desktop_event.dart';
import 'desktop_ports.dart';
import 'desktop_service.dart';

/// The policy behind [VeloraDesktopService]: it owns no native code and
/// decides only what the ports are asked to do and which events are reported.
///
/// - The window hides to the tray on close only when the tray icon exists.
/// - [quit] always closes.
/// - Activating the tray icon, its Show entry, or a second launch restores
///   and focuses the window.
/// - Cold-start links, links received while running, second launches, and
///   notification activations share one stream, and the same activation
///   delivered twice within [VeloraDesktopConfig.deduplicationWindow] is
///   reported once.
/// - A wake is reported once per sleep.
class VeloraDesktopCoordinator implements VeloraDesktopService {
  VeloraDesktopCoordinator({
    required this.config,
    required VeloraDesktopWindowPort window,
    VeloraDesktopTrayPort? tray,
    VeloraDesktopAutoStartPort? autoStart,
    VeloraDesktopSingleInstancePort? singleInstance,
    VeloraDesktopLinkPort? links,
    VeloraDesktopPowerPort? power,
    DateTime Function() now = DateTime.now,
  }) : _window = window,
       _tray = tray,
       _autoStart = autoStart,
       _singleInstance = singleInstance,
       _links = links,
       _power = power,
       _now = now;

  final VeloraDesktopConfig config;
  final VeloraDesktopWindowPort _window;
  final VeloraDesktopTrayPort? _tray;
  final VeloraDesktopAutoStartPort? _autoStart;
  final VeloraDesktopSingleInstancePort? _singleInstance;
  final VeloraDesktopLinkPort? _links;
  final VeloraDesktopPowerPort? _power;
  final DateTime Function() _now;

  late final StreamController<VeloraDesktopEvent> _events =
      StreamController<VeloraDesktopEvent>.broadcast(onListen: _flush);
  final List<VeloraDesktopEvent> _pending = [];
  final Map<String, DateTime> _seen = {};
  final List<StreamSubscription<Object?>> _subscriptions = [];

  VeloraDesktopCapabilities _capabilities = const VeloraDesktopCapabilities();
  Future<void>? _initializing;
  bool _trayReady = false;
  bool _quitting = false;
  bool _asleep = false;
  bool _disposed = false;

  @override
  Stream<VeloraDesktopEvent> get events => _events.stream;

  @override
  VeloraDesktopCapabilities get capabilities => _capabilities;

  @override
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    final problems = <String, String>{};
    Future<bool> attempt(String name, Future<bool> Function() body) async {
      try {
        final ok = await body();
        if (!ok) problems[name] = 'Not supported on this platform.';
        return ok;
      } on Object catch (error) {
        problems[name] = '$error';
        return false;
      }
    }

    // First, so a second copy exits before it creates a tray icon or window
    // listeners of its own.
    final singleInstancePort = _singleInstance;
    final singleInstance =
        config.singleInstance &&
        singleInstancePort != null &&
        await attempt(
          'singleInstance',
          () => singleInstancePort.ensure(
            appId: config.appId,
            arguments: config.launchArguments,
            onSecondaryLaunch: _onSecondaryLaunch,
          ),
        );

    final window = await attempt('window', () async {
      await _window.attach(onCloseRequested: _onCloseRequested);
      return true;
    });

    final trayPort = _tray;
    final trayConfig = config.tray;
    _trayReady =
        trayPort != null &&
        trayConfig != null &&
        await attempt(
          'tray',
          () => trayPort.setup(
            config: trayConfig,
            onActivate: () => unawaited(show()),
            onShow: () => unawaited(show()),
            onQuit: () => unawaited(quit()),
          ),
        );

    final autoStartPort = _autoStart;
    final autoStart =
        autoStartPort != null &&
        await attempt(
          'autoStart',
          () => autoStartPort.setup(
            appId: config.appId,
            appName: config.appName,
            arguments: [config.autoStartArgument],
          ),
        );

    final powerPort = _power;
    final power =
        powerPort != null &&
        await attempt('powerEvents', () async {
          if (!await powerPort.start()) return false;
          _subscriptions.add(powerPort.signals.listen(_onPowerSignal));
          return true;
        });

    final linkPort = _links;
    final links =
        linkPort != null &&
        await attempt('protocolLinks', () async {
          _subscriptions.add(linkPort.links.listen(_onLink));
          final initial = await linkPort.initialLink();
          if (initial != null) _onLink(initial);
          return true;
        });

    _capabilities = VeloraDesktopCapabilities(
      window: window,
      tray: _trayReady,
      autoStart: autoStart,
      singleInstance: singleInstance,
      protocolLinks: links,
      powerEvents: power,
      problems: Map.unmodifiable(problems),
    );
  }

  @override
  Future<void> show({bool focus = true}) => _window.show(focus: focus);

  @override
  Future<void> hide() => _window.hide();

  @override
  Future<void> quit() async {
    _quitting = true;
    await _window.close();
  }

  @override
  Future<void> setAutoStart(bool enabled) async {
    final port = _autoStart;
    if (port == null || !_capabilities.autoStart) {
      throw UnsupportedError(
        'Auto-start is not available'
        '${_capabilities.problems['autoStart'] == null ? '' : ': ${_capabilities.problems['autoStart']}'}',
      );
    }
    await port.setEnabled(enabled);
  }

  @override
  Future<bool> isAutoStartEnabled() async {
    final port = _autoStart;
    if (port == null || !_capabilities.autoStart) return false;
    return port.isEnabled();
  }

  /// Reports that the user activated a notification, so it joins the same
  /// ordered, de-duplicated stream as the other activations. [id] must be
  /// unique per activation (not per notification) for a repeat tap on the same
  /// notification to be reported again.
  void reportNotificationActivation({
    required String id,
    Map<String, Object?> data = const {},
  }) {
    _activate(
      VeloraDesktopEvent(
        type: VeloraDesktopEventType.notificationActivation,
        id: id,
        data: data,
      ),
      key: 'notification:$id',
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _ignoreErrors(() async => _power?.stop());
    await _ignoreErrors(() async => _tray?.dispose());
    await _ignoreErrors(_window.detach);
    _trayReady = false;
    await _events.close();
  }

  Future<void> _ignoreErrors(Future<void> Function() body) async {
    try {
      await body();
    } on Object {
      // Teardown continues; there is nobody left to report to.
    }
  }

  /// Decides a close request: `true` lets the window close.
  bool _onCloseRequested() {
    if (_quitting) return true;
    final hideInstead = config.closeToTray && _trayReady;
    _emit(
      VeloraDesktopEvent(
        type: VeloraDesktopEventType.closeRequested,
        data: {'hidden': hideInstead},
      ),
    );
    if (hideInstead) unawaited(hide());
    return !hideInstead;
  }

  void _onSecondaryLaunch(List<String> arguments) {
    final exact = List<String>.unmodifiable(arguments);
    final link = _protocolLink(exact);
    if (link != null) {
      _activate(
        VeloraDesktopEvent(
          type: VeloraDesktopEventType.protocolActivation,
          id: link.toString(),
          arguments: exact,
          uri: link,
        ),
        key: 'link:$link',
      );
    } else {
      // Two launches with the same command line are two requests, so a
      // secondary launch is never treated as a duplicate.
      _emit(
        VeloraDesktopEvent(
          type: VeloraDesktopEventType.secondaryLaunch,
          arguments: exact,
        ),
      );
    }
    unawaited(show());
  }

  Uri? _protocolLink(List<String> arguments) {
    for (final argument in arguments) {
      final uri = Uri.tryParse(argument);
      if (uri != null &&
          uri.hasScheme &&
          config.protocolSchemes.contains(uri.scheme.toLowerCase())) {
        return uri;
      }
    }
    return null;
  }

  void _onLink(Uri link) {
    _activate(
      VeloraDesktopEvent(
        type: VeloraDesktopEventType.protocolActivation,
        id: link.toString(),
        uri: link,
      ),
      key: 'link:$link',
    );
  }

  void _onPowerSignal(VeloraPowerSignal signal) {
    switch (signal) {
      case VeloraPowerSignal.suspending:
        if (_asleep) return;
        _asleep = true;
        _emit(
          const VeloraDesktopEvent(type: VeloraDesktopEventType.suspending),
        );
      case VeloraPowerSignal.resumed:
        // The system can announce one wake more than once.
        if (!_asleep) return;
        _asleep = false;
        _emit(const VeloraDesktopEvent(type: VeloraDesktopEventType.resumed));
    }
  }

  void _activate(VeloraDesktopEvent event, {required String key}) {
    final now = _now();
    _seen.removeWhere(
      (_, at) => now.difference(at) > config.deduplicationWindow,
    );
    if (_seen.containsKey(key)) return;
    _seen[key] = now;
    _emit(event);
  }

  void _emit(VeloraDesktopEvent event) {
    if (_disposed) return;
    if (_events.hasListener) {
      _events.add(event);
    } else {
      _pending.add(event);
    }
  }

  void _flush() {
    final pending = List.of(_pending);
    _pending.clear();
    pending.forEach(_events.add);
  }
}
