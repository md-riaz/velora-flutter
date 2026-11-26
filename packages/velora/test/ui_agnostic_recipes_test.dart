import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart';

class _CounterController extends VeloraController {
  final count = 0.obs;

  Future<void> increment({bool shouldFail = false}) async {
    await run<void>(() async {
      if (shouldFail) {
        throw StateError('increment failed');
      }
      count.value++;
    }, successMessage: 'Incremented');
  }
}

class _RecordingFeedbackPresenter implements FeedbackPresenter {
  _RecordingFeedbackPresenter(this.label);

  final String label;
  final List<String> events = <String>[];

  @override
  void success(String message) => events.add('$label:success:$message');

  @override
  void error(String message) => events.add('$label:error:$message');

  @override
  Future<bool> confirm(ConfirmationRequest request) async {
    events.add('$label:confirm:${request.title}');
    return true;
  }
}

void main() {
  tearDown(Get.reset);

  Future<void> bootWithPresenter(
    WidgetTester tester,
    FeedbackPresenter presenter,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    Get.reset();
    await tester.runAsync(
      () => Velora.boot(
        config: const VeloraConfig(
          appName: 'RecipeApp',
          apiBaseUrl: 'https://example.test',
          notifications: VeloraNotificationConfig(enabled: false),
        ),
        feedback: presenter,
      ),
    );
  }

  testWidgets('same VeloraController renders with MaterialApp', (tester) async {
    final presenter = _RecordingFeedbackPresenter('material');
    await bootWithPresenter(tester, presenter);
    final controller = _CounterController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Obx(
            () => FilledButton(
              onPressed: controller.increment,
              child: Text('Count: ${controller.count.value}'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Count: 0'));
    await tester.pump();
    expect(find.text('Count: 1'), findsOneWidget);
    expect(presenter.events, ['material:success:Incremented']);
  });

  testWidgets('same VeloraController renders with CupertinoApp', (
    tester,
  ) async {
    final presenter = _RecordingFeedbackPresenter('cupertino');
    await bootWithPresenter(tester, presenter);
    final controller = _CounterController();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Center(
            child: Obx(
              () => CupertinoButton(
                onPressed: controller.increment,
                child: Text('Count: ${controller.count.value}'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Count: 0'));
    await tester.pump();
    expect(find.text('Count: 1'), findsOneWidget);
    expect(presenter.events, ['cupertino:success:Incremented']);
  });

  testWidgets('same VeloraController renders with custom non-Material UI kit', (
    tester,
  ) async {
    final presenter = _RecordingFeedbackPresenter('shad-like');
    await bootWithPresenter(tester, presenter);
    final controller = _CounterController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Obx(
          () => GestureDetector(
            onTap: controller.increment,
            child: Text('Count: ${controller.count.value}'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Count: 0'));
    await tester.pump();
    expect(find.text('Count: 1'), findsOneWidget);
    expect(presenter.events, ['shad-like:success:Incremented']);
  });
}
