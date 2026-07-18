import 'notification_service.dart';

class VeloraNotify extends NotificationService {
  VeloraNotify({
    required super.repository,
    required super.pushAdapter,
    required super.localAdapter,
    required super.auth,
    required super.feature,
    required super.permission,
    required super.nav,
    required super.config,
    super.onNotificationTap,
  });
}
