import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ui_file.dart';

class HardcodedUiColor extends DartLintRule {
  const HardcodedUiColor() : super(code: _code);

  static const _code = LintCode(
    name: 'hardcoded_ui_color',
    problemMessage: 'Avoid hardcoded UI colors.',
    correctionMessage:
        'Use Theme.of(context).colorScheme or StatusColors.of(context).',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!isUiFile(resolver.path, includeModules: true)) return;
    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors' &&
          node.identifier.name != 'transparent') {
        reporter.reportErrorForNode(_code, node);
      }
    });
    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.type.name2.lexeme != 'Color' ||
          node.constructorName.name != null ||
          node.argumentList.arguments.length != 1)
        return;
      final argument = node.argumentList.arguments.single;
      if (argument is IntegerLiteral &&
          argument.literal.lexeme.toLowerCase().startsWith('0x')) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }
}
