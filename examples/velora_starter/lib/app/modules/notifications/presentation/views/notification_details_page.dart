import 'package:flutter/material.dart';

import 'package:velora/velora.dart';

import '../notifications_controller.dart';

class NotificationDetailsPage extends GetView<NotificationsController> {
  const NotificationDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments;
    final notification = argument is AppNotification ? argument : null;

    if (notification == null) {
      return const Scaffold(
        body: Center(child: Text('Notification not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notification detail')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            notification.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_createdAt(notification.createdAt)),
          const SizedBox(height: 24),
          Text(notification.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          if (notification.data.isNotEmpty) ...[
            Text('Data', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...notification.data.entries.map(
              (entry) => Text('${entry.key}: ${entry.value}'),
            ),
            const SizedBox(height: 24),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Obx(() {
                final current = Velora.notify.notifications.firstWhereOrNull(
                  (item) => item.id == notification.id,
                );
                final isUnread = current?.isUnread ?? notification.isUnread;

                return FilledButton.icon(
                  onPressed: isUnread
                      ? () => controller.markAsRead(notification)
                      : null,
                  icon: const Icon(Icons.done),
                  label: const Text('Mark read'),
                );
              }),
              FilledButton.tonalIcon(
                onPressed: () => controller.open(notification),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open action'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _createdAt(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
