import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';

/// Minimal concrete [VeloraController] used only to exercise [listenStream]
/// / [onClose] — it never calls [VeloraController.run], so it doesn't touch
/// any `Velora.*` facade.
class _TestController extends VeloraController {}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  test(
    'listenStream delivers events to onData and auto-cancels on onClose',
    () async {
      final controller = _TestController();
      final source = StreamController<int>.broadcast();
      final received = <int>[];

      final subscription = controller.listenStream(source.stream, received.add);

      // listenStream hands back a usable StreamSubscription.
      expect(subscription, isA<StreamSubscription<int>>());

      source.add(1);
      await pumpEventQueue();
      expect(received, [1]);

      source.add(2);
      await pumpEventQueue();
      expect(received, [1, 2]);

      // Disposing the controller cancels the subscription automatically —
      // no more events should be delivered after this point.
      controller.onClose();

      source.add(3);
      await pumpEventQueue();
      expect(received, [1, 2]);

      await source.close();
    },
  );

  test(
    'listenStream subscription can be cancelled early without error',
    () async {
      final controller = _TestController();
      final source = StreamController<int>.broadcast();
      final received = <int>[];

      final subscription = controller.listenStream(source.stream, received.add);

      // Early cancel — should be a no-op safe call, and onClose's later
      // cancel-again must not throw.
      await subscription.cancel();

      source.add(1);
      await pumpEventQueue();
      expect(received, isEmpty);

      // Double-cancel via onClose must not throw.
      expect(controller.onClose, returnsNormally);

      await source.close();
    },
  );

  group('run error formatting', () {
    test('standalone controller falls back to exception.toString() when Velora is not booted', () async {
      await Velora.reset();
      expect(Velora.isBooted, isFalse);

      final controller = _TestController();
      final result = await controller.run<int>(
        () async => throw StateError('boom'),
        reportError: false,
      );

      expect(result, isNull);
      expect(controller.error.value, 'Bad state: boom');
    });

    test(
      'uses VeloraConfig.errorFormatter when errorMessage is omitted',
      () async {
        await Velora.testBoot(
          config: VeloraConfig(
            appName: 'Test',
            apiBaseUrl: 'http://localhost',
            notifications: const VeloraNotificationConfig(enabled: false),
            errorFormatter: (error) => 'Formatted: $error',
          ),
        );
        addTearDown(Velora.reset);

        final controller = _TestController();
        await controller.run<void>(
          () async => throw FormatException('bad input'),
          reportError: false,
        );

        expect(controller.error.value, 'Formatted: FormatException: bad input');
      },
    );

    test(
      'explicit errorMessage overrides VeloraConfig.errorFormatter',
      () async {
        var formatterCalled = false;
        await Velora.testBoot(
          config: VeloraConfig(
            appName: 'Test',
            apiBaseUrl: 'http://localhost',
            notifications: const VeloraNotificationConfig(enabled: false),
            errorFormatter: (error) {
              formatterCalled = true;
              return 'Formatted: $error';
            },
          ),
        );
        addTearDown(Velora.reset);

        final controller = _TestController();
        await controller.run<void>(
          () async => throw Exception('raw'),
          errorMessage: 'Friendly message',
          reportError: false,
        );

        expect(formatterCalled, isFalse);
        expect(controller.error.value, 'Friendly message');
      },
    );
  });
}
