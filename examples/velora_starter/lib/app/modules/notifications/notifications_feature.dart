import 'package:velora/velora.dart';

import 'notifications_routes.dart';

class NotificationsFeature {
  static const id = 'notifications';
  static const viewPermission = 'notifications.view';

  static const feature = VeloraFeature(
    id: id,
    name: 'Notifications',
    permission: viewPermission,
    menuItems: [
      VeloraMenuItem(
        label: 'Notifications',
        route: NotificationsRoutes.index,
        permission: viewPermission,
      ),
    ],
  );
}
