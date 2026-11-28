import 'dart:io';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_desktop/velora_desktop.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';
import 'package:velora_offline/velora_offline.dart';

import 'src/contracts/realtime_port.dart';
import 'src/controllers/readiness_controller.dart';
import 'src/data/readiness_database.dart';
import 'src/diagnostics/diagnostics_log.dart';
import 'src/models/work_item.dart';
import 'src/services/readiness_coordinator.dart';
import 'src/ui/readiness_app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  const desktopConfig = VeloraDesktopConfig(
    appId: 'dev.velora.desktop_readiness',
    appName: 'Velora Desktop Readiness',
    closeToTray: false,
    singleInstance: false,
    minimumSize: Size(640, 480),
    initialSize: Size(1100, 760),
  );

  await Velora.boot(
    config: const VeloraConfig(
      appName: 'Velora Desktop Readiness',
      apiBaseUrl: 'http://localhost',
      notifications: VeloraNotificationConfig(enabled: false),
    ),
    plugins: [
      VeloraDbPlugin.fromSchema(readinessDbSchema),
      VeloraDesktopPlugin(config: desktopConfig),
    ],
  );

  final diagnostics = ReadinessDiagnosticsLog();
  final connectivity = ToggleConnectivitySource(online: true);
  final realtime = SimulatedRealtimeAdapter();
  final gateway = SimulatedRemoteGateway();
  final database = Get.find<VeloraDatabase>();
  final desktop = Get.find<VeloraDesktopService>();

  VeloraNativeNotifications notifications;
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    try {
      notifications = FlutterLocalNotificationsNativeAdapter();
      await notifications.initialize();
    } on Object {
      notifications = FakeNativeNotifications();
      await notifications.initialize();
    }
  } else {
    notifications = FakeNativeNotifications();
    await notifications.initialize();
  }

  final store = ReadinessWorkStore(
    database: database,
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

  final controller = Get.put(
    ReadinessController(
      coordinator: coordinator,
      store: store,
      diagnosticsLog: diagnostics,
    ),
  );

  var remoteCounter = 1;
  runApp(
    ReadinessApp(
      controller: controller,
      onHideToTray: coordinator.hideToTray,
      onRestoreFromTray: coordinator.restoreFromTray,
      onTriggerConflict: () {
        gateway.conflictOnNextSync = true;
        diagnostics.record('simulation', 'Armed conflict on next sync');
      },
      onEmitRemoteEvent: () {
        final seq = remoteCounter++;
        realtime.emitRemoteEvent(
          ReadinessRealtimeEvent(
            id: 'evt-sim-$seq',
            cursor: 'cur-sim-$seq',
            item: WorkItem(
              id: 'WI-103',
              title: 'Remote update #$seq',
              priority: 2,
              version: seq + 1,
              syncStatus: SyncStatus.synced,
              updatedAt: DateTime.now().toUtc(),
            ),
          ),
        );
      },
      onSimulateNotification: (itemId) async {
        desktop.reportNotificationActivation(
          id: 'notif-$itemId-${DateTime.now().millisecondsSinceEpoch}',
          data: {'itemId': itemId},
        );
      },
      onSimulateMalformedNotification: () {
        desktop.reportNotificationActivation(
          id: 'notif-malformed-${DateTime.now().millisecondsSinceEpoch}',
          data: const {'unexpected': 123},
        );
      },
    ),
  );
}
