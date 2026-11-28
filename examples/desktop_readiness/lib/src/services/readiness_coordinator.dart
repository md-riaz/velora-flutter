import 'dart:async';

import 'package:velora_desktop/velora_desktop.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';
import 'package:velora_offline/velora_offline.dart';

import '../contracts/realtime_port.dart';
import '../data/readiness_database.dart';
import '../diagnostics/diagnostics_log.dart';

/// Plain Dart coordinator (constructor-injected, not a `GetxService`) that
/// orchestrates desktop lifecycle, native notification activations,
/// connectivity/reachability, realtime transport, and durable outbox replay.
class ReadinessCoordinator {
  final VeloraDesktopService desktop;
  final VeloraNativeNotifications notifications;
  final ReadinessRealtimePort realtime;
  final ReadinessRemoteGateway gateway;
  final ReadinessWorkStore store;
  final ToggleConnectivitySource connectivity;
  final ReadinessDiagnosticsLog diagnostics;

  final List<StreamSubscription<Object?>> _subscriptions = [];
  final Set<String> _seenActivationIds = <String>{};

  final StreamController<bool> _hiddenController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _reachableController =
      StreamController<bool>.broadcast();
  final StreamController<String> _activatedItemController =
      StreamController<String>.broadcast();

  bool _initialized = false;
  bool _disposed = false;
  bool _isHiddenToTray = false;
  bool _isSuspended = false;
  bool _endpointReachable = true;
  Future<void> _resumeQueue = Future<void>.value();

  ReadinessCoordinator({
    required this.desktop,
    required this.notifications,
    required this.realtime,
    required this.gateway,
    required this.store,
    required this.connectivity,
    required this.diagnostics,
  });

  bool get isHiddenToTray => _isHiddenToTray;
  bool get isSuspended => _isSuspended;
  bool get isOnline => connectivity.isOnline;
  bool get endpointReachable => _endpointReachable;
  ReadinessRealtimeState get realtimeState => realtime.currentState;

  Stream<bool> get hiddenToTrayStream => _hiddenController.stream;
  Stream<bool> get onlineStream => _onlineController.stream;
  Stream<bool> get endpointReachableStream => _reachableController.stream;
  Stream<ReadinessRealtimeState> get realtimeStates => realtime.states;
  Stream<String> get activatedItemIds => _activatedItemController.stream;

  /// Initializes subscriptions and connects realtime once. Idempotent.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;

    _subscriptions.add(desktop.events.listen(_handleDesktopEvent));
    _subscriptions.add(
      notifications.activations.listen(_handleNativeNotificationActivation),
    );
    _subscriptions.add(realtime.events.listen(_handleRealtimeEvent));
    _subscriptions.add(
      realtime.states.listen((state) {
        diagnostics.record(
          'realtime',
          'Realtime state changed',
          metadata: {'state': state.name},
        );
      }),
    );
    _subscriptions.add(
      connectivity.onConnectivityChanged.listen(_handleConnectivityChanged),
    );

    await store.seedDefaultsIfEmpty();
    final cursor = await store.loadCursor();
    await realtime.connect(sinceCursor: cursor);
    await reconcileAndFlush();
  }

  /// Hides the window to the tray while keeping realtime and durable queue
  /// alive.
  Future<void> hideToTray() async {
    await desktop.hide();
    _setHiddenToTray(true);
    diagnostics.record(
      'tray',
      'Window hidden to tray; background sync remains active',
      metadata: {'realtimeState': realtime.currentState.name},
    );
  }

  /// Restores and focuses the window from the tray.
  Future<void> restoreFromTray() async {
    await desktop.show(focus: true);
    _setHiddenToTray(false);
    diagnostics.record('tray', 'Window restored from tray');
  }

  /// Updates simulated network connectivity and triggers recovery if online.
  Future<void> setNetworkOnline(bool online) async {
    connectivity.setOnline(online);
    if (realtime case final SimulatedRealtimeAdapter sim) {
      sim.networkAvailable = online;
    }
    if (gateway case final SimulatedRemoteGateway simGw) {
      simGw.networkAvailable = online;
    }
    _onlineController.add(online);
    diagnostics.record(
      'network',
      online ? 'Network restored' : 'Network lost',
      metadata: {'online': online},
    );
    if (online) {
      await reconcileAndFlush();
    } else {
      await realtime.connect(sinceCursor: await store.loadCursor());
    }
  }

  /// Updates simulated endpoint reachability and triggers recovery if reachable.
  Future<void> setEndpointReachable(bool reachable) async {
    _endpointReachable = reachable;
    if (realtime case final SimulatedRealtimeAdapter sim) {
      sim.endpointReachable = reachable;
    }
    if (gateway case final SimulatedRemoteGateway simGw) {
      simGw.endpointReachable = reachable;
    }
    _reachableController.add(reachable);
    diagnostics.record(
      'network',
      reachable ? 'Endpoint reachable' : 'Endpoint unreachable',
      metadata: {'reachable': reachable},
    );
    if (reachable && connectivity.isOnline) {
      await reconcileAndFlush();
    } else {
      await realtime.connect(sinceCursor: await store.loadCursor());
    }
  }

  /// Updates simulated unauthorized mode.
  Future<void> setUnauthorizedMode(bool unauthorized) async {
    if (realtime case final SimulatedRealtimeAdapter sim) {
      sim.unauthorizedMode = unauthorized;
    }
    if (gateway case final SimulatedRemoteGateway simGw) {
      simGw.unauthorizedMode = unauthorized;
    }
    diagnostics.record(
      'auth',
      unauthorized ? 'Unauthorized mode enabled' : 'Authorization restored',
      metadata: {'unauthorized': unauthorized},
    );
    if (unauthorized) {
      await realtime.connect(sinceCursor: await store.loadCursor());
    } else {
      await reconcileAndFlush();
    }
  }

  /// Revalidates reachability, reconnects realtime if needed, reconciles
  /// missed events once, and flushes the durable outbox.
  Future<OutboxFlushReport> reconcileAndFlush() async {
    final online = await connectivity.isConnected();
    _onlineController.add(online);
    if (!online) {
      _endpointReachable = false;
      _reachableController.add(false);
      return const OutboxFlushReport(unreachable: true);
    }

    final reachable = await gateway.checkReachability();
    _endpointReachable = reachable;
    _reachableController.add(reachable);
    if (!reachable) {
      return const OutboxFlushReport(unreachable: true);
    }

    final cursor = await store.loadCursor();
    if (realtime.currentState != ReadinessRealtimeState.connected &&
        realtime.currentState != ReadinessRealtimeState.closed) {
      await realtime.connect(sinceCursor: cursor);
    }

    if (realtime.currentState == ReadinessRealtimeState.unauthorized) {
      return const OutboxFlushReport(pausedUnauthorized: true);
    }

    final missed = await gateway.fetchSince(cursor);
    if (missed.isNotEmpty) {
      await store.reconcile(sinceCursor: cursor, events: missed);
    }

    final report = await store.flushOutbox();
    if (report.pausedUnauthorized) {
      await setUnauthorizedMode(true);
    }
    return report;
  }

  void _setHiddenToTray(bool value) {
    if (_isHiddenToTray == value) return;
    _isHiddenToTray = value;
    if (!_hiddenController.isClosed) {
      _hiddenController.add(value);
    }
  }

  Future<void> _handleConnectivityChanged(bool online) async {
    if (!_onlineController.isClosed) {
      _onlineController.add(online);
    }
    if (online) {
      await reconcileAndFlush();
    }
  }

  Future<void> _handleRealtimeEvent(ReadinessRealtimeEvent event) async {
    final cursor = await store.loadCursor();
    await store.reconcile(sinceCursor: cursor, events: [event]);
  }

  Future<void> _handleDesktopEvent(VeloraDesktopEvent event) async {
    switch (event.type) {
      case VeloraDesktopEventType.closeRequested:
        final hidden = event.data['hidden'] == true;
        if (hidden) {
          _setHiddenToTray(true);
          diagnostics.record('tray', 'Close intercepted; hidden to tray');
        } else {
          diagnostics.record('lifecycle', 'Close requested');
        }

      case VeloraDesktopEventType.suspending:
        if (_isSuspended) {
          diagnostics.record('power', 'Coalesced duplicate suspend signal');
          return;
        }
        _isSuspended = true;
        await realtime.invalidateConnection();
        diagnostics.record(
          'power',
          'System suspending; invalidated old realtime connection',
        );

      case VeloraDesktopEventType.resumed:
        if (!_isSuspended) {
          diagnostics.record('power', 'Coalesced duplicate resume signal');
          return;
        }
        _isSuspended = false;
        _resumeQueue = _resumeQueue.then((_) => _performResumeRecovery());
        await _resumeQueue;

      case VeloraDesktopEventType.notificationActivation:
        await _routeNotificationActivation(
          activationId:
              (event.data['activationId'] as String?) ?? event.id ?? '',
          itemId: event.data['itemId'],
        );

      case VeloraDesktopEventType.protocolActivation:
        final itemId = event.uri?.queryParameters['itemId'];
        await _routeNotificationActivation(
          activationId: event.id ?? 'proto-${event.uri}',
          itemId: itemId,
        );

      case VeloraDesktopEventType.secondaryLaunch:
        await restoreFromTray();
        diagnostics.record(
          'lifecycle',
          'Secondary launch focused existing window',
          metadata: {'argCount': event.arguments.length},
        );
    }
  }

  Future<void> _performResumeRecovery() async {
    diagnostics.record('power', 'System resumed; revalidating and reconciling');
    final cursor = await store.loadCursor();
    await realtime.connect(sinceCursor: cursor);
    await reconcileAndFlush();
  }

  Future<void> _handleNativeNotificationActivation(
    VeloraNotificationActivation activation,
  ) async {
    final activationId =
        (activation.payload['activationId'] as String?) ?? activation.id;
    final itemId = activation.payload['itemId'] ?? activation.data['itemId'];
    await _routeNotificationActivation(
      activationId: activationId,
      itemId: itemId,
    );
  }

  Future<void> _routeNotificationActivation({
    required String activationId,
    required Object? itemId,
  }) async {
    if (activationId.isEmpty) {
      diagnostics.record(
        'notification',
        'Ignored notification activation with empty ID',
      );
      return;
    }
    if (!_seenActivationIds.add(activationId)) {
      diagnostics.record(
        'notification',
        'Deduplicated notification activation',
        metadata: {'activationId': activationId},
      );
      return;
    }
    if (_seenActivationIds.length > 200) {
      _seenActivationIds.remove(_seenActivationIds.first);
    }

    if (itemId is! String || itemId.trim().isEmpty) {
      diagnostics.record(
        'notification',
        'Ignored malformed notification payload',
        metadata: {'activationId': activationId},
      );
      return;
    }

    final existing = await store.findItem(itemId);
    if (existing == null) {
      diagnostics.record(
        'notification',
        'Ignored notification for unknown item',
        metadata: {'activationId': activationId, 'itemId': itemId},
      );
      return;
    }

    if (_isHiddenToTray) {
      await restoreFromTray();
    } else {
      await desktop.show(focus: true);
    }

    if (!_activatedItemController.isClosed) {
      _activatedItemController.add(itemId);
    }
    diagnostics.record(
      'notification',
      'Routed notification activation to work item',
      metadata: {'activationId': activationId, 'itemId': itemId},
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _hiddenController.close();
    await _onlineController.close();
    await _reachableController.close();
    await _activatedItemController.close();
  }
}
