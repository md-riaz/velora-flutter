import 'package:velora/velora.dart';

/// Demonstrates [NotificationService] patterns in Velora.
///
/// In a real app [Velora.notify.fetch()] loads notifications from the server.
/// Here we seed the list directly so the demo works without a backend.
class NotificationsController extends VeloraController {
  @override
  void onInit() {
    super.onInit();
    _seedMockNotifications();
  }

  void _seedMockNotifications() {
    // Only seed once — avoids duplicate entries if the controller is hot-reloaded.
    if (Velora.notify.notifications.isNotEmpty) return;

    final now = DateTime.now();
    Velora.notify.notifications.assignAll([
      AppNotification(
        id: 'n1',
        type: 'system',
        title: 'Welcome to Claude',
        body: 'Your account is set up and ready to use.',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: 'n2',
        type: 'feature',
        title: 'Canvas mode available',
        body: 'Try the new side-by-side canvas editor in your next chat.',
        feature: 'chat.canvas',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n3',
        type: 'message',
        title: 'Conversation archived',
        body: 'Your conversation "Dart async/await" was archived.',
        createdAt: now.subtract(const Duration(hours: 6)),
        readAt: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'n4',
        type: 'system',
        title: 'New features unlocked',
        body: 'Code interpreter and Artifacts are now available in your plan.',
        createdAt: now.subtract(const Duration(days: 1)),
        readAt: now.subtract(const Duration(hours: 20)),
      ),
    ]);
    _recalculateUnread();
  }

  Future<void> markAsRead(VeloraNotification notification) async {
    if (notification.isRead) return;
    final notifications = Velora.notify.notifications;
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index == -1) return;
    notifications[index] = notification.copyWith(readAt: DateTime.now());
    _recalculateUnread();
  }

  Future<void> markAllAsRead() async {
    if (Velora.notify.unreadCount.value == 0) return;
    final now = DateTime.now();
    Velora.notify.notifications.assignAll(
      Velora.notify.notifications
          .map((n) => n.isUnread ? n.copyWith(readAt: now) : n)
          .toList(growable: false),
    );
    Velora.notify.unreadCount.value = 0;
    Velora.toast.success('All notifications marked as read');
  }

  void _recalculateUnread() {
    Velora.notify.unreadCount.value =
        Velora.notify.notifications.where((n) => n.isUnread).length;
  }
}
