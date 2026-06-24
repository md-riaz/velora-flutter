import 'package:get/get.dart';

import '../auth/auth_service.dart';
import '../config/velora_config.dart';

/// Synchronous route guard. Return a redirect route to block navigation,
/// or null to allow it through.
///
/// Guards run against the current reactive auth state, so they are always
/// up to date without an async call.
///
/// ```dart
/// GetPage(
///   name: '/dashboard',
///   page: () => DashboardPage(),
///   middlewares: Velora.guard([VeloraAuthGuard()]),
/// )
/// ```
abstract class VeloraRouteGuard {
  const VeloraRouteGuard();

  /// Called before the route is entered. Return a route name to redirect,
  /// or null to allow through.
  String? redirect(String route);
}

/// Redirects unauthenticated users to the login route.
///
/// Reads [VeloraAuthConfig.logoutRedirectRoute] from the registered config.
class VeloraAuthGuard extends VeloraRouteGuard {
  const VeloraAuthGuard();

  @override
  String? redirect(String route) {
    try {
      final auth = Get.find<AuthService>();
      if (auth.isAuthenticated.value) return null;
      final cfg = Get.find<VeloraConfig>();
      return cfg.auth.logoutRedirectRoute;
    } catch (_) {
      // AuthService not registered — Velora.boot() was not called.
      // Allow navigation so UI-only demos and tests work without full boot.
      return null;
    }
  }
}

/// Redirects already-authenticated users away from guest-only routes (e.g.
/// login, register). Defaults to redirecting to '/'.
class VeloraGuestGuard extends VeloraRouteGuard {
  final String authenticatedRoute;

  const VeloraGuestGuard({this.authenticatedRoute = '/'});

  @override
  String? redirect(String route) {
    try {
      final auth = Get.find<AuthService>();
      return auth.isAuthenticated.value ? authenticatedRoute : null;
    } catch (_) {
      return null;
    }
  }
}

/// GetX [GetMiddleware] that chains one or more [VeloraRouteGuard]s.
///
/// Guards are evaluated in order; the first non-null redirect wins.
class VeloraMiddleware extends GetMiddleware {
  final List<VeloraRouteGuard> guards;

  VeloraMiddleware({required this.guards, super.priority = 1});

  @override
  RouteSettings? redirect(String? route) {
    for (final guard in guards) {
      final to = guard.redirect(route ?? '');
      if (to != null) return RouteSettings(name: to);
    }
    return null;
  }
}
