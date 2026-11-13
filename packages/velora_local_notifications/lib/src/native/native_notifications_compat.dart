import 'package:velora/velora.dart';

import 'native_notification_models.dart';
import 'velora_native_notifications.dart';

/// Bridges [VeloraNativeNotifications] into the legacy [LocalNotificationAdapter]
/// interface for one deprecation cycle.
///
/// New code should use [VeloraNativeNotifications] directly. This adapter lets
/// existing code that depends on [LocalNotificationAdapter] keep working while
/// it migrates.
@Deprecated('Use VeloraNativeNotifications directly. '
    'This compatibility adapter will be removed in a future release.')
class NativeNotificationsCompat implements LocalNotificationAdapter {
  NativeNotificationsCompat(this._native);

  final VeloraNativeNotifications _native;

  int _nextShowId = DateTime.now().millisecondsSinceEpoch % 0x7FFFFFFF;

  int _getAndIncrementShowId() {
    final id = _nextShowId;
    _nextShowId = _nextShowId >= 0x7FFFFFFF ? 1 : _nextShowId + 1;
    return id;
  }

  @override
  Future<void> init() => _native.initialize();

  @override
  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) {
    final id = 'compat-show-${_getAndIncrementShowId()}';
    return _native.show(VeloraNativeNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    ));
  }

  @override
  Future<void> schedule({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
    Map<String, dynamic> payload = const {},
  }) {
    // VeloraNativeNotifications does not expose scheduling yet (per issue #58:
    // "add scheduling only when the readiness app requires it"). Fall back to
    // an immediate show with the scheduled id so that the cancel path still
    // works.
    return _native.show(VeloraNativeNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    ));
  }

  @override
  Future<void> cancel(String id) => _native.cancel(id);

  @override
  Future<void> cancelAll() => _native.cancelAll();
}
