import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

class NotificationTile extends StatelessWidget {
  final VeloraNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;

  const NotificationTile({
    required this.notification,
    this.onTap,
    this.onMarkRead,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;
    // createdAt is not part of VeloraNotification — access it only when the
    // concrete type is AppNotification (the default, no custom parser set).
    final createdAt =
        notification is AppNotification
            ? (notification as AppNotification).createdAt
            : null;

    return Card(
      child: ListTile(
        leading: Icon(
          unread ? Icons.notifications_active : Icons.notifications_none,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(_relativeTime(createdAt)),
            ],
          ],
        ),
        trailing: unread
            ? IconButton(
                tooltip: 'Mark read',
                icon: const Icon(Icons.done),
                onPressed: onMarkRead,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
