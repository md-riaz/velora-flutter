import 'package:get/get.dart';

import '../auth/auth_service.dart';
import '../auth/auth_user.dart';

class PermissionService extends GetxService {
  final AuthService auth;
  final bool Function(AuthUser user, String permission)? _resolver;

  PermissionService({
    required this.auth,
    bool Function(AuthUser user, String permission)? permissionResolver,
  }) : _resolver = permissionResolver;

  /// Returns true if the current user may perform [permission].
  ///
  /// Uses [VeloraAuthConfig.permissionResolver] when configured; otherwise
  /// checks whether [permission] appears in [AuthUser.permissions].
  bool can(String permission) {
    final user = auth.user;
    if (user == null) return false;
    final resolver = _resolver;
    if (resolver != null) return resolver(user, permission);
    return user.permissions.contains(permission);
  }

  bool cannot(String permission) => !can(permission);

  bool hasRole(String role) => auth.user?.roles.contains(role) ?? false;

  bool hasAnyRole(Iterable<String> roles) => roles.any(hasRole);

  bool hasAllPermissions(Iterable<String> permissions) => permissions.every(can);
}
