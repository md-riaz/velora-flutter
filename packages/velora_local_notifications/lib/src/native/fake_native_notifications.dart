import 'dart:async';

import 'native_notification_models.dart';
import 'velora_native_notifications.dart';

/// In-memory fake of [VeloraNativeNotifications] for unit testing.
///
/// Records every call and exposes the state for assertions. Activations can be
/// injected via [simulateActivation].
class FakeNativeNotifications implements VeloraNativeNotifications {
  bool initialized = false;
  bool disposed = false;

  final List<VeloraNativeNotification> shown = [];
  final List<String> canceled = [];
  int cancelAllCalls = 0;

  final StreamController<VeloraNotificationActivation> _activations =
      StreamController<VeloraNotificationActivation>.broadcast();

  @override
  Stream<VeloraNotificationActivation> get activations => _activations.stream;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> show(VeloraNativeNotification notification) async {
    shown.add(notification);
  }

  @override
  Future<void> cancel(String id) async {
    canceled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _activations.close();
  }

  /// Injects an activation into the [activations] stream.
  void simulateActivation(VeloraNotificationActivation activation) {
    _activations.add(activation);
  }
}
