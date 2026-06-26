import 'package:velora/velora.dart';

import '../../routes/app_routes.dart';

/// Demonstrates [AuthService] patterns in Velora.
///
/// In a real app:
///   1. Call [Velora.login] with credentials — it stores the token and user.
///   2. Access the current user via [Velora.user] or [Velora.userAs<T>()].
///   3. Call [Velora.logout] to clear the session.
///   4. Guard routes with [Velora.authOnly] middleware.
class AccountController extends VeloraController {
  bool get isAuthenticated => Velora.auth.isAuthenticated.value;

  VeloraUser? get currentUser => Velora.auth.user;

  /// Fallback user shown when no real session is active.
  static const mockUser = _MockUser(
    name: 'Alex Chen',
    email: 'alex@example.com',
    plan: 'Free',
    roles: ['user'],
  );

  Future<void> signOut() async {
    final confirmed = await Velora.dialog.confirm(
      title: 'Sign out',
      message: 'Are you sure you want to sign out?',
    );
    if (!confirmed) return;
    // Direct state reset — no HTTP call. The session was created by mock login,
    // so there is no real token to revoke and no remote endpoint to call.
    Velora.auth.currentUser.value = null;
    Velora.auth.state.value = SessionState.guest;
    Velora.notify.notifications.clear();
    Velora.notify.unreadCount.value = 0;
    Velora.nav.offAll(AppRoutes.login);
  }
}

class _MockUser {
  final String name;
  final String email;
  final String plan;
  final List<String> roles;

  const _MockUser({
    required this.name,
    required this.email,
    required this.plan,
    required this.roles,
  });
}
