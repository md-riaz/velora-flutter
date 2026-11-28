import 'dart:io';

import 'package:desktop_readiness/src/contracts/realtime_port.dart';
import 'package:desktop_readiness/src/controllers/readiness_controller.dart';
import 'package:desktop_readiness/src/data/readiness_database.dart';
import 'package:desktop_readiness/src/diagnostics/diagnostics_log.dart';
import 'package:desktop_readiness/src/models/work_item.dart';
import 'package:desktop_readiness/src/services/readiness_coordinator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/velora.dart';
import 'package:velora_db/velora_db.dart';
import 'package:velora_desktop/velora_desktop.dart';
import 'package:velora_local_notifications/velora_local_notifications.dart';
import 'package:velora_offline/velora_offline.dart';

class _TestHarness {
  final FakeWindowPort window;
  final FakeTrayPort tray;
  final FakePowerPort power;
  final VeloraDesktopCoordinator desktop;
  final FakeNativeNotifications notifications;
  final ToggleConnectivitySource connectivity;
  final SimulatedRealtimeAdapter realtime;
  final SimulatedRemoteGateway gateway;
  final ReadinessDiagnosticsLog diagnostics;
  final VeloraDatabase database;
  final ReadinessWorkStore store;
  final ReadinessCoordinator coordinator;
  final ReadinessController controller;

  _TestHarness._({
    required this.window,
    required this.tray,
    required this.power,
    required this.desktop,
    required this.notifications,
    required this.connectivity,
    required this.realtime,
    required this.gateway,
    required this.diagnostics,
    required this.database,
    required this.store,
    required this.coordinator,
    required this.controller,
  });

  static Future<_TestHarness> create({
    VeloraDatabase? existingDatabase,
    bool online = true,
  }) async {
    Get.testMode = true;
    final window = FakeWindowPort();
    final tray = FakeTrayPort();
    final power = FakePowerPort();
    final desktop = VeloraDesktopCoordinator(
      config: const VeloraDesktopConfig(
        appId: 'test.readiness',
        appName: 'Test Readiness',
        tray: VeloraTrayConfig(iconAsset: 'assets/tray.ico'),
        closeToTray: true,
        singleInstance: false,
      ),
      window: window,
      tray: tray,
      autoStart: FakeAutoStartPort(),
      singleInstance: FakeSingleInstancePort(),
      links: FakeLinkPort(),
      power: power,
      storage: FakeDesktopStoragePort(),
    );
    await desktop.initialize();

    final notifications = FakeNativeNotifications();
    await notifications.initialize();

    final connectivity = ToggleConnectivitySource(online: online);
    final realtime = SimulatedRealtimeAdapter(networkAvailable: online);
    final gateway = SimulatedRemoteGateway(networkAvailable: online);
    final diagnostics = ReadinessDiagnosticsLog();

    final database =
        existingDatabase ??
        await VeloraDatabase.inMemory(readinessDbSchema).open();

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

    final controller = ReadinessController(
      coordinator: coordinator,
      store: store,
      diagnosticsLog: diagnostics,
    );
    controller.onInit();
    await Future<void>.delayed(Duration.zero);

    return _TestHarness._(
      window: window,
      tray: tray,
      power: power,
      desktop: desktop,
      notifications: notifications,
      connectivity: connectivity,
      realtime: realtime,
      gateway: gateway,
      diagnostics: diagnostics,
      database: database,
      store: store,
      coordinator: coordinator,
      controller: controller,
    );
  }

  Future<void> dispose({bool closeDb = true}) async {
    controller.onClose();
    await coordinator.dispose();
    await realtime.dispose();
    connectivity.dispose();
    await notifications.dispose();
    await desktop.dispose();
    await diagnostics.dispose();
    if (closeDb) {
      await database.close();
    }
  }
}

void main() {
  test(
    'work items are ordered by priority and then ID in both reads',
    () async {
      final h = await _TestHarness.create();
      addTearDown(h.dispose);
      final item = (await h.store.findItem('WI-101'))!;
      await h.store.putItem(item.copyWith(id: 'WI-100'));
      final expected = ['WI-100', 'WI-101', 'WI-102', 'WI-103'];
      expect((await h.store.loadItems()).map((item) => item.id), expected);
      expect(
        (await h.store.watchItems().first).map((item) => item.id),
        expected,
      );
    },
  );

  group('Scenario 1: Background & restore', () {
    test('hide to tray keeps realtime and queue alive and preserves selection, tab, and unsaved wizard state without duplicate listeners', () async {
      final h = await _TestHarness.create();
      addTearDown(h.dispose);

      final target = h.controller.items.firstWhere((i) => i.id == 'WI-102');
      h.controller.selectTab(0);
      h.controller.startWizard(target);
      h.controller.updateWizardStep1(title: 'Unsaved draft title', priority: 4);

      await h.coordinator.hideToTray();
      await Future<void>.delayed(Duration.zero);

      expect(h.window.visible, isFalse);
      expect(h.controller.isHiddenToTray.value, isTrue);
      expect(h.realtime.currentState, ReadinessRealtimeState.connected);

      // Remote event arrives while hidden in tray.
      h.realtime.emitRemoteEvent(
        ReadinessRealtimeEvent(
          id: 'evt-bg-1',
          cursor: 'cur-bg-1',
          item: WorkItem(
            id: 'WI-103',
            title: 'Updated while in tray',
            priority: 1,
            version: 2,
            syncStatus: SyncStatus.synced,
            updatedAt: DateTime.now().toUtc(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final updated103 = h.controller.items.firstWhere((i) => i.id == 'WI-103');
      expect(updated103.title, 'Updated while in tray');

      // Restore from tray and verify initialize() is idempotent (no duplicate listeners).
      await h.coordinator.initialize();
      await h.coordinator.restoreFromTray();
      await Future<void>.delayed(Duration.zero);

      expect(h.window.visible, isTrue);
      expect(h.controller.isHiddenToTray.value, isFalse);
      expect(h.controller.selectedTab.value, 0);
      expect(h.controller.selectedItem.value?.id, 'WI-102');
      expect(h.controller.wizardStep.value, 1);
      expect(h.controller.wizardTitle.value, 'Unsaved draft title');
      expect(h.controller.wizardPriority.value, 4);
    });
  });

  group('Scenario 2: Network loss, restart durability, conflict & auth', () {
    test('offline mutation survives database close & reopen (process restart), handles unreachable endpoint, and replays idempotently once', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'desktop_readiness_restart_',
      );
      final dbFile = File('${tempDir.path}${Platform.pathSeparator}test.db');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final db1 = await VeloraDatabase(
        databaseName: readinessDbSchema.databaseName,
        version: readinessDbSchema.version,
        migrations: readinessDbSchema.migrations,
        executor: NativeDatabase(dbFile),
      ).open();

      final h1 = await _TestHarness.create(
        existingDatabase: db1,
        online: false,
      );
      final item = h1.controller.items.firstWhere((i) => i.id == 'WI-101');
      h1.controller.startWizard(item);
      h1.controller.updateWizardStep1(title: 'Edited offline', priority: 4);
      h1.controller.nextWizardStep();
      await h1.controller.submitWizard();

      expect(await h1.store.pendingOutboxCount(), 1);
      final savedBeforeRestart = await h1.store.findItem('WI-101');
      expect(savedBeforeRestart?.syncStatus, SyncStatus.pending);
      expect(savedBeforeRestart?.title, 'Edited offline');
      final keyBeforeRestart = savedBeforeRestart?.idempotencyKey;
      expect(keyBeforeRestart, isNotNull);

      await h1.dispose(closeDb: true);

      // Simulate process restart with a fresh database handle to the same file.
      final db2 = await VeloraDatabase(
        databaseName: readinessDbSchema.databaseName,
        version: readinessDbSchema.version,
        migrations: readinessDbSchema.migrations,
        executor: NativeDatabase(dbFile),
      ).open();

      final h2 = await _TestHarness.create(
        existingDatabase: db2,
        online: false,
      );
      addTearDown(h2.dispose);

      expect(await h2.store.pendingOutboxCount(), 1);
      final loadedAfterRestart = await h2.store.findItem('WI-101');
      expect(loadedAfterRestart?.title, 'Edited offline');
      expect(loadedAfterRestart?.idempotencyKey, keyBeforeRestart);

      // Restore network while endpoint is unreachable.
      await h2.coordinator.setEndpointReachable(false);
      await h2.coordinator.setNetworkOnline(true);
      expect(h2.controller.endpointReachable.value, isFalse);
      expect(await h2.store.pendingOutboxCount(), 1);

      // Restore endpoint reachability -> replays once idempotently.
      await h2.coordinator.setEndpointReachable(true);
      expect(await h2.store.pendingOutboxCount(), 0);
      expect(h2.gateway.uniqueAppliedCount, 1);

      final synced = await h2.store.findItem('WI-101');
      expect(synced?.syncStatus, SyncStatus.synced);
      expect(synced?.version, 2);

      // Duplicate replay of same idempotency key does not apply twice.
      await h2.gateway.pushMutation(
        item: synced!,
        idempotencyKey: keyBeforeRestart!,
      );
      expect(h2.gateway.uniqueAppliedCount, 1);
    });

    test('conflict requires explicit resolution and permanent auth failure stops retry loop', () async {
      final h = await _TestHarness.create();
      addTearDown(h.dispose);

      // Conflict case.
      h.gateway.conflictOnNextSync = true;
      h.gateway.conflictServerTitle = 'Remote server version';
      await h.store.enqueueMutation(
        itemId: 'WI-102',
        title: 'Local conflicting edit',
        priority: 3,
      );
      final conflictReport = await h.store.flushOutbox();
      expect(conflictReport.conflicts, 1);

      final conflicted = await h.store.findItem('WI-102');
      expect(conflicted?.syncStatus, SyncStatus.conflict);
      expect(conflicted?.serverTitle, 'Remote server version');

      // Explicit resolution: accept server.
      await h.controller.resolveConflictAcceptServer('WI-102');
      final resolved = await h.store.findItem('WI-102');
      expect(resolved?.syncStatus, SyncStatus.synced);
      expect(resolved?.title, 'Remote server version');

      // Permanent auth failure stops retry loop without spinning.
      h.gateway.unauthorizedMode = true;
      await h.store.enqueueMutation(
        itemId: 'WI-101',
        title: 'Should pause on 401',
        priority: 2,
      );
      final attemptsBefore = h.gateway.pushAttempts;
      final authReport = await h.coordinator.reconcileAndFlush();
      expect(authReport.pausedUnauthorized, isTrue);
      expect(h.realtime.currentState, ReadinessRealtimeState.unauthorized);
      expect(h.gateway.pushAttempts - attemptsBefore, 1);

      final failed = await h.store.findItem('WI-101');
      expect(failed?.syncStatus, SyncStatus.permanentFailure);
    });
  });

  group('Scenario 3: Sleep & resume', () {
    test('coalesces duplicate suspend/resume signals, invalidates old connection, reconciles once with event deduplication, and preserves unsaved wizard state', () async {
      final h = await _TestHarness.create();
      addTearDown(h.dispose);

      final target = h.controller.items.firstWhere((i) => i.id == 'WI-101');
      h.controller.startWizard(target);
      h.controller.updateWizardStep1(title: 'Draft across sleep', priority: 3);

      final epochBeforeSleep = h.realtime.connectionEpoch;

      // Duplicate suspend signals.
      h.power.add(VeloraPowerSignal.suspending);
      h.power.add(VeloraPowerSignal.suspending);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(h.realtime.currentState, ReadinessRealtimeState.disconnected);
      expect(h.realtime.connectionEpoch, greaterThan(epochBeforeSleep));

      // Old connection is invalidated; emitting while disconnected does nothing.
      h.realtime.emitRemoteEvent(
        ReadinessRealtimeEvent(
          id: 'evt-stale',
          cursor: 'cur-stale',
          item: target.copyWith(title: 'Stale packet'),
        ),
      );

      // Stage missed events including a duplicate event ID.
      final missedItem = WorkItem(
        id: 'WI-103',
        title: 'Reconciled after wake',
        priority: 2,
        version: 5,
        syncStatus: SyncStatus.synced,
        updatedAt: DateTime.now().toUtc(),
      );
      h.gateway.stageRemoteEvent(
        ReadinessRealtimeEvent(
          id: 'evt-wake-1',
          cursor: 'cur-wake-1',
          item: missedItem,
        ),
      );
      h.gateway.stageRemoteEvent(
        ReadinessRealtimeEvent(
          id: 'evt-wake-1',
          cursor: 'cur-wake-1',
          item: missedItem.copyWith(title: 'Duplicate should be ignored'),
        ),
      );

      // Duplicate resume signals.
      h.power.add(VeloraPowerSignal.resumed);
      h.power.add(VeloraPowerSignal.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(h.realtime.currentState, ReadinessRealtimeState.connected);
      expect(await h.store.loadCursor(), 'cur-wake-1');
      final item103 = await h.store.findItem('WI-103');
      expect(item103?.title, 'Reconciled after wake');

      // Unsaved wizard state survived sleep/resume.
      expect(h.controller.wizardStep.value, 1);
      expect(h.controller.wizardTitle.value, 'Draft across sleep');
    });
  });

  group('Scenario 4: Notification activation & diagnostics redaction', () {
    test('handles foreground, tray-hidden, duplicate activation IDs, malformed payloads, and redacts secrets/content', () async {
      final h = await _TestHarness.create();
      addTearDown(h.dispose);

      // Foreground activation.
      h.notifications.simulateActivation(
        const VeloraNotificationActivation(
          id: 'act-1',
          payload: {'activationId': 'act-1', 'itemId': 'WI-102'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.controller.lastActivatedItemId.value, 'WI-102');
      expect(h.controller.selectedItem.value?.id, 'WI-102');

      // Duplicate activation ID is deduplicated.
      h.controller.selectItem(
        h.controller.items.firstWhere((i) => i.id == 'WI-101'),
      );
      h.notifications.simulateActivation(
        const VeloraNotificationActivation(
          id: 'act-1',
          payload: {'activationId': 'act-1', 'itemId': 'WI-102'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.controller.selectedItem.value?.id, 'WI-101');

      // Tray-hidden activation restores window and focuses item.
      await h.coordinator.hideToTray();
      expect(h.window.visible, isFalse);
      h.notifications.simulateActivation(
        const VeloraNotificationActivation(
          id: 'act-2',
          payload: {'activationId': 'act-2', 'itemId': 'WI-103'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.window.visible, isTrue);
      expect(h.controller.isHiddenToTray.value, isFalse);
      expect(h.controller.selectedItem.value?.id, 'WI-103');

      // Malformed payload is safely ignored.
      h.notifications.simulateActivation(
        const VeloraNotificationActivation(
          id: 'act-bad',
          payload: {'activationId': 'act-bad', 'itemId': 999},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.controller.selectedItem.value?.id, 'WI-103');

      // Verify diagnostics redaction for sensitive keys and bearer/token strings.
      final entry = h.diagnostics.record(
        'security',
        'Auth failed with Bearer super-secret-token-123 and password=myPass',
        metadata: {
          'token': 'abc-secret',
          'authorization': 'Bearer xyz',
          'title': 'Private user work item title',
          'payload': {'secret': 'nested-secret'},
          'safeKey': 'WI-103',
        },
      );

      expect(entry.message, isNot(contains('super-secret-token-123')));
      expect(entry.message, isNot(contains('myPass')));
      expect(entry.message, contains(ReadinessDiagnosticsLog.redactedValue));
      expect(entry.metadata['token'], ReadinessDiagnosticsLog.redactedValue);
      expect(
        entry.metadata['authorization'],
        ReadinessDiagnosticsLog.redactedValue,
      );
      expect(entry.metadata['title'], ReadinessDiagnosticsLog.redactedValue);
      expect(entry.metadata['payload'], ReadinessDiagnosticsLog.redactedValue);
      expect(entry.metadata['safeKey'], 'WI-103');
    });
  });
}
