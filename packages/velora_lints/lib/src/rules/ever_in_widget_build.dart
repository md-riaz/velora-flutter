import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags calls to GetX listener registration functions (`ever`, `once`,
/// `debounce`, `interval`) made directly inside a Widget's `build()` method.
///
/// Each call to `build()` registers a new listener without removing the
/// previous one, causing memory leaks and duplicate callbacks that compound
/// on every rebuild.
///
/// ## Wrong
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   ever(controller.error, (v) => showSnackbar(v)); // new listener every build
///   return ...;
/// }
/// ```
///
/// ## Correct
/// ```dart
/// @override
/// void onInit() {
///   super.onInit();
///   ever(error, (v) { if ((v as String).isNotEmpty) Velora.toast.error(v); });
/// }
/// ```
class EverInWidgetBuild extends DartLintRule {
  const EverInWidgetBuild() : super(code: _code);

  static const _code = LintCode(
    name: 'ever_in_widget_build',
    problemMessage:
        "GetX listener '{0}' registered inside build() — a new listener is "
        'added on every rebuild, causing memory leaks and duplicate callbacks.',
    correctionMessage:
        'Move ever/once/debounce/interval calls to onInit() '
        'and cancel subscriptions in onClose().',
    errorSeverity: ErrorSeverity.ERROR,
  );

  static const _listenerFunctions = {'ever', 'once', 'debounce', 'interval'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final name = node.methodName.name;
      if (!_listenerFunctions.contains(name)) return;
      if (_isInsideBuildMethod(node)) {
        reporter.reportErrorForNode(_code, node, [name]);
      }
    });

    context.registry.addFunctionExpressionInvocation((node) {
      // Handles bare `ever(...)` calls (top-level function, not method)
      final function = node.function;
      if (function is! SimpleIdentifier) return;
      final name = function.name;
      if (!_listenerFunctions.contains(name)) return;
      if (_isInsideBuildMethod(node)) {
        reporter.reportErrorForNode(_code, node, [name]);
      }
    });
  }

  static bool _isInsideBuildMethod(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodDeclaration) {
        return current.name.lexeme == 'build';
      }
      // Stop if we enter a nested function or closure — that's a different scope.
      if (current is FunctionExpression ||
          current is FunctionDeclaration) {
        return false;
      }
      current = current.parent;
    }
    return false;
  }
}
