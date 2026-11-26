import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

double _luminance(Color color) {
  double linearize(double channel) => channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}

double _contrast(Color a, Color b) {
  final first = _luminance(a);
  final second = _luminance(b);
  return (math.max(first, second) + 0.05) / (math.min(first, second) + 0.05);
}

void main() {
  test('contrast helper matches black and white reference values', () {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    expect(_luminance(black), 0);
    expect(_luminance(white), closeTo(1, 0.000001));
    expect(_contrast(black, white), closeTo(21, 0.000001));
  });

  for (final preset in [
    ThemePreset.aurora,
    ThemePreset.meadow,
    ThemePreset.neutral,
    ThemePreset.corporate,
  ]) {
    for (final brightness in Brightness.values) {
      test('${preset.name} $brightness meets WCAG AA contrast', () {
        final theme = brightness == Brightness.light
            ? preset.light()
            : preset.dark();
        final scheme = theme.colorScheme;
        final status = theme.extension<StatusColors>()!;
        final pairs = <String, (Color, Color)>{
          'primary/onPrimary': (scheme.primary, scheme.onPrimary),
          'secondary/onSecondary': (scheme.secondary, scheme.onSecondary),
          'error/onError': (scheme.error, scheme.onError),
          'surface/onSurface': (scheme.surface, scheme.onSurface),
          'primaryContainer/onPrimaryContainer': (
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
          ),
          'success': (status.success.color, status.success.onColor),
          'warning': (status.warning.color, status.warning.onColor),
          'info': (status.info.color, status.info.onColor),
          'danger': (status.error.color, status.error.onColor),
        };
        for (final entry in pairs.entries) {
          final ratio = _contrast(entry.value.$1, entry.value.$2);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: entry.key);
        }
      });
    }
  }
}
