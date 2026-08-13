import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

void main() {
  group('buildVeloraTheme font resolution', () {
    test(
      'defaults to the bundled brand faces (Inter body, Space Grotesk display)',
      () {
        final t = buildVeloraTheme();
        expect(t.textTheme.bodyMedium?.fontFamily, 'packages/velora_ui/Inter');
        expect(
          t.textTheme.headlineLarge?.fontFamily,
          'packages/velora_ui/SpaceGrotesk',
        );
        expect(
          t.textTheme.titleLarge?.fontFamily,
          'packages/velora_ui/SpaceGrotesk',
        );
      },
    );

    test(
      'a lone fontFamily override drives the whole theme (body + display)',
      () {
        final t = buildVeloraTheme(fontFamily: 'Acme');
        expect(t.textTheme.bodyMedium?.fontFamily, 'Acme');
        expect(t.textTheme.headlineLarge?.fontFamily, 'Acme');
        expect(t.textTheme.titleLarge?.fontFamily, 'Acme');
        expect(t.textTheme.labelLarge?.fontFamily, 'Acme');
      },
    );

    test('explicit null drops the brand faces (no forced family)', () {
      // At the theme level the merged Typography may still supply a platform
      // family, but Velora must not force its own brand faces.
      final t = buildVeloraTheme(fontFamily: null);
      expect(
        t.textTheme.headlineLarge?.fontFamily,
        isNot('packages/velora_ui/SpaceGrotesk'),
      );
      expect(
        t.textTheme.bodyMedium?.fontFamily,
        isNot('packages/velora_ui/Inter'),
      );
    });

    test('veloraTextTheme leaves families null when none are supplied', () {
      final tt = veloraTextTheme(fontFamily: null);
      expect(tt.bodyMedium?.fontFamily, isNull);
      expect(tt.displayLarge?.fontFamily, isNull);
    });

    test('displayFontFamily overrides only the display voice', () {
      final t = buildVeloraTheme(fontFamily: 'Body', displayFontFamily: 'Disp');
      expect(t.textTheme.bodyMedium?.fontFamily, 'Body');
      expect(t.textTheme.labelLarge?.fontFamily, 'Body');
      expect(t.textTheme.headlineLarge?.fontFamily, 'Disp');
      expect(t.textTheme.titleLarge?.fontFamily, 'Disp');
    });
  });
}
