import 'dart:async';

import '../models/work_item.dart';

/// Lifecycle states of a replaceable realtime transport.
enum ReadinessRealtimeState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  paused,
  unauthorized,
  closed,
}

/// An event delivered over the realtime stream or catch-up fetch.
final class ReadinessRealtimeEvent {
  final String id;
  final String cursor;
  final WorkItem item;

  const ReadinessRealtimeEvent({
    required this.id,
    required this.cursor,
    required this.item,
  });
}

/// Persists and loads the latest processed realtime cursor.
abstract interface class ReadinessCursorStore {
  Future<String?> loadCursor();
  Future<void> saveCursor(String cursor);
}

/// Applies catch-up or live events idempotently into local durable state.
abstract interface class ReadinessReconciler {
  Future<int> reconcile({
    required String? sinceCursor,
    required List<ReadinessRealtimeEvent> events,
  });
}

/// Vendor-agnostic realtime transport contract.
abstract interface class ReadinessRealtimePort {
  Stream<ReadinessRealtimeState> get states;
  ReadinessRealtimeState get currentState;
  Stream<ReadinessRealtimeEvent> get events;

  Future<void> connect({String? sinceCursor});
  Future<void> disconnect();

  /// Invalidates any active connection epoch (e.g., before OS suspend) so
  /// delayed packets from the old connection cannot emit after wake.
  Future<void> invalidateConnection();

  Future<void> pause();
  Future<void> resume();
  Future<void> dispose();
}

/// Outcome of pushing a local outbox mutation to the remote gateway.
enum ReadinessPushOutcome { applied, unreachable, conflict, unauthorized }

/// Result returned by [ReadinessRemoteGateway.pushMutation].
final class ReadinessPushResult {
  final ReadinessPushOutcome outcome;
  final WorkItem? serverItem;
  final String? serverTitle;
  final String? errorMessage;

  const ReadinessPushResult({
    required this.outcome,
    this.serverItem,
    this.serverTitle,
    this.errorMessage,
  });
}

/// Vendor-agnostic remote gateway for outbox replay and cursor catch-up.
abstract interface class ReadinessRemoteGateway {
  Future<bool> checkReachability();

  Future<ReadinessPushResult> pushMutation({
    required WorkItem item,
    required String idempotencyKey,
  });

  Future<List<ReadinessRealtimeEvent>> fetchSince(String? cursor);
}

/// Deterministic in-memory [ReadinessRealtimePort] for simulation and tests.
class SimulatedRealtimeAdapter implements ReadinessRealtimePort {
  final StreamController<ReadinessRealtimeState> _stateController =
      StreamController<ReadinessRealtimeState>.broadcast();
  final StreamController<ReadinessRealtimeEvent> _eventController =
      StreamController<ReadinessRealtimeEvent>.broadcast();

  ReadinessRealtimeState _state = ReadinessRealtimeState.disconnected;
  int _connectionEpoch = 0;
  bool _disposed = false;

  bool networkAvailable;
  bool endpointReachable;
  Duration responseDelay;
  bool unauthorizedMode;

  SimulatedRealtimeAdapter({
    this.networkAvailable = true,
    this.endpointReachable = true,
    this.responseDelay = Duration.zero,
    this.unauthorizedMode = false,
  });

  @override
  Stream<ReadinessRealtimeState> get states => _stateController.stream;

  @override
  ReadinessRealtimeState get currentState => _state;

  @override
  Stream<ReadinessRealtimeEvent> get events => _eventController.stream;

  int get connectionEpoch => _connectionEpoch;

  void _setState(ReadinessRealtimeState next) {
    if (_disposed || _state == next) return;
    _state = next;
    _stateController.add(next);
  }

  @override
  Future<void> connect({String? sinceCursor}) async {
    if (_disposed || _state == ReadinessRealtimeState.closed) return;
    final epoch = ++_connectionEpoch;
    _setState(ReadinessRealtimeState.connecting);
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
    if (_disposed ||
        epoch != _connectionEpoch ||
        _state == ReadinessRealtimeState.closed) {
      return;
    }
    if (unauthorizedMode) {
      _setState(ReadinessRealtimeState.unauthorized);
      return;
    }
    if (!networkAvailable || !endpointReachable) {
      _setState(ReadinessRealtimeState.reconnecting);
      return;
    }
    _setState(ReadinessRealtimeState.connected);
  }

  @override
  Future<void> disconnect() async {
    if (_disposed || _state == ReadinessRealtimeState.closed) return;
    _connectionEpoch++;
    _setState(ReadinessRealtimeState.disconnected);
  }

  @override
  Future<void> invalidateConnection() async {
    if (_disposed || _state == ReadinessRealtimeState.closed) return;
    _connectionEpoch++;
    _setState(ReadinessRealtimeState.disconnected);
  }

  @override
  Future<void> pause() async {
    if (_disposed || _state == ReadinessRealtimeState.closed) return;
    _setState(ReadinessRealtimeState.paused);
  }

  @override
  Future<void> resume() async {
    if (_disposed || _state == ReadinessRealtimeState.closed) return;
    await connect();
  }

  /// Forces the transport into [ReadinessRealtimeState.closed].
  void forceClose() {
    if (_disposed) return;
    _connectionEpoch++;
    _setState(ReadinessRealtimeState.closed);
  }

  /// Emits a remote event if the transport is currently connected.
  ///
  /// Duplicate event IDs are intentionally allowed here so downstream
  /// deduplication can be tested deterministically.
  void emitRemoteEvent(ReadinessRealtimeEvent event) {
    if (_disposed || _state != ReadinessRealtimeState.connected) return;
    _eventController.add(event);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stateController.close();
    await _eventController.close();
  }
}

/// Deterministic in-memory [ReadinessRemoteGateway] for simulation and tests.
class SimulatedRemoteGateway implements ReadinessRemoteGateway {
  bool networkAvailable;
  bool endpointReachable;
  Duration responseDelay;
  bool unauthorizedMode;
  bool conflictOnNextSync;
  String conflictServerTitle;

  final Map<String, WorkItem> _appliedIdempotencyKeys = {};
  final List<ReadinessRealtimeEvent> _catchUpEvents = [];
  int pushAttempts = 0;

  SimulatedRemoteGateway({
    this.networkAvailable = true,
    this.endpointReachable = true,
    this.responseDelay = Duration.zero,
    this.unauthorizedMode = false,
    this.conflictOnNextSync = false,
    this.conflictServerTitle = 'Server-edited title',
  });

  /// Number of unique idempotent mutations accepted by the remote gateway.
  int get uniqueAppliedCount => _appliedIdempotencyKeys.length;

  /// Queues a remote event to be returned by [fetchSince] when cursor differs.
  void stageRemoteEvent(ReadinessRealtimeEvent event) {
    _catchUpEvents.add(event);
  }

  @override
  Future<bool> checkReachability() async {
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
    return networkAvailable && endpointReachable;
  }

  @override
  Future<ReadinessPushResult> pushMutation({
    required WorkItem item,
    required String idempotencyKey,
  }) async {
    pushAttempts++;
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
    if (unauthorizedMode) {
      return const ReadinessPushResult(
        outcome: ReadinessPushOutcome.unauthorized,
        errorMessage: '401 Unauthorized: credentials expired',
      );
    }
    if (!networkAvailable || !endpointReachable) {
      return const ReadinessPushResult(
        outcome: ReadinessPushOutcome.unreachable,
        errorMessage: 'Remote endpoint is unreachable',
      );
    }

    final existing = _appliedIdempotencyKeys[idempotencyKey];
    if (existing != null) {
      return ReadinessPushResult(
        outcome: ReadinessPushOutcome.applied,
        serverItem: existing,
      );
    }

    if (conflictOnNextSync) {
      conflictOnNextSync = false;
      return ReadinessPushResult(
        outcome: ReadinessPushOutcome.conflict,
        serverTitle: conflictServerTitle,
        errorMessage: 'Version conflict detected on server',
      );
    }

    final applied = item.copyWith(
      version: item.version + 1,
      syncStatus: SyncStatus.synced,
      clearIdempotencyKey: true,
      clearServerTitle: true,
      clearLastError: true,
    );
    _appliedIdempotencyKeys[idempotencyKey] = applied;
    return ReadinessPushResult(
      outcome: ReadinessPushOutcome.applied,
      serverItem: applied,
    );
  }

  @override
  Future<List<ReadinessRealtimeEvent>> fetchSince(String? cursor) async {
    if (responseDelay > Duration.zero) {
      await Future<void>.delayed(responseDelay);
    }
    if (unauthorizedMode || !networkAvailable || !endpointReachable) {
      return const [];
    }
    if (cursor == null) {
      return List<ReadinessRealtimeEvent>.unmodifiable(_catchUpEvents);
    }
    final index = _catchUpEvents.indexWhere((e) => e.cursor == cursor);
    if (index == -1) {
      return List<ReadinessRealtimeEvent>.unmodifiable(_catchUpEvents);
    }
    return List<ReadinessRealtimeEvent>.unmodifiable(
      _catchUpEvents.sublist(index + 1),
    );
  }
}
