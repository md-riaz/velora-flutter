import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags direct `.value` reads on GetX `Rx` fields inside a widget's
/// `build()` method when the read is not enclosed in an `Obx`, `GetX`,
/// or `GetBuilder` reactive scope.
///
/// Reading `.value` outside a reactive scope captures the value once at
/// build time; when the observable changes the widget is never scheduled
/// for rebuild.
///
/// ## Wrong
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Text(controller.title.value); // stale after first render
/// }
/// ```
///
/// ## Correct
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return Obx(() => Text(controller.title.value));
/// }
/// ```
class RxInBuildWithoutObx extends DartLintRule {
  const RxInBuildWithoutObx() : super(code: _code);

  static const _code = LintCode(
    name: 'rx_in_build_without_obx',
    problemMessage:
        "'.value' read on an Rx type inside build() without a reactive scope "
        '(Obx/GetX/GetBuilder) — the widget reads the value once and never '
        'rebuilds when it changes.',
    correctionMessage:
        'Wrap the expression in Obx(() => ...) or move it inside a '
        'GetX/GetBuilder builder.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const _reactiveWidgets = {'Obx', 'GetX', 'GetBuilder'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      if (node.propertyName.name != 'value') return;

      final targetType = node.realTarget?.staticType;
      if (targetType == null || !_isGetxRxType(targetType)) return;

      if (_isInsideBuildMethod(node) && !_isInsideReactiveScope(node)) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }

  static bool _isInsideBuildMethod(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration) {
        return current.name.lexeme == 'build';
      }
      current = current.parent;
    }
    return false;
  }

  /// Returns true when [node] is directly inside a function expression that
  /// is the builder argument of an `Obx`, `GetX`, or `GetBuilder` constructor.
  static bool _isInsideReactiveScope(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression) {
        final parent = current.parent;

        // Check: argument to a constructor  Obx(() => ...)
        final argList = parent is ArgumentList
            ? parent
            : (parent is NamedExpression ? parent.parent : null);

        if (argList is ArgumentList) {
          final call = argList.parent;
          if (call is InstanceCreationExpression) {
            final name = call.constructorName.type.name2.lexeme;
            if (_reactiveWidgets.contains(name)) return true;
          }
        }
      }
      // Stop searching once we leave the build method scope.
      if (current is MethodDeclaration && current.name.lexeme == 'build') {
        return false;
      }
      current = current.parent;
    }
    return false;
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
