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
  ///
  /// When [onActivation] is non-null, it is called for every notification tap
  /// or action button press (both cold-start and live). The parameters are:
  /// - [id]: the platform int notification id
  /// - [actionId]: the action button id, or `null` for a body tap
  /// - [input]: the text the user typed, when the action has a text field
  /// - [payload]: the opaque payload string stored with the notification
  /// - [data]: platform-specific extra data (Windows input values, etc.)
  Future<void> initialize({
    void Function({
      required int id,
      String? actionId,
      String? input,
      String? payload,
      Map<String, dynamic> data,
    })? onActivation,
  });

  /// Shows an immediate notification with the given integer [id].
  ///
  /// [actions] is a list of action descriptors. Each entry is a map with:
  /// - `id` (String): the action identifier
  /// - `label` (String): the button text
  /// - `textInputPlaceholder` (String?): when present, a text field is shown
  ///
  /// [silent] suppresses sound and vibration when `true`.
  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
    List<Map<String, String?>> actions = const [],
    bool silent = false,
  });

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
