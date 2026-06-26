import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import 'notifications_controller.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Velora.nav.back(),
        ),
        title: const Text('Notifications'),
        actions: [
          Obx(() {
            final hasUnread = Velora.notify.unreadCount.value > 0;
            return TextButton(
              onPressed: hasUnread ? controller.markAllAsRead : null,
              child: const Text('Mark all read'),
            );
          }),
        ],
      ),
      body: Obx(() {
        final notifications = Velora.notify.notifications;
        if (notifications.isEmpty) {
          return const Center(
            child: VeloraEmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications',
              description: 'You are all caught up.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            // In a real app: await Velora.notify.fetch();
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: scheme.outlineVariant),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(
                notification: n,
                scheme: scheme,
                textTheme: textTheme,
                onMarkRead: () => controller.markAsRead(n),
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final VeloraNotification notification;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final VoidCallback onMarkRead;

  const _NotificationTile({
    required this.notification,
    required this.scheme,
    required this.textTheme,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;
    final createdAt = notification is AppNotification
        ? (notification as AppNotification).createdAt
        : null;

    return InkWell(
      onTap: unread ? onMarkRead : null,
      child: Container(
        color: unread ? scheme.primaryContainer.withAlpha(40) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: unread
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                unread
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                size: 20,
                color: unread
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
