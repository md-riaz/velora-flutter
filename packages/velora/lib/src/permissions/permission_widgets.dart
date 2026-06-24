import 'package:flutter/widgets.dart';

import '../core/velora_facade.dart';

class Can extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const Can({
    required this.permission,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Velora.permission.can(permission) ? child : fallback ?? const SizedBox.shrink();
  }
}

class RoleOnly extends StatelessWidget {
  final String role;
  final Widget child;
  final Widget? fallback;

  const RoleOnly({
    required this.role,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Velora.permission.hasRole(role) ? child : fallback ?? const SizedBox.shrink();
  }
}
