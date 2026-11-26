import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';
import 'package:velora_lints/src/rules/hardcoded_spacing.dart';
import 'package:velora_lints/src/rules/hardcoded_ui_color.dart';

const source = '''
class Colors {
  static const red = 1;
  static const transparent = 0;
}
class Color { const Color(int value); }
class EdgeInsets {
  const EdgeInsets.all(num value);
  const EdgeInsets.symmetric({num? horizontal, num? vertical});
  const EdgeInsets.only({num? left, num? right});
}
class SizedBox { const SizedBox({num? width, num? height, Object? child}); }
void example(num dynamicValue) {
  Colors.red;
  Colors.transparent;
  const Color(0xFF00FF00);
  const Color(123);
  const EdgeInsets.all(8);
  const EdgeInsets.symmetric(horizontal: 0, vertical: 2.5);
  const EdgeInsets.only(left: -4, right: 0.0);
  const SizedBox(width: 10, height: 0);
  SizedBox(width: dynamicValue, child: 12);
}
''';

Future<List<AnalysisError>> runRule(DartLintRule rule, String path) async {
  final workspace = Directory.systemTemp.createTempSync('velora_ui_lints_');
  addTearDown(() => workspace.deleteSync(recursive: true));
  final file = File.fromUri(workspace.uri.resolve(path));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(source);
  return rule.testAnalyzeAndRun(file);
}

void main() {
  test('color rule detects colors and hex literals in UI files', () async {
    for (final path in [
      'lib/pages/home.dart',
      'lib/modules/home.dart',
      'lib/home_widget.dart',
    ]) {
      final errors = await runRule(const HardcodedUiColor(), path);
      expect(errors.map((e) => e.errorCode.name), [
        'hardcoded_ui_color',
        'hardcoded_ui_color',
      ]);
      expect(
        errors.every((e) => e.errorCode.errorSeverity == ErrorSeverity.WARNING),
        isTrue,
      );
    }
  });

  test('spacing rule detects nonzero numeric spacing in UI files', () async {
    for (final path in ['lib/widgets/home.dart', 'lib/home_page.dart']) {
      final errors = await runRule(const HardcodedSpacing(), path);
      expect(
        errors.map((e) => e.errorCode.name),
        List.filled(4, 'hardcoded_spacing'),
      );
      expect(
        errors.every((e) => e.errorCode.errorSeverity == ErrorSeverity.WARNING),
        isTrue,
      );
    }
  });

  test('excludes theme, tests, and non UI files', () async {
    for (final path in [
      'lib/resources/theme/widgets/home_page.dart',
      'test/widgets/home_page.dart',
      'lib/data/home.dart',
    ]) {
      expect(await runRule(const HardcodedUiColor(), path), isEmpty);
      expect(await runRule(const HardcodedSpacing(), path), isEmpty);
    }
    expect(
      await runRule(const HardcodedSpacing(), 'lib/modules/home.dart'),
      isEmpty,
    );
  });
}
