import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velora/velora.dart';

class _Presenter implements FeedbackPresenter {
  final successes = <String>[];
  final errors = <String>[];
  ConfirmationRequest? request;

  @override
  void success(String message) => successes.add(message);

  @override
  void error(String message) => errors.add(message);

  @override
  Future<bool> confirm(ConfirmationRequest request) async {
    this.request = request;
    return true;
  }
}

class _Controller extends VeloraController {}

void main() {
  const config = VeloraConfig(
    appName: 'Test',
    apiBaseUrl: 'https://example.test',
    notifications: VeloraNotificationConfig(enabled: false),
  );
  const request = ConfirmationRequest(
    title: 'Delete',
    message: 'Continue?',
    confirmLabel: 'Delete',
    cancelLabel: 'Cancel',
  );

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(Get.reset);

  test('missing presenter ignores messages and rejects confirmation', () async {
    Velora.feedback.success('saved');
    Velora.feedback.error('failed');
    expect(() => Velora.feedback.confirm(request), throwsStateError);
    final controller = _Controller();
    expect(await controller.run(() async => 1, successMessage: 'saved'), 1);
    expect(
      await controller.run<int>(() async => throw StateError('failed')),
      isNull,
    );
    expect(controller.error.value, contains('failed'));
    expect(controller.loading.value, isFalse);
  });

  test('boot registers presenter and run reports results', () async {
    final presenter = _Presenter();
    await Velora.boot(config: config, feedback: presenter);
    expect(Velora.feedback, same(presenter));
    expect(request.destructive, isFalse);
    expect(await Velora.feedback.confirm(request), isTrue);
    expect(presenter.request, same(request));
    final controller = _Controller();
    expect(await controller.run(() async => 1, successMessage: 'saved'), 1);
    await controller.run<void>(
      () async => throw StateError('oops'),
      errorMessage: 'failed',
    );
    await controller.run<void>(
      () async => throw StateError('quiet'),
      reportError: false,
    );
    expect(presenter.successes, ['saved']);
    expect(presenter.errors, ['failed']);
    await expectLater(
      controller.run<void>(
        () async => throw StateError('again'),
        rethrowError: true,
      ),
      throwsStateError,
    );
    expect(controller.loading.value, isFalse);
    Get.reset();
    await Velora.boot(config: config);
    expect(() => Velora.feedback.confirm(request), throwsStateError);
  });
}
