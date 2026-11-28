import 'package:desktop_readiness/src/contracts/realtime_port.dart';
import 'package:desktop_readiness/src/controllers/readiness_controller.dart';
import 'package:desktop_readiness/src/data/readiness_database.dart';
import 'package:desktop_readiness/src/diagnostics/diagnostics_log.dart';
import 'package:desktop_readiness/src/services/readiness_coordinator.dart';
import 'package:desktop_readiness/src/ui/readiness_app.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_desktop/velora_desktop.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';
import 'package:velora_offline/velora_offline.dart';

Future<({ReadinessController controller, Future<void> Function() dispose})>
_createAppController() async {
  Get.testMode = true;
  final desktop = VeloraDesktopCoordinator(
    config: const VeloraDesktopConfig(
      appId: 'test.widget',
      appName: 'Test Widget',
      singleInstance: false,
    ),
    window: FakeWindowPort(),
    tray: FakeTrayPort(),
    autoStart: FakeAutoStartPort(),
    singleInstance: FakeSingleInstancePort(),
    links: FakeLinkPort(),
    power: FakePowerPort(),
    storage: FakeDesktopStoragePort(),
  );
  await desktop.initialize();

  final notifications = FakeNativeNotifications();
  await notifications.initialize();
  final connectivity = ToggleConnectivitySource(online: true);
  final realtime = SimulatedRealtimeAdapter();
  final gateway = SimulatedRemoteGateway();
  final diagnostics = ReadinessDiagnosticsLog();
  final db = await VeloraDatabase.inMemory(readinessDbSchema).open();

  final store = ReadinessWorkStore(
    database: db,
    connectivity: connectivity,
    gateway: gateway,
    diagnostics: diagnostics,
  );
  final coordinator = ReadinessCoordinator(
    desktop: desktop,
    notifications: notifications,
    realtime: realtime,
    gateway: gateway,
    store: store,
    connectivity: connectivity,
    diagnostics: diagnostics,
  );
  await coordinator.initialize();

  final controller = ReadinessController(
    coordinator: coordinator,
    store: store,
    diagnosticsLog: diagnostics,
  );
  controller.onInit();
  await Future<void>.delayed(const Duration(milliseconds: 20));

  return (
    controller: controller,
    dispose: () async {
      controller.onClose();
      await coordinator.dispose();
      await realtime.dispose();
      connectivity.dispose();
      await notifications.dispose();
      await desktop.dispose();
      await diagnostics.dispose();
      await db.close();
    },
  );
}

void main() {
  testWidgets(
    'controlled wizard state survives AdaptiveShell + MasterDetail resize (1280x800 <-> 500x800)',
    (tester) async {
      final setup = (await tester.runAsync(_createAppController))!;
      addTearDown(() => tester.runAsync(setup.dispose));

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(ReadinessApp(controller: setup.controller));
      await tester.pumpAndSettle();

      // Open wizard from detail pane button.
      await tester.tap(find.text('Edit in 2-Step Wizard'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('wizard-title-field')),
        'Survives resize',
      );
      await tester.pumpAndSettle();

      // Resize down to 500x800 (compact).
      await tester.binding.setSurfaceSize(const Size(500, 800));
      await tester.pumpAndSettle();
      expect(find.text('Edit Work Item — Step 1 of 2'), findsOneWidget);
      expect(setup.controller.wizardTitle.value, 'Survives resize');

      // Resize back up to 1280x800 (expanded).
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpAndSettle();
      expect(find.text('Edit Work Item — Step 1 of 2'), findsOneWidget);
      expect(setup.controller.wizardTitle.value, 'Survives resize');
    },
  );

  testWidgets(
    'supports keyboard Tab navigation, 640x480 minimum layout, and 2.0x text scaling without overflow',
    (tester) async {
      final setup = (await tester.runAsync(_createAppController))!;
      addTearDown(() => tester.runAsync(setup.dispose));

      // Test 640x480 minimum window size + 2.0x text scaling.
      await tester.binding.setSurfaceSize(const Size(640, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: ReadinessApp(controller: setup.controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Keyboard Tab navigation moves focus cleanly without exceptions.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
