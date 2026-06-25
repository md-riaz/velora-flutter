import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../resources/theme/claude_colors.dart';
import 'account_controller.dart';

class AccountPage extends GetView<AccountController> {
  const AccountPage({super.key});

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
        title: const Text('Account'),
      ),
      body: ListView(
        children: [
          // ----------------------------------------------------------------
          // Profile card
          // ----------------------------------------------------------------
          _ProfileCard(
            scheme: scheme,
            textTheme: textTheme,
          ),

          // ----------------------------------------------------------------
          // Session state
          // ----------------------------------------------------------------
          _SectionHeader(label: 'Session', textTheme: textTheme),
          _SessionSection(
            controller: controller,
            scheme: scheme,
            textTheme: textTheme,
          ),

          // ----------------------------------------------------------------
          // Auth API patterns
          // ----------------------------------------------------------------
          _SectionHeader(label: 'SDK Patterns', textTheme: textTheme),
          _SdkPatternsSection(scheme: scheme, textTheme: textTheme),

          // ----------------------------------------------------------------
          // Actions
          // ----------------------------------------------------------------
          _SectionHeader(label: 'Actions', textTheme: textTheme),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: controller.signOut,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _ProfileCard({
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final user = AccountController.mockUser;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ClaudeColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                user.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                _PlanBadge(plan: user.plan),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    final isPro = plan.toLowerCase() == 'pro';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPro
            ? ClaudeColors.primary.withAlpha(26)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPro
              ? ClaudeColors.primary.withAlpha(77)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        plan,
        style: TextStyle(
          color: isPro
              ? ClaudeColors.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session section
// ---------------------------------------------------------------------------

class _SessionSection extends StatelessWidget {
  final AccountController controller;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _SessionSection({
    required this.controller,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isAuth = controller.isAuthenticated;
      final stateLabel = isAuth ? 'Authenticated' : 'Guest (demo mode)';
      final stateColor = isAuth ? Colors.green : scheme.onSurfaceVariant;

      return Column(
        children: [
          ListTile(
            title: Text('Auth state', style: textTheme.bodyMedium),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: stateColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  stateLabel,
                  style: textTheme.bodySmall?.copyWith(color: stateColor),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text('User object', style: textTheme.bodyMedium),
            trailing: Text(
              controller.currentUser != null ? 'VeloraUser' : 'null',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (!isAuth)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  'No active session — profile data above is mock. '
                  'Call Velora.login() to authenticate and populate Velora.auth.user.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// SDK patterns section
// ---------------------------------------------------------------------------

class _SdkPatternsSection extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _SdkPatternsSection({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CodeCard(
          title: 'Login',
          code: 'await Velora.login({\n'
              "  'email': email,\n"
              "  'password': password,\n"
              '});',
          scheme: scheme,
          textTheme: textTheme,
        ),
        _CodeCard(
          title: 'Access current user',
          code: 'final user = Velora.user;\n'
              '// or cast to your model:\n'
              'final appUser = Velora.userAs<AppUser>();',
          scheme: scheme,
          textTheme: textTheme,
        ),
        _CodeCard(
          title: 'Guard routes',
          code: 'GetPage(\n'
              "  name: '/home',\n"
              '  page: () => HomePage(),\n'
              '  middlewares: Velora.authOnly,\n'
              ')',
          scheme: scheme,
          textTheme: textTheme,
        ),
        _CodeCard(
          title: 'React to auth state',
          code: 'Obx(() {\n'
              '  if (!Velora.auth.isAuthenticated.value)\n'
              "    return LoginPrompt();\n"
              '  return ProfileBody();\n'
              '})',
          scheme: scheme,
          textTheme: textTheme,
        ),
        _CodeCard(
          title: 'Custom user model',
          code: 'class AppUser implements VeloraUser {\n'
              '  // your fields ...\n'
              '  static AppUser fromJson(Map<String, dynamic> j) => ...;\n'
              '}\n\n'
              '// Configure in VeloraAuthConfig:\n'
              'VeloraAuthConfig(userParser: AppUser.fromJson)',
          scheme: scheme,
          textTheme: textTheme,
        ),
      ],
    );
  }
}

class _CodeCard extends StatelessWidget {
  final String title;
  final String code;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _CodeCard({
    required this.title,
    required this.code,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  final TextTheme textTheme;
  const _SectionHeader({required this.label, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
