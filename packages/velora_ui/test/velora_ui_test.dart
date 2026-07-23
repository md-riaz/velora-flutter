import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

void main() {
  group('VeloraTokens.copyWith', () {
    test('overrides only the given fields', () {
      const base = VeloraTokens.light;
      final updated = base.copyWith(
        spacingMd: 20,
        success: const Color(0xFF00FF00),
      );

      expect(updated.spacingMd, 20);
      expect(updated.success, const Color(0xFF00FF00));

      // Everything else is untouched.
      expect(updated.spacingXs, base.spacingXs);
      expect(updated.spacingSm, base.spacingSm);
      expect(updated.spacingLg, base.spacingLg);
      expect(updated.spacingXl, base.spacingXl);
      expect(updated.spacingXxl, base.spacingXxl);
      expect(updated.radiusSm, base.radiusSm);
      expect(updated.radiusMd, base.radiusMd);
      expect(updated.radiusLg, base.radiusLg);
      expect(updated.radiusPill, base.radiusPill);
      expect(updated.onSuccess, base.onSuccess);
      expect(updated.warning, base.warning);
      expect(updated.onWarning, base.onWarning);
      expect(updated.info, base.info);
      expect(updated.onInfo, base.onInfo);
      expect(updated.elevation1, base.elevation1);
      expect(updated.elevation2, base.elevation2);
      expect(updated.elevation3, base.elevation3);
      expect(updated.elevation4, base.elevation4);
      expect(updated.shadowSm, base.shadowSm);
      expect(updated.shadowMd, base.shadowMd);
      expect(updated.motionFast, base.motionFast);
      expect(updated.motionNormal, base.motionNormal);
      expect(updated.motionSlow, base.motionSlow);
    });
  });

  group('VeloraTokens.lerp', () {
    test('t=0 returns the starting endpoint', () {
      final result = VeloraTokens.light.lerp(VeloraTokens.dark, 0);
      expect(result.spacingMd, VeloraTokens.light.spacingMd);
      expect(result.success, VeloraTokens.light.success);
      expect(result.motionNormal, VeloraTokens.light.motionNormal);
    });

    test('t=1 returns the ending endpoint', () {
      final result = VeloraTokens.light.lerp(VeloraTokens.dark, 1);
      expect(result.spacingMd, VeloraTokens.dark.spacingMd);
      expect(result.success, VeloraTokens.dark.success);
      expect(result.motionNormal, VeloraTokens.dark.motionNormal);
    });

    test('t=0.5 interpolates a double and a color', () {
      const a = VeloraTokens.light;
      const b = VeloraTokens(
        spacingXs: 4,
        spacingSm: 8,
        spacingMd: 30, // light is 16 -> midpoint 23
        spacingLg: 24,
        spacingXl: 32,
        spacingXxl: 48,
        radiusSm: 4,
        radiusMd: 8,
        radiusLg: 16,
        radiusPill: 999,
        success: Color(0xFF000000), // light success is 0xFF1E7D46
        onSuccess: Color(0xFFFFFFFF),
        warning: Color(0xFF8A5300),
        onWarning: Color(0xFFFFFFFF),
        info: Color(0xFF1A5FB4),
        onInfo: Color(0xFFFFFFFF),
        elevation1: 1,
        elevation2: 3,
        elevation3: 6,
        elevation4: 8,
        shadowSm: [],
        shadowMd: [],
        motionFast: Duration(milliseconds: 120),
        motionNormal: Duration(milliseconds: 220),
        motionSlow: Duration(milliseconds: 360),
      );

      final result = a.lerp(b, 0.5);
      expect(result.spacingMd, closeTo(23, 0.001));
      expect(result.success, Color.lerp(a.success, b.success, 0.5));
    });

    test('lerp returns `this` unchanged when other is not a VeloraTokens', () {
      final result = VeloraTokens.light.lerp(null, 0.5);
      expect(result, VeloraTokens.light);
    });
  });

  group('buildVeloraTheme', () {
    test('light brightness carries VeloraTokens and matching ColorScheme', () {
      final theme = buildVeloraTheme();
      expect(theme.extension<VeloraTokens>(), isNotNull);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark brightness carries VeloraTokens and matching ColorScheme', () {
      final theme = buildVeloraTheme(brightness: Brightness.dark);
      expect(theme.extension<VeloraTokens>(), isNotNull);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light and dark themes differ', () {
      final light = buildVeloraTheme();
      final dark = buildVeloraTheme(brightness: Brightness.dark);
      expect(light.colorScheme, isNot(dark.colorScheme));
      expect(
        light.extension<VeloraTokens>()!.success,
        isNot(dark.extension<VeloraTokens>()!.success),
      );
    });

    test('VeloraTheme.light()/.dark() mirror buildVeloraTheme', () {
      expect(VeloraTheme.light().colorScheme.brightness, Brightness.light);
      expect(VeloraTheme.dark().colorScheme.brightness, Brightness.dark);
    });
  });

  group('context.veloraTokens', () {
    testWidgets('returns the tokens when a Velora theme is applied', (
      tester,
    ) async {
      late VeloraTokens tokensFromContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: VeloraTheme.light(),
          home: Builder(
            builder: (context) {
              tokensFromContext = context.veloraTokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tokensFromContext, VeloraTokens.light);
    });
  });
}
