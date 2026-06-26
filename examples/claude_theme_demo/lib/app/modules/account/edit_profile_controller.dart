import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

/// Demonstrates [VeloraFormController] — the Velora form-layer base class.
///
/// [VeloraFormController.setErrors] populates field-level errors returned by
/// a server (e.g. a Laravel validation response). [firstError] reads the first
/// message for a given field so the UI can show it inline.
class EditProfileController extends VeloraFormController {
  late final TextEditingController nameController;
  late final TextEditingController emailController;

  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = Velora.auth.user;
    nameController = TextEditingController(
      text: user is AuthUser ? user.name : '',
    );
    emailController = TextEditingController(
      text: user is AuthUser ? user.email : '',
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    clearErrors();
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    // Simulate server-side validation returning field errors (as a real
    // Laravel API would via 422 Unprocessable Entity).
    final fieldErrors = <String, List<String>>{};
    if (name.isEmpty) fieldErrors['name'] = ['The name field is required.'];
    if (email.isEmpty) {
      fieldErrors['email'] = ['The email field is required.'];
    } else if (!email.contains('@')) {
      fieldErrors['email'] = ['The email must be a valid email address.'];
    }

    if (fieldErrors.isNotEmpty) {
      setErrors(fieldErrors);
      return;
    }

    loading.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final current = Velora.auth.user;
      if (current is AuthUser) {
        Velora.auth.currentUser.value = AuthUser(
          id: current.id,
          name: name,
          email: email,
          roles: current.roles,
          permissions: current.permissions,
          features: current.features,
        );
      }
      Velora.toast.success('Profile updated');
      Velora.nav.back();
    } catch (e) {
      Velora.toast.error(e.toString());
    } finally {
      loading.value = false;
    }
  }
}
