import 'dart:async';

import 'connectivity_source.dart';

/// A [ConnectivitySource] whose online/offline state you flip
/// programmatically, standing in for the device's real network state.
///
/// Useful for:
/// - **Unit tests** — drive `ConnectivityService` (and anything built on top
///   of it, like `VeloraOfflinePlugin`'s queue flush) through connectivity
///   transitions without touching `connectivity_plus`'s platform channels.
/// - **Demos/previews** — let a UI toggle simulate connectivity drops and
///   restores on demand, without airplane mode or a real network dependency.
/// - **Real apps** — back a manual "work offline" switch some products
///   expose to end users.
class ToggleConnectivitySource implements ConnectivitySource {
  bool _online;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  ToggleConnectivitySource({bool online = true}) : _online = online;

  @override
  Future<bool> isConnected() async => _online;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// The current simulated connectivity state.
  bool get isOnline => _online;

  /// Flips the simulated connectivity state and notifies listeners — but
  /// only when [value] actually differs from the current state, to avoid
  /// emitting spurious duplicate events.
  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    _controller.add(value);
  }

  /// Closes the underlying stream controller. Call when the source is no
  /// longer needed (app teardown / test cleanup).
  void dispose() {
    _controller.close();
  }
}
