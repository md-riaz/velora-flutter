import 'package:flutter/widgets.dart';
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
///
/// ## Fail-closed behaviour
///
/// If [AuthService] is registered but the authentication check throws, the
/// guard **denies** access (redirects to [fallbackRoute]) rather than letting
/// the request through — an authentication control must never fail open. The
/// guard only allows navigation without a check when Velora has not been booted
/// at all (no [AuthService] registered), which is the intended affordance for
/// UI-only demos and widget tests.
class VeloraAuthGuard extends VeloraRouteGuard {
  /// Route to redirect to when the auth check cannot be completed. Used only if
  /// the registered [VeloraConfig] is also unavailable.
  final String fallbackRoute;

  const VeloraAuthGuard({this.fallbackRoute = '/login'});

  @override
  String? redirect(String route) {
    // Not booted at all → dev/UI-only mode: allow through.
    if (!Get.isRegistered<AuthService>()) return null;

    try {
      final auth = Get.find<AuthService>();
      if (auth.isAuthenticated.value) return null;
      return _loginRoute();
    } catch (_) {
      // Booted, but the check failed — fail closed.
      return _loginRoute();
    }
  }

  String _loginRoute() {
    try {
      return Get.find<VeloraConfig>().auth.logoutRedirectRoute;
    } catch (_) {
      return fallbackRoute;
    }
  }
}

/// Redirects already-authenticated users away from guest-only routes (e.g.
/// login, register). Defaults to redirecting to '/'.
///
/// A guest guard failing open (letting an authenticated user reach a guest
/// route) is not a security risk, so when booted-but-erroring it defaults to
/// allowing the guest route through.
class VeloraGuestGuard extends VeloraRouteGuard {
  final String authenticatedRoute;

  const VeloraGuestGuard({this.authenticatedRoute = '/'});

  @override
  String? redirect(String route) {
    if (!Get.isRegistered<AuthService>()) return null;
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
