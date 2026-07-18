import 'notification_service.dart';

class VeloraNotify extends NotificationService {
  VeloraNotify({
    required super.repository,
    required super.pushAdapter,
    required super.localAdapter,
    super.onNotificationTap,
  });
}
