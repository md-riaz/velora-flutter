import 'notification_payload.dart';

enum PushProvider { none, fcm }

class VeloraNotificationConfig {
  final bool enabled;
  final PushProvider provider;
  final bool requestPermissionAfterLogin;
  final bool showForegroundRemoteAsLocal;
  final bool syncInAppNotificationsAfterPush;
  final String deviceRegisterEndpoint;
  final String deviceUnregisterEndpoint;
  final String notificationsEndpoint;
  final String markAsReadEndpoint;
  final String markAllAsReadEndpoint;

  /// Route to send the user to when they tap a notification while
  /// unauthenticated. Defaults to `'/login'`.
  final String unauthenticatedRoute;

  /// Route to send the user to when they tap a notification they are not
  /// allowed to open (feature/permission gate failed). Defaults to `'/403'`.
  final String forbiddenRoute;

  /// Converts a raw JSON map into your [VeloraNotification] model.
  ///
  /// If omitted, [AppNotification.fromJson] is used. Override when you have
  /// custom notification fields or a non-standard API shape:
  ///
  /// ```dart
  /// VeloraNotificationConfig(
  ///   notificationParser: MyNotification.fromJson,
  /// )
  /// ```
  final VeloraNotification Function(Map<String, dynamic>)? notificationParser;

  const VeloraNotificationConfig({
    this.enabled = true,
    this.provider = PushProvider.fcm,
    this.requestPermissionAfterLogin = true,
    this.showForegroundRemoteAsLocal = true,
    this.syncInAppNotificationsAfterPush = true,
    this.deviceRegisterEndpoint = '/devices',
    this.deviceUnregisterEndpoint = '/devices',
    this.notificationsEndpoint = '/notifications',
    this.markAsReadEndpoint = '/notifications/{id}/read',
    this.markAllAsReadEndpoint = '/notifications/read-all',
    this.unauthenticatedRoute = '/login',
    this.forbiddenRoute = '/403',
    this.notificationParser,
  });
}
