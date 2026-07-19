import 'dart:async';

import 'package:get/get.dart';

import 'connectivity_source.dart';

/// Tracks device connectivity and notifies registered callbacks when the app
/// transitions from offline back to online (the moment it's safe to replay
/// queued writes).
class ConnectivityService extends GetxService {
  final ConnectivitySource source;
  final RxBool isOnline = true.obs;

  StreamSubscription<bool>? _subscription;
  final List<Future<void> Function()> _onOnlineCallbacks = [];

  ConnectivityService(this.source);

  /// Seeds [isOnline] from the current connectivity state and starts
  /// listening for changes. Returns `this` for fluent chaining, mirroring
  /// `VeloraStorageService.init()`.
  Future<ConnectivityService> init() async {
    isOnline.value = await source.isConnected();
    _subscription = source.onConnectivityChanged.listen(_handleUpdate);
    return this;
  }

  /// Registers a callback invoked whenever connectivity transitions from
  /// offline to online.
  void onOnline(Future<void> Function() callback) {
    _onOnlineCallbacks.add(callback);
  }

  void _handleUpdate(bool online) {
    final wasOffline = !isOnline.value;
    isOnline.value = online;
    if (wasOffline && online) {
      for (final callback in List<Future<void> Function()>.from(
        _onOnlineCallbacks,
      )) {
        // Fire-and-forget: a slow/failing reconnect hook must not block
        // connectivity updates for the rest of the app.
        unawaited(callback());
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
