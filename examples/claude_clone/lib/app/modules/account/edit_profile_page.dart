import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../resources/theme/claude_colors.dart';
import 'edit_profile_controller.dart';

class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Velora.nav.back(),
        ),
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // VeloraFormController info banner
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: ClaudeColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ClaudeColors.primary.withAlpha(45)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.code, size: 16, color: ClaudeColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This form uses VeloraFormController — submit with '
                      'blank or invalid fields to see server-side validation '
                      'errors rendered inline.',
                      style: textTheme.bodySmall
                          ?.copyWith(color: ClaudeColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Name field
            _FieldLabel(label: 'Display name', textTheme: textTheme, scheme: scheme),
            const SizedBox(height: 6),
            Obx(() {
              final nameError = controller.firstError('name');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller.nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDec(
                      scheme: scheme,
                      hint: 'Alex Chen',
                      icon: Icons.person_outline,
                      hasError: nameError != null,
                    ),
                  ),
                  if (nameError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      nameError,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              );
            }),

            const SizedBox(height: 16),

            // Email field
            _FieldLabel(label: 'Email', textTheme: textTheme, scheme: scheme),
            const SizedBox(height: 6),
            Obx(() {
              final emailError = controller.firstError('email');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.save(),
                    decoration: _inputDec(
                      scheme: scheme,
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      hasError: emailError != null,
                    ),
                  ),
                  if (emailError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      emailError,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              );
            }),

            const SizedBox(height: 28),

            // Save button
            Obx(() {
              final loading = controller.loading.value;
              return FilledButton(
                onPressed: loading ? null : controller.save,
                style: FilledButton.styleFrom(
                  backgroundColor: ClaudeColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required ColorScheme scheme,
    required String hint,
    required IconData icon,
    bool hasError = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? scheme.error : scheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? scheme.error : ClaudeColors.primary,
          width: 2,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final TextTheme textTheme;
  final ColorScheme scheme;

  const _FieldLabel({
    required this.label,
    required this.textTheme,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );
  }
}
