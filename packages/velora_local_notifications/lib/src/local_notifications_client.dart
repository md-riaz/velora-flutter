/// A thin seam between [VeloraLocalNotificationsAdapter] and the real
/// `flutter_local_notifications` plugin.
///
/// `flutter_local_notifications` talks to platform channels, which don't
/// exist under `flutter test`. By depending on this interface instead of the
/// plugin directly, [VeloraLocalNotificationsAdapter] can be exercised
/// headlessly with a fake in tests, while [FlutterLocalNotificationsClient]
/// provides the real, on-device behaviour for apps.
///
/// All `flutter_local_notifications`-specific concepts (channels, Darwin
/// settings, timezone conversion, `NotificationDetails`, ...) are confined to
/// implementations of this interface -- callers only ever see plain Dart
/// types (`int` ids, `String`, `DateTime`).
abstract class LocalNotificationsClient {
  /// Performs one-time plugin/platform initialization.
  Future<void> initialize();

  /// Shows an immediate notification with the given integer [id].
  Future<void> show(int id, String? title, String? body, {String? payload});

  /// Schedules a notification with the given integer [id] to be shown at
  /// [dateTime].
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    DateTime dateTime, {
    String? payload,
  });

  /// Cancels the notification (shown or scheduled) with the given integer
  /// [id].
  Future<void> cancel(int id);

  /// Cancels every notification (shown or scheduled).
  Future<void> cancelAll();
}
