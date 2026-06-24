import 'package:velora/velora.dart';

import '../../routes/app_routes.dart';
import 'users_binding.dart';

class UsersFeature {
  static const id = 'users';
  static const viewPermission = 'users.view';

  static VeloraFeature get feature {
    return VeloraFeature(
      id: id,
      name: 'Users',
      permission: viewPermission,
      menuItems: const [VeloraMenuItem(label: 'Users', route: AppRoutes.users)],
      disposers: const [UsersBinding.disposeScope],
    );
  }
}
