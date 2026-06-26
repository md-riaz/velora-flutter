import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Flags any `Obx(...)` builder — arrow *or* block body — whose function
/// body contains zero detectable reactive reads on GetX `Rx` types.
///
/// ## Controller members
///
/// GetX controllers commonly expose computed getters that return plain Dart
/// types (`bool`, `int`, `String`) while internally accessing reactive fields:
///
/// ```dart
/// bool get isAuthenticated => Velora.auth.isAuthenticated.value;
/// ```
///
/// Static analysis cannot see through the getter boundary, so the rule treats
/// controller properties/methods returning non-Rx types as reactive reads. Bare
/// controller properties/getters returning Rx types are pass-throughs and must
/// still be followed by an Rx read such as `.value`, `.isEmpty`, or `[index]`.
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
        'controller computed value — no subscription is registered and the '
        'widget will never rebuild.',
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
  void visitFunctionExpression(FunctionExpression node) {
    // Obx subscriptions are registered only by reads that happen synchronously
    // while the builder itself runs. Reads inside callbacks/closures execute
    // later and must not suppress this lint.
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (!hasReactiveRead) {
      _checkRead(
        targetType: node.realTarget.staticType,
        memberType: node.staticType,
        name: node.propertyName.name,
      );
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!hasReactiveRead) {
      _checkRead(
        targetType: node.prefix.staticType,
        memberType: node.staticType,
        name: node.identifier.name,
      );
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!hasReactiveRead) {
      _checkRead(
        targetType: node.realTarget?.staticType,
        memberType: node.staticType,
        name: node.methodName.name,
      );
    }
    super.visitMethodInvocation(node);
  }

  // Also detect direct indexing on RxList — list[i] registers a subscription.
  @override
  void visitIndexExpression(IndexExpression node) {
    if (!hasReactiveRead) {
      _checkRead(
        targetType: node.realTarget.staticType,
        memberType: node.staticType,
      );
    }
    super.visitIndexExpression(node);
  }

  void _checkRead({
    required DartType? targetType,
    required DartType? memberType,
    String? name,
  }) {
    if (targetType == null) return;
    if (name == 'hashCode' || name == 'runtimeType') return;

    if (_isGetxRxType(targetType)) {
      hasReactiveRead = true;
      return;
    }

    if (_isGetxController(targetType) && _isKnownNonRxType(memberType)) {
      hasReactiveRead = true;
    }
  }

  static bool _isKnownNonRxType(DartType? type) {
    if (type == null || type is DynamicType) return false;
    return !_isGetxRxType(type);
  }

  /// Returns true for direct Rx types (RxInt, RxBool, RxList, Rx<T>, …) and
  /// their private implementation classes (_RxImpl, _RxInt, etc.) by walking
  /// the full supertype chain rather than only checking the immediate type name.
  static bool _isGetxRxType(DartType type) {
    if (type is! InterfaceType) return false;
    for (final t in [type, ...type.allSupertypes]) {
      final element = t.element;
      final name = element.name;
      final uri = element.library.source.uri.toString();
      if (uri.contains('package:get/') &&
          (name.startsWith('Rx') || name == 'GetListenable')) {
        return true;
      }
    }
    return false;
  }

  /// Returns true for any GetxController / GetxService subclass.
  static bool _isGetxController(DartType type) {
    if (type is! InterfaceType) return false;
    for (final t in [type, ...type.allSupertypes]) {
      final element = t.element;
      final name = element.name;
      final uri = element.library.source.uri.toString();
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
