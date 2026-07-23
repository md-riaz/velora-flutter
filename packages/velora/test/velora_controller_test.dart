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

      final subscription = controller.listenStream(
        source.stream,
        received.add,
      );

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

      final subscription = controller.listenStream(
        source.stream,
        received.add,
      );

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
}
