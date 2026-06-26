import 'dart:convert';
import 'dart:io';

import 'package:analyzer/error/error.dart';
import 'package:test/test.dart';
import 'package:velora_lints/src/rules/obx_with_no_reads.dart';

void main() {
  test('detects only synchronous Obx reactive reads', () async {
    const source = '''
import 'package:get/get.dart';

class Obx {
  Obx(Object Function() builder);
}

class Text {
  const Text(String text);
}

class SizedBox {
  const SizedBox.shrink();
}

class GestureDetector {
  const GestureDetector({void Function()? onTap, Object? child});
}

class TestController extends GetxController {
  final count = 0.obs;
  final items = <String>[].obs;
  RxInt get rxCount => count;
  bool get isPositive => count.value > 0;
  bool hasItems() => items.isNotEmpty;
}

final controller = TestController();
final GetListenable<int> supertypeCount = 0.obs;

void examples() {
  Obx(() => Text('r:\${controller.isPositive}'));
  Obx(() => Text('r:\${controller.hasItems()}'));

  // expect_lint: obx_with_no_reads
  Obx(() => const Text('Static'));

  // expect_lint: obx_with_no_reads
  Obx(() {
    final value = controller.rxCount;
    return Text('r:\$value');
  });

  Obx(() {
    if (controller.items.isEmpty) return const SizedBox.shrink();
    return Text('r:\${controller.items}');
  });

  // expect_lint: obx_with_no_reads
  Obx(() => GestureDetector(
        onTap: () => controller.count.value++,
        child: const Text('tap'),
      ));

  Obx(() => Text('r:\${supertypeCount.value}'));
}
''';

    final errors = await _runRule(source);
    expect(_errorLines(source, errors), [35, 38, 49]);
    expect(errors.map((error) => error.errorCode.name), [
      'obx_with_no_reads',
      'obx_with_no_reads',
      'obx_with_no_reads',
    ]);
  });
}

List<int> _errorLines(String source, List<AnalysisError> errors) {
  return errors.map((error) {
    return '\n'.allMatches(source.substring(0, error.offset)).length + 1;
  }).toList();
}

Future<List<AnalysisError>> _runRule(String source) async {
  final workspace = Directory.systemTemp.createTempSync('velora_lints_test_');
  addTearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  final app = Directory.fromUri(workspace.uri.resolve('app/'))..createSync();
  final appLib = Directory.fromUri(app.uri.resolve('lib/'))..createSync();
  final getPackage = Directory.fromUri(workspace.uri.resolve('get/'))
    ..createSync();
  final getLib = Directory.fromUri(getPackage.uri.resolve('lib/'))
    ..createSync();

  File.fromUri(app.uri.resolve('pubspec.yaml')).writeAsStringSync('''
name: app
environment:
  sdk: ^3.11.0
dependencies:
  get:
    path: ../get
''');

  File.fromUri(getPackage.uri.resolve('pubspec.yaml')).writeAsStringSync('''
name: get
environment:
  sdk: ^3.11.0
''');

  File.fromUri(getLib.uri.resolve('get.dart')).writeAsStringSync('''
library get;

import 'dart:collection';

class GetListenable<T> {
  GetListenable(this.value);
  T value;
}

class Rx<T> extends GetListenable<T> {
  Rx(super.value);
}

class RxInt extends Rx<int> {
  RxInt(super.value);
}

class RxList<E> extends ListBase<E> implements Rx<List<E>> {
  RxList(this.value);

  @override
  List<E> value;

  @override
  int get length => value.length;

  @override
  set length(int newLength) => value.length = newLength;

  @override
  E operator [](int index) => value[index];

  @override
  void operator []=(int index, E element) => value[index] = element;
}

class GetxController {}
class GetxService {}
class SuperController<T> extends GetxController {}
mixin GetLifeCycleMixin {}

extension IntObs on int {
  RxInt get obs => RxInt(this);
}

extension ListObs<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);
}
''');

  final packageConfigDir = Directory.fromUri(app.uri.resolve('.dart_tool/'))
    ..createSync();
  File.fromUri(
    packageConfigDir.uri.resolve('package_config.json'),
  ).writeAsStringSync(
    jsonEncode({
      'configVersion': 2,
      'packages': [
        {
          'name': 'app',
          'rootUri': app.uri.toString(),
          'packageUri': 'lib/',
          'languageVersion': '3.11',
        },
        {
          'name': 'get',
          'rootUri': getPackage.uri.toString(),
          'packageUri': 'lib/',
          'languageVersion': '3.11',
        },
      ],
    }),
  );

  final file = File.fromUri(appLib.uri.resolve('main.dart'))
    ..writeAsStringSync(source);
  return const ObxWithNoReads().testAnalyzeAndRun(file);
}
