import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags `Obx(() => Widget(rxField))` arrow-function bodies that pass an
/// Rx-typed value to a child widget constructor without reading `.value`
/// (or any delegated property such as `.isEmpty`, `.length`) anywhere in
/// the builder scope.
///
/// When no reactive property is read inside an Obx builder, GetX registers
/// no subscription and throws an "improper use" error.  In release mode the
/// Obx becomes an ErrorWidget that claims infinite height, collapsing any
/// sibling [Expanded] child to zero — producing a blank grey area.
///
/// ## Wrong
/// ```dart
/// Obx(() => VeloraAttachmentStrip(attachments: controller.attachments))
/// ```
///
/// ## Correct
/// ```dart
/// Obx(() {
///   if (controller.attachments.isEmpty) return const SizedBox.shrink();
///   return VeloraAttachmentStrip(attachments: controller.attachments);
/// })
/// ```
class ObxMissingReactiveRead extends DartLintRule {
  const ObxMissingReactiveRead() : super(code: _code);

  static const _code = LintCode(
    name: 'obx_missing_reactive_read',
    problemMessage:
        'An Rx-typed value is passed to a widget inside an Obx arrow-function '
        'body without any reactive property read (.value, .isEmpty, etc.). '
        'No subscription is registered — the widget will never rebuild.',
    correctionMessage:
        'Use a block body and guard with a reactive read (e.g. .isEmpty) '
        'before passing the Rx object to the child widget.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      // Only care about Obx(...) construction.
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName != 'Obx') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      // Builder is the first positional argument.
      final firstArg = args.first is NamedExpression
          ? (args.first as NamedExpression).expression
          : args.first;

      if (firstArg is! FunctionExpression) return;

      // Only flag arrow (expression) bodies — block bodies are assumed to
      // guard subscriptions explicitly.
      final body = firstArg.body;
      if (body is! ExpressionFunctionBody) return;

      // The expression must be a widget constructor call.
      final expr = body.expression;
      if (expr is! InstanceCreationExpression) return;

      for (final arg in expr.argumentList.arguments) {
        final valueExpr =
            arg is NamedExpression ? arg.expression : arg as Expression;
        final type = valueExpr.staticType;
        if (type != null && _isGetxRxType(type)) {
          reporter.reportErrorForNode(_code, valueExpr);
        }
      }
    });
  }

  static bool _isGetxRxType(DartType type) {
    final element = type.element;
    if (element == null) return false;
    final name = element.name ?? '';
    if (!name.startsWith('Rx') && name != 'GetListenable') return false;
    final uri = element.library?.source.uri.toString() ?? '';
    return uri.contains('package:get/');
  }
}
