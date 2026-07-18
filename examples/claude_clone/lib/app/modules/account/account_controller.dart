import 'package:velora/velora.dart';

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
    // Delegate to the framework's logout so every user-scoped service
    // (notifications, feature flags, in-flight requests, navigation) is torn
    // down through the LogoutCoordinator — instead of this module hand-resetting
    // another module's state. The remote logout call is best-effort and is
    // skipped/ignored when offline or unauthenticated.
    await Velora.logout();
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
