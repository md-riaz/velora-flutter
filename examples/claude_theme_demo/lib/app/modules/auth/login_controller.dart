import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../routes/app_routes.dart';
import '../settings/settings_controller.dart';

/// Demonstrates the Velora auth flow with a mock (no real backend).
///
/// In production, replace [_mockLogin] with [Velora.login(credentials)].
/// Feature flags toggled here persist for the session and are visible on
/// the Settings page.
class LoginController extends VeloraController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  bool featureEnabled(String id) => Velora.feature.enabled(id);

  void toggleFeature(String id) {
    if (Velora.feature.enabled(id)) {
      Velora.feature.disable(id);
    } else {
      Velora.feature.enable(id);
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Velora.toast.error('Enter an email to continue');
      return;
    }
    await run(() => _mockLogin(email));
    if (error.value.isNotEmpty) return;
    Velora.nav.offAll(AppRoutes.home);
  }

  Future<void> _mockLogin(String email) async {
    // Simulate network latency so the loading state is exercised.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final name = email.contains('@') ? email.split('@').first : email;
    final enabledFeatures = SettingsController.demoFeatures
        .where((f) => Velora.feature.enabled(f.id))
        .map((f) => f.id)
        .toList();
    Velora.auth.currentUser.value = AuthUser(
      id: 1,
      name: _capitalise(name),
      email: email,
      roles: const ['user'],
      features: enabledFeatures,
    );
    Velora.auth.state.value = SessionState.authenticated;
  }

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
