import 'package:velora/velora.dart';

/// Demonstrates [AuthService] patterns in Velora.
///
/// In this demo app the user is not authenticated, so [Velora.auth.check]
/// is false.  The controller shows mock profile data alongside explanations
/// of the auth API for developers studying the demo.
///
/// In a real app:
///   1. Call [Velora.login] with credentials — it stores the token and user.
///   2. Access the current user via [Velora.user] or [Velora.userAs<T>()].
///   3. Call [Velora.logout] to clear the session.
///   4. Guard routes with [Velora.authOnly] middleware.
class AccountController extends VeloraController {
  bool get isAuthenticated => Velora.auth.isAuthenticated.value;

  VeloraUser? get currentUser => Velora.auth.user;

  /// Demo user displayed when no real session is active.
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
    if (isAuthenticated) {
      await Velora.logout();
    } else {
      Velora.toast.info('Sign out called — no real session in demo');
    }
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
