import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
///
/// [initialize] also requests OS notification permission (Android 13+,
/// iOS, macOS) -- see its dartdoc.
class FlutterLocalNotificationsClient implements LocalNotificationsClient {
  FlutterLocalNotificationsClient({
    FlutterLocalNotificationsPlugin? plugin,
    String androidDefaultIcon = '@mipmap/ic_launcher',
    String channelId = 'velora_default_channel',
    String channelName = 'Velora Notifications',
    String channelDescription = 'Default notification channel for this app.',
    AndroidScheduleMode androidScheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _androidDefaultIcon = androidDefaultIcon,
        _channelId = channelId,
        _channelName = channelName,
        _channelDescription = channelDescription,
        _androidScheduleMode = androidScheduleMode;

  final FlutterLocalNotificationsPlugin _plugin;
  final String _androidDefaultIcon;
  final String _channelId;
  final String _channelName;
  final String _channelDescription;

  /// The Android alarm-scheduling mode used by [zonedSchedule].
  ///
  /// Defaults to [AndroidScheduleMode.inexactAllowWhileIdle], which needs no
  /// special permission and never throws a `SecurityException` on Android
  /// 12+/14+. Exact alarms
  /// ([AndroidScheduleMode.exactAllowWhileIdle]/[AndroidScheduleMode.exact])
  /// require declaring (and, on Android 12+, the user granting) the
  /// `SCHEDULE_EXACT_ALARM` permission -- only opt into that explicitly (by
  /// passing it to this constructor) if your notifications truly need
  /// exact-time delivery; otherwise the inexact default is the safe choice
  /// and works out of the box.
  final AndroidScheduleMode _androidScheduleMode;

  bool _timeZonesInitialized = false;

  /// Initializes the plugin and, on Android 13+/iOS/macOS, requests
  /// notification permission from the OS.
  ///
  /// Requesting permission here (rather than only via a push adapter) means
  /// local notifications work even in apps that have no push/remote
  /// notification adapter wired up -- otherwise `NotificationService`'s
  /// `requestPermission()`, which only delegates to the push adapter, would
  /// leave a local-only app (`NoopPushAdapter`) without OS permission and
  /// local notifications would silently never appear.
  @override
  Future<void> initialize() async {
    if (!_timeZonesInitialized) {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
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
    await _requestPermissions();
  }

  /// Best-effort notification permission request, guarded so that a
  /// platform without the relevant plugin implementation (e.g. running on
  /// a platform that doesn't expose it, or under a test harness) never
  /// throws.
  Future<void> _requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Platform doesn't support (or doesn't need) this permission request.
    }

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // Platform doesn't support (or doesn't need) this permission request.
    }

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // Platform doesn't support (or doesn't need) this permission request.
    }
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
      androidScheduleMode: _androidScheduleMode,
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
