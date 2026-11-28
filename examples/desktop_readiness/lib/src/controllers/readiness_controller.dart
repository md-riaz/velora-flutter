import 'package:velora/velora.dart';

import '../contracts/realtime_port.dart';
import '../data/readiness_database.dart';
import '../diagnostics/diagnostics_log.dart';
import '../models/work_item.dart';
import '../services/readiness_coordinator.dart';

/// Screen-local reactive controller for the desktop readiness app.
///
/// All stream subscriptions are registered once in [onInit] via
/// [VeloraController.listenStream] so they are automatically cancelled in
/// [onClose] and never duplicated across rebuilds or tray hide/restore.
class ReadinessController extends VeloraController {
  final ReadinessCoordinator coordinator;
  final ReadinessWorkStore store;
  final ReadinessDiagnosticsLog diagnosticsLog;

  ReadinessController({
    required this.coordinator,
    required this.store,
    required this.diagnosticsLog,
  });

  final RxInt selectedTab = 0.obs;
  final Rxn<WorkItem> selectedItem = Rxn<WorkItem>();

  // Controlled 2-step edit wizard state (0 = closed, 1 = edit, 2 = review).
  final RxInt wizardStep = 0.obs;
  final RxnString wizardItemId = RxnString();
  final RxString wizardTitle = ''.obs;
  final RxInt wizardPriority = 2.obs;

  final RxList<WorkItem> items = <WorkItem>[].obs;
  final Rx<ReadinessRealtimeState> realtimeState =
      ReadinessRealtimeState.disconnected.obs;
  final RxBool isOnline = true.obs;
  final RxBool endpointReachable = true.obs;
  final RxBool isHiddenToTray = false.obs;
  final RxnString lastActivatedItemId = RxnString();
  final RxList<ReadinessDiagnosticEntry> diagnostics =
      <ReadinessDiagnosticEntry>[].obs;

  bool _streamsBound = false;

  @override
  void onInit() {
    super.onInit();
    if (_streamsBound) return;
    _streamsBound = true;

    realtimeState.value = coordinator.realtimeState;
    isOnline.value = coordinator.isOnline;
    endpointReachable.value = coordinator.endpointReachable;
    isHiddenToTray.value = coordinator.isHiddenToTray;
    diagnostics.assignAll(diagnosticsLog.entries);
    final pendingActivation = coordinator.consumePendingActivatedItemId();
    if (pendingActivation != null) {
      lastActivatedItemId.value = pendingActivation;
    }

    listenStream<List<WorkItem>>(store.watchItems(), _onItemsChanged);
    listenStream<ReadinessRealtimeState>(
      coordinator.realtimeStates,
      (state) => realtimeState.value = state,
    );
    listenStream<bool>(
      coordinator.onlineStream,
      (online) => isOnline.value = online,
    );
    listenStream<bool>(
      coordinator.endpointReachableStream,
      (reachable) => endpointReachable.value = reachable,
    );
    listenStream<bool>(
      coordinator.hiddenToTrayStream,
      (hidden) => isHiddenToTray.value = hidden,
    );
    listenStream<String>(coordinator.activatedItemIds, _onItemActivated);
    listenStream<List<ReadinessDiagnosticEntry>>(
      diagnosticsLog.stream,
      diagnostics.assignAll,
    );

    _loadInitialItems();
  }

  Future<void> _loadInitialItems() async {
    final loaded = await store.loadItems();
    _onItemsChanged(loaded);
  }

  void _onItemsChanged(List<WorkItem> updated) {
    items.assignAll(updated);
    final current = selectedItem.value;
    if (current != null) {
      final match = updated.where((i) => i.id == current.id).firstOrNull;
      if (match != null) {
        selectedItem.value = match;
      }
    } else if (updated.isNotEmpty) {
      selectedItem.value = updated.first;
    }
  }

  void _onItemActivated(String itemId) {
    lastActivatedItemId.value = itemId;
    selectedTab.value = 0;
    final match = items.where((i) => i.id == itemId).firstOrNull;
    if (match != null) {
      selectedItem.value = match;
    }
  }

  void selectTab(int index) {
    selectedTab.value = index;
  }

  void selectItem(WorkItem item) {
    selectedItem.value = item;
  }

  /// Opens the 2-step edit wizard for [item].
  void startWizard(WorkItem item) {
    selectedItem.value = item;
    wizardItemId.value = item.id;
    wizardTitle.value = item.title;
    wizardPriority.value = item.priority;
    wizardStep.value = 1;
  }

  /// Updates controlled wizard step-1 fields.
  void updateWizardStep1({String? title, int? priority}) {
    if (title != null) {
      wizardTitle.value = title;
    }
    if (priority != null) {
      wizardPriority.value = priority;
    }
  }

  /// Advances from step 1 to step 2 if title is non-empty.
  void nextWizardStep() {
    if (wizardStep.value == 1 && wizardTitle.value.trim().isNotEmpty) {
      wizardStep.value = 2;
    }
  }

  /// Returns from step 2 back to step 1.
  void previousWizardStep() {
    if (wizardStep.value == 2) {
      wizardStep.value = 1;
    }
  }

  /// Cancels the wizard without saving.
  void cancelWizard() {
    wizardStep.value = 0;
    wizardItemId.value = null;
  }

  /// Persists the wizard edit to the durable outbox and attempts a flush.
  Future<void> submitWizard() async {
    final itemId = wizardItemId.value;
    final title = wizardTitle.value.trim();
    if (itemId == null || title.isEmpty) return;

    await run(() async {
      final saved = await store.enqueueMutation(
        itemId: itemId,
        title: title,
        priority: wizardPriority.value,
      );
      selectedItem.value = saved;
      await coordinator.reconcileAndFlush();
    }, reportError: false);
    if (error.value.isNotEmpty) return;

    wizardStep.value = 0;
    wizardItemId.value = null;
  }

  Future<void> resolveConflictKeepLocal(String itemId) async {
    await run(() async {
      await store.resolveConflictKeepLocal(itemId);
      await coordinator.reconcileAndFlush();
    }, reportError: false);
    if (error.value.isNotEmpty) return;
  }

  Future<void> resolveConflictAcceptServer(String itemId) async {
    await run(() async {
      await store.resolveConflictAcceptServer(itemId);
    }, reportError: false);
    if (error.value.isNotEmpty) return;
  }

  Future<void> retrySyncNow() async {
    await run(() => coordinator.reconcileAndFlush(), reportError: false);
  }
}
