import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../resources/theme/claude_colors.dart';
import '../settings/settings_controller.dart';
import 'login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),

              // Logo + title
              Center(
                child: Column(
                  children: [
                    _ClaudeLogo(size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to Claude',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in to your account',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Demo notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ClaudeColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ClaudeColors.primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: ClaudeColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo mode — any email works. No real backend.',
                        style: textTheme.bodySmall?.copyWith(
                          color: ClaudeColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Email field
              _FieldLabel(label: 'Email', textTheme: textTheme, scheme: scheme),
              const SizedBox(height: 6),
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _inputDec(
                  scheme: scheme,
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 16),

              // Password field
              _FieldLabel(label: 'Password', textTheme: textTheme, scheme: scheme),
              const SizedBox(height: 6),
              TextField(
                controller: controller.passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => controller.login(),
                decoration: _inputDec(
                  scheme: scheme,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                ),
              ),

              const SizedBox(height: 28),

              // Feature toggles
              _FeatureToggles(
                controller: controller,
                scheme: scheme,
                textTheme: textTheme,
              ),

              const SizedBox(height: 24),

              // Sign in button
              Obx(() {
                final loading = controller.loading.value;
                return FilledButton(
                  onPressed: loading ? null : controller.login,
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
                          'Sign in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              }),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec({
    required ColorScheme scheme,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ClaudeColors.primary, width: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature toggles
// ---------------------------------------------------------------------------

class _FeatureToggles extends StatelessWidget {
  final LoginController controller;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _FeatureToggles({
    required this.controller,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'FEATURES FOR THIS SESSION',
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Admin role toggle — first item, always visible
          _FeatureRow(
            label: 'Admin role',
            description: 'Grants admin role + permissions (enables RoleOnly demo)',
            scheme: scheme,
            textTheme: textTheme,
            valueBuilder: () => controller.loginAsAdmin.value,
            onToggle: () =>
                controller.loginAsAdmin.value = !controller.loginAsAdmin.value,
          ),
          Divider(height: 1, indent: 16, color: scheme.outlineVariant),

          ...SettingsController.demoFeatures.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            final isLast = i == SettingsController.demoFeatures.length - 1;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FeatureRow(
                  label: f.label,
                  description: f.description,
                  scheme: scheme,
                  textTheme: textTheme,
                  isLastInGroup: isLast,
                  valueBuilder: () => controller.featureEnabled(f.id),
                  onToggle: () => controller.toggleFeature(f.id),
                ),
                if (!isLast)
                  Divider(height: 1, indent: 16, color: scheme.outlineVariant),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _FeatureRow extends StatelessWidget {
  final String label;
  final String description;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final bool isLastInGroup;
  final bool Function() valueBuilder;
  final VoidCallback onToggle;

  const _FeatureRow({
    required this.label,
    required this.description,
    required this.scheme,
    required this.textTheme,
    required this.valueBuilder,
    required this.onToggle,
    this.isLastInGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final enabled = valueBuilder();
      return InkWell(
        onTap: onToggle,
        borderRadius: isLastInGroup
            ? const BorderRadius.vertical(bottom: Radius.circular(14))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (_) => onToggle(),
                activeTrackColor: ClaudeColors.primary,
              ),
            ],
          ),
        ),
      );
    });
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

class _ClaudeLogo extends StatelessWidget {
  final double size;
  const _ClaudeLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ClaudeColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(
          'C',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
