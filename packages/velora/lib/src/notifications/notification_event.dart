import 'notification_payload.dart';

enum NotificationEventType {
  foregroundMessage,
  openedApp,
  localShown,
  localScheduled,
  tapped,
}

class NotificationEvent {
  final NotificationEventType type;
  final VeloraNotification? notification;
  final PushMessage? message;
  final Map<String, dynamic> data;

  const NotificationEvent({
    required this.type,
    this.notification,
    this.message,
    this.data = const {},
  });
}
