import 'dart:io';

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
/// `TZDateTime` conversion) so that the adapter's id mapping logic stays
/// plugin-agnostic and unit-testable.
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
    this.windowsAppName,
    this.windowsAppUserModelId,
    this.windowsGuid,
    this.windowsIconPath,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
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
  final AndroidScheduleMode _androidScheduleMode;

  /// Windows-specific initialization settings. All optional — when null, the
  /// platform default applies.
  final String? windowsAppName;
  final String? windowsAppUserModelId;
  final String? windowsGuid;
  final String? windowsIconPath;

  bool _timeZonesInitialized = false;

  @override
  Future<void> initialize({
    void Function({
      required int id,
      String? actionId,
      String? input,
      String? payload,
      Map<String, dynamic> data,
    })? onActivation,
  }) async {
    if (!_timeZonesInitialized) {
      tz_data.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
      _timeZonesInitialized = true;
    }

    final androidSettings = AndroidInitializationSettings(_androidDefaultIcon);
    const darwinSettings = DarwinInitializationSettings();

    WindowsInitializationSettings? windowsSettings;
    if (Platform.isWindows) {
      windowsSettings = WindowsInitializationSettings(
        appName: windowsAppName ?? 'Velora',
        appUserModelId: windowsAppUserModelId ?? '',
        guid: windowsGuid ?? '',
        iconPath: windowsIconPath,
      );
    }

    final initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      windows: windowsSettings,
    );

    void Function(NotificationResponse)? responseCallback;
    if (onActivation != null) {
      responseCallback = (response) {
        onActivation(
          id: response.id ?? 0,
          actionId: response.actionId,
          input: response.input,
          payload: response.payload,
          data: response.data,
        );
      };
    }

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: responseCallback,
    );
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
    List<Map<String, String?>> actions = const [],
    bool silent = false,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(
        actions: actions,
        silent: silent,
      ),
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
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: _androidScheduleMode,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  NotificationDetails _notificationDetails({
    List<Map<String, String?>> actions = const [],
    bool silent = false,
  }) {
    final windowsActions = <WindowsAction>[];
    final windowsInputs = <WindowsInput>[];
    for (final action in actions) {
      final id = action['id'];
      final label = action['label'];
      if (id == null || label == null) continue;

      final placeholder = action['textInputPlaceholder'];
      if (placeholder != null) {
        windowsInputs.add(
          WindowsTextInput(id: id, placeHolderContent: placeholder),
        );
        windowsActions.add(WindowsAction(
          content: label,
          arguments: id,
          inputId: id,
        ));
      } else {
        windowsActions.add(WindowsAction(
          content: label,
          arguments: id,
        ));
      }
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        playSound: !silent,
        enableVibration: !silent,
      ),
      iOS: DarwinNotificationDetails(presentSound: !silent),
      macOS: DarwinNotificationDetails(presentSound: !silent),
      windows: (windowsActions.isNotEmpty || windowsInputs.isNotEmpty)
          ? WindowsNotificationDetails(
              actions: windowsActions,
              inputs: windowsInputs,
            )
          : null,
    );
  }
}
