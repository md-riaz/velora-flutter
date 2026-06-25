import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../../../resources/theme/claude_colors.dart';
import 'settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

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
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ----------------------------------------------------------------
          // Appearance
          // ----------------------------------------------------------------
          _SectionHeader(label: 'Appearance', textTheme: textTheme),
          _AppearanceSection(controller: controller, scheme: scheme, textTheme: textTheme),

          // ----------------------------------------------------------------
          // Features
          // ----------------------------------------------------------------
          _SectionHeader(label: 'Features', textTheme: textTheme),
          _FeaturesSection(controller: controller),

          // ----------------------------------------------------------------
          // About
          // ----------------------------------------------------------------
          _SectionHeader(label: 'About', textTheme: textTheme),
          _AboutSection(scheme: scheme, textTheme: textTheme),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance section
// ---------------------------------------------------------------------------

class _AppearanceSection extends StatelessWidget {
  final SettingsController controller;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _AppearanceSection({
    required this.controller,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = Velora.theme.current;
      return Column(
        children: [
          _ThemeOption(
            label: 'System default',
            icon: Icons.brightness_auto_outlined,
            value: ThemeMode.system,
            groupValue: current,
            onChanged: controller.setTheme,
            scheme: scheme,
            textTheme: textTheme,
          ),
          _ThemeOption(
            label: 'Light',
            icon: Icons.light_mode_outlined,
            value: ThemeMode.light,
            groupValue: current,
            onChanged: controller.setTheme,
            scheme: scheme,
            textTheme: textTheme,
          ),
          _ThemeOption(
            label: 'Dark',
            icon: Icons.dark_mode_outlined,
            value: ThemeMode.dark,
            groupValue: current,
            onChanged: controller.setTheme,
            scheme: scheme,
            textTheme: textTheme,
          ),
        ],
      );
    });
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? ClaudeColors.primary : scheme.onSurfaceVariant,
      ),
      title: Text(label, style: textTheme.bodyMedium),
      trailing: selected
          ? Icon(Icons.check_circle, color: ClaudeColors.primary, size: 20)
          : Icon(Icons.circle_outlined, color: scheme.outlineVariant, size: 20),
      onTap: () => onChanged(value),
    );
  }
}

// ---------------------------------------------------------------------------
// Features section
// ---------------------------------------------------------------------------

class _FeaturesSection extends StatelessWidget {
  final SettingsController controller;
  const _FeaturesSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      // Reading Velora.feature._enabled triggers rebuild via RxSet.
      // We call isEnabled() in the builder which reads from the reactive set.
      return Column(
        children: SettingsController.demoFeatures.map((f) {
          final enabled = controller.isEnabled(f.id);
          return SwitchListTile.adaptive(
            value: enabled,
            onChanged: (_) => controller.toggle(f.id),
            title: Text(f.label, style: textTheme.bodyMedium),
            subtitle: Text(
              f.description,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            activeThumbColor: ClaudeColors.primary,
            activeTrackColor: ClaudeColors.primary.withAlpha(128),
          );
        }).toList(),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// About section
// ---------------------------------------------------------------------------

class _AboutSection extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _AboutSection({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Demo app', style: textTheme.bodyMedium),
          trailing: Text(
            'v1.0.0',
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        ListTile(
          title: Text('Velora Flutter SDK', style: textTheme.bodyMedium),
          trailing: Text(
            '1.0.0',
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        ListTile(
          title: Text('Open source licenses', style: textTheme.bodyMedium),
          trailing: Icon(
            Icons.chevron_right,
            color: scheme.onSurfaceVariant,
          ),
          onTap: () => showLicensePage(context: context),
        ),
      ],
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
