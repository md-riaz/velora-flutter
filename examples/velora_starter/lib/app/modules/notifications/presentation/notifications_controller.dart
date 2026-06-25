import 'package:velora/velora.dart';

class NotificationsController extends VeloraController {
  Future<void> fetch() async {
    await run(() => Velora.notify.fetch());
  }

  Future<void> markAsRead(VeloraNotification notification) async {
    if (notification.isRead) return;
    await run(() => Velora.notify.markAsRead(notification.id));
  }

  Future<void> markAllAsRead() async {
    if (Velora.notify.unreadCount.value == 0) return;
    await run(
      () => Velora.notify.markAllAsRead(),
      successMessage: 'All notifications marked as read',
    );
  }

  Future<void> open(VeloraNotification notification) async {
    await Velora.notify.handleTap(notification);
  }
}
