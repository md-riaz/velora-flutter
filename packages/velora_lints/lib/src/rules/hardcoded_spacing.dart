import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'ui_file.dart';

class HardcodedSpacing extends DartLintRule {
  const HardcodedSpacing() : super(code: _code);

  static const _code = LintCode(
    name: 'hardcoded_spacing',
    problemMessage: 'Avoid hardcoded UI spacing.',
    correctionMessage: 'Use DesignTokens.of(context).',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!isUiFile(resolver.path)) return;
    context.registry.addInstanceCreationExpression((node) {
      final type = node.constructorName.type.name2.lexeme;
      final constructor = node.constructorName.name?.name;
      final edgeInsets =
          type == 'EdgeInsets' &&
          {'all', 'symmetric', 'only'}.contains(constructor);
      final sizedBox = type == 'SizedBox' && constructor == null;
      if (!edgeInsets && !sizedBox) return;
      for (final argument in node.argumentList.arguments) {
        if (sizedBox &&
            (argument is! NamedExpression ||
                !{'width', 'height'}.contains(argument.name.label.name)))
          continue;
        final value = argument is NamedExpression
            ? argument.expression
            : argument;
        final literal =
            value is PrefixExpression && value.operator.lexeme == '-'
            ? value.operand
            : value;
        if ((literal is IntegerLiteral && literal.value != 0) ||
            (literal is DoubleLiteral && literal.value != 0)) {
          reporter.reportErrorForNode(_code, value);
        }
      }
    });
  }
}
