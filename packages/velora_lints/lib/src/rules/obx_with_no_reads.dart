import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags any `Obx(...)` builder — arrow *or* block body — whose function
/// body contains zero detectable reactive reads on GetX `Rx` types AND no
/// access to any `GetxController` / `GetxService` subclass.
///
/// ## Why not every Obx with a controller call?
///
/// GetX controllers commonly expose computed getters that return plain Dart
/// types (`bool`, `int`, `String`) while internally accessing reactive fields:
///
/// ```dart
/// bool get isAuthenticated => Velora.auth.isAuthenticated.value;
/// ```
///
/// Static analysis cannot see through the getter boundary, so the rule
/// conservatively skips Obx blocks that access any controller property.
/// The `obx_missing_reactive_read` rule covers the arrow-body Rx-arg case.
///
/// ## Wrong — completely static builder
/// ```dart
/// Obx(() => const Text('Static'))
/// Obx(() {
///   final label = 'Hello';   // plain string literal, not reactive
///   return Text(label);
/// })
/// ```
///
/// ## Correct
/// ```dart
/// Obx(() => Text(controller.title.value))
/// Obx(() {
///   if (controller.items.isEmpty) return const SizedBox.shrink();
///   return ItemList(items: controller.items);
/// })
/// ```
class ObxWithNoReads extends DartLintRule {
  const ObxWithNoReads() : super(code: _code);

  static const _code = LintCode(
    name: 'obx_with_no_reads',
    problemMessage:
        'This Obx builder contains no reactive reads on any GetX Rx type or '
        'GetxController — no subscription is registered and the widget '
        'will never rebuild.',
    correctionMessage:
        'Read at least one reactive property inside the builder, '
        'or remove the Obx wrapper entirely.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName != 'Obx') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final firstArg = args.first is NamedExpression
          ? (args.first as NamedExpression).expression
          : args.first;
      if (firstArg is! FunctionExpression) return;

      final detector = _ReactiveReadDetector();
      firstArg.body.accept(detector);

      if (!detector.hasReactiveRead) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }
}

// ---------------------------------------------------------------------------
// AST visitor — scans a function body for reactive property reads
// ---------------------------------------------------------------------------

class _ReactiveReadDetector extends RecursiveAstVisitor<void> {
  bool hasReactiveRead = false;

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (!hasReactiveRead) {
      final targetType = node.realTarget.staticType;
      if (targetType != null &&
          (_isGetxRxType(targetType) || _isGetxController(targetType))) {
        final name = node.propertyName.name;
        if (name != 'hashCode' && name != 'runtimeType') {
          hasReactiveRead = true;
        }
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!hasReactiveRead) {
      final prefixType = node.prefix.staticType;
      if (prefixType != null &&
          (_isGetxRxType(prefixType) || _isGetxController(prefixType))) {
        final name = node.identifier.name;
        if (name != 'hashCode' && name != 'runtimeType') {
          hasReactiveRead = true;
        }
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!hasReactiveRead) {
      final targetType = node.realTarget?.staticType;
      if (targetType != null &&
          (_isGetxRxType(targetType) || _isGetxController(targetType))) {
        hasReactiveRead = true;
      }
    }
    super.visitMethodInvocation(node);
  }

  // Also detect direct indexing on RxList — list[i] registers a subscription
  @override
  void visitIndexExpression(IndexExpression node) {
    if (!hasReactiveRead) {
      final targetType = node.realTarget.staticType;
      if (targetType != null &&
          (_isGetxRxType(targetType) || _isGetxController(targetType))) {
        hasReactiveRead = true;
      }
    }
    super.visitIndexExpression(node);
  }

  /// Returns true for direct Rx types (RxInt, RxBool, RxList, Rx<T>, …) and
  /// their private implementation classes (_RxImpl, _RxInt, etc.) by walking
  /// the full supertype chain rather than only checking the immediate type name.
  static bool _isGetxRxType(DartType type) {
    if (type is! InterfaceType) return false;
    for (final t in [type, ...type.allSupertypes]) {
      final element = t.element;
      final name = element.name;
      if (name == null) continue;
      final uri = element.library?.source?.uri.toString() ?? '';
      if (uri.contains('package:get/') &&
          (name.startsWith('Rx') || name == 'GetListenable')) {
        return true;
      }
    }
    return false;
  }

  /// Returns true for any GetxController / GetxService subclass.
  ///
  /// Accessing a property or method on a controller inside an Obx block may
  /// trigger reactive subscriptions through computed getters even when the
  /// getter's return type is a plain Dart type. We conservatively treat any
  /// controller access as a potential reactive read to avoid false positives.
  static bool _isGetxController(DartType type) {
    if (type is! InterfaceType) return false;
    for (final t in [type, ...type.allSupertypes]) {
      final element = t.element;
      final name = element.name;
      if (name == null) continue;
      final uri = element.library?.source?.uri.toString() ?? '';
      if (uri.contains('package:get/') &&
          (name == 'GetxController' ||
              name == 'GetxService' ||
              name == 'SuperController' ||
              name == 'GetLifeCycleMixin')) {
        return true;
      }
    }
    return false;
  }
}
