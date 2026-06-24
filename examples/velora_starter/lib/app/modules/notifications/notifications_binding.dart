import 'package:get/get.dart';
import 'package:velora/velora.dart';

import 'presentation/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  static bool _mockRuntimeRegistered = false;

  @override
  void dependencies() {
    if (!_mockRuntimeRegistered) {
      _registerMockRuntime();
      _mockRuntimeRegistered = true;
    }

    if (!Get.isRegistered<NotificationsController>()) {
      Get.put<NotificationsController>(NotificationsController());
    }
  }

  void _registerMockRuntime() {
    if (Get.isRegistered<VeloraNotify>()) {
      Get.delete<VeloraNotify>(force: true);
    }
    if (Get.isRegistered<NotificationService>()) {
      Get.delete<NotificationService>(force: true);
    }
    if (Get.isRegistered<NotificationRepository>()) {
      Get.delete<NotificationRepository>(force: true);
    }

    final repository = InMemoryNotificationRepository(_mockNotifications());
    final notify = VeloraNotify(
      repository: repository,
      pushAdapter: NoopPushAdapter(
        permissionGranted: true,
        token: 'starter-demo-token',
      ),
      localAdapter: InMemoryLocalNotificationAdapter(),
    );

    Get.put<NotificationRepository>(repository, permanent: true);
    Get.put<VeloraNotify>(notify, permanent: true);
    Get.put<NotificationService>(notify, permanent: true);
  }

  List<AppNotification> _mockNotifications() {
    final now = DateTime.now();

    return [
      AppNotification(
        id: 'starter-welcome',
        type: 'in_app',
        title: 'Welcome to Velora Starter',
        body: 'Open this notification center from the dashboard bell.',
        feature: 'notifications',
        permission: 'notifications.view',
        route: '/notifications',
        data: const {'source': 'starter'},
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      AppNotification(
        id: 'starter-users-report',
        type: 'in_app',
        title: 'Users report ready',
        body:
            'Demo export completed. No file was generated in the starter app.',
        feature: 'users',
        permission: 'users.view',
        route: '/users',
        data: const {'format': 'csv'},
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'starter-maintenance',
        type: 'local',
        title: 'Maintenance reminder',
        body: 'This read item shows how historical notifications appear.',
        feature: 'notifications',
        permission: 'notifications.view',
        data: const {'severity': 'info'},
        readAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
