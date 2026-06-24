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
  });
}
