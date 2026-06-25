import 'package:flutter/material.dart';

import 'package:velora/velora.dart';

import '../../notifications_routes.dart';
import '../notifications_controller.dart';
import '../widgets/notification_tile.dart';

class NotificationsIndexPage extends GetView<NotificationsController> {
  const NotificationsIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(
            () => TextButton(
              onPressed: Velora.notify.unreadCount.value == 0
                  ? null
                  : controller.markAllAsRead,
              child: const Text('Mark all read'),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final notifications = Velora.notify.notifications;
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (notifications.isEmpty) {
          return const Center(child: Text('No notifications yet.'));
        }

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () => Velora.nav.to(
                  NotificationsRoutes.detail,
                  arguments: notification,
                ),
                onMarkRead: () => controller.markAsRead(notification),
              );
            },
          ),
        );
      }),
    );
  }
}
