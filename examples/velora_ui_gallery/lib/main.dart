import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

import 'sections/display_section.dart';
import 'sections/inputs_section.dart';
import 'sections/layout_section.dart';
import 'sections/nav_section.dart';

void main() => runApp(const GalleryApp());

/// The velora_ui component gallery — a single scrollable screen showcasing
/// every Layer 2-5 component, with a light/dark toggle and an
/// aurora/meadow theme-preset toggle in the app bar.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  bool _dark = false;
  VeloraThemePreset _preset = VeloraThemePreset.aurora;

  void _toggleBrightness() {
    setState(() => _dark = !_dark);
  }

  void _togglePreset() {
    setState(() {
      _preset = _preset == VeloraThemePreset.aurora
          ? VeloraThemePreset.meadow
          : VeloraThemePreset.aurora;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora UI Gallery',
      theme: buildVeloraTheme(preset: _preset),
      darkTheme: buildVeloraTheme(brightness: Brightness.dark, preset: _preset),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: GalleryHomePage(
        dark: _dark,
        preset: _preset,
        onToggleBrightness: _toggleBrightness,
        onTogglePreset: _togglePreset,
      ),
    );
  }
}

/// The gallery's single screen: an [AppBar] with the light/dark and
/// aurora/meadow toggles, and a scrollable body listing every showcase
/// section.
class GalleryHomePage extends StatelessWidget {
  /// Creates the gallery's home page.
  const GalleryHomePage({
    super.key,
    required this.dark,
    required this.preset,
    required this.onToggleBrightness,
    required this.onTogglePreset,
  });

  /// Whether the app is currently in dark mode.
  final bool dark;

  /// The active theme preset.
  final VeloraThemePreset preset;

  /// Called when the brightness (sun/moon) action is tapped.
  final VoidCallback onToggleBrightness;

  /// Called when the preset action is tapped.
  final VoidCallback onTogglePreset;

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final otherPreset = preset == VeloraThemePreset.aurora
        ? VeloraThemePreset.meadow
        : VeloraThemePreset.aurora;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Velora UI Gallery'),
        actions: [
          IconButton(
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: onToggleBrightness,
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Switch to ${otherPreset.name}',
            onPressed: onTogglePreset,
          ),
          SizedBox(width: tokens.spacingSm),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(tokens.spacingMd),
          children: [
            Text(
              '${preset.name} · ${dark ? 'Dark' : 'Light'}',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spacingMd),
            const DisplaySection(),
            SizedBox(height: tokens.spacingLg),
            const VeloraDivider(),
            SizedBox(height: tokens.spacingLg),
            const InputsSection(),
            SizedBox(height: tokens.spacingLg),
            const VeloraDivider(),
            SizedBox(height: tokens.spacingLg),
            const LayoutSection(),
            SizedBox(height: tokens.spacingLg),
            const VeloraDivider(),
            SizedBox(height: tokens.spacingLg),
            const NavSection(),
            SizedBox(height: tokens.spacingXl),
          ],
        ),
      ),
    );
  }
}
