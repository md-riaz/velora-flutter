import 'package:get/get.dart';

import '../auth/auth_service.dart';

class PermissionService extends GetxService {
  final AuthService auth;

  PermissionService({required this.auth});

  bool can(String permission) => auth.user?.permissions.contains(permission) ?? false;

  bool cannot(String permission) => !can(permission);

  bool hasRole(String role) => auth.user?.roles.contains(role) ?? false;

  bool hasAnyRole(Iterable<String> roles) => roles.any(hasRole);

  bool hasAllPermissions(Iterable<String> permissions) => permissions.every(can);
}
