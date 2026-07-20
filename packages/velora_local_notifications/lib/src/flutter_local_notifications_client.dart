import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_notifications_client.dart';

/// The default, real [LocalNotificationsClient] implementation, backed by
/// `flutter_local_notifications`.
///
/// This is where every `flutter_local_notifications`-specific type lives
/// (Android/Darwin initialization settings, notification channel/details,
/// `TZDateTime` conversion) so that [VeloraLocalNotificationsAdapter]'s id
/// mapping logic stays plugin-agnostic and unit-testable.
class FlutterLocalNotificationsClient implements LocalNotificationsClient {
  FlutterLocalNotificationsClient({
    FlutterLocalNotificationsPlugin? plugin,
    String androidDefaultIcon = '@mipmap/ic_launcher',
    String channelId = 'velora_default_channel',
    String channelName = 'Velora Notifications',
    String channelDescription = 'Default notification channel for this app.',
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _androidDefaultIcon = androidDefaultIcon,
        _channelId = channelId,
        _channelName = channelName,
        _channelDescription = channelDescription;

  final FlutterLocalNotificationsPlugin _plugin;
  final String _androidDefaultIcon;
  final String _channelId;
  final String _channelName;
  final String _channelDescription;

  bool _timeZonesInitialized = false;

  @override
  Future<void> initialize() async {
    if (!_timeZonesInitialized) {
      tz_data.initializeTimeZones();
      _timeZonesInitialized = true;
    }

    final androidSettings = AndroidInitializationSettings(_androidDefaultIcon);
    const darwinSettings = DarwinInitializationSettings();
    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initializationSettings);
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
  }) {
    return _plugin.show(
      id,
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    DateTime dateTime, {
    String? payload,
  }) {
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }
}
