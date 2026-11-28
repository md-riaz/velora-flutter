// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:velora/velora.dart';
import 'package:velora_ui/velora_ui.dart';

import '../contracts/realtime_port.dart';
import '../controllers/readiness_controller.dart';
import '../models/work_item.dart';

/// Root UI for the Desktop Readiness application.
///
/// Strictly decoupled from `velora_desktop`, `flutter_local_notifications`,
/// and `drift` — all platform interactions go through [ReadinessController].
class ReadinessApp extends StatelessWidget {
  final ReadinessController controller;
  final Future<void> Function()? onHideToTray;
  final Future<void> Function()? onRestoreFromTray;
  final Future<void> Function()? onSimulateSuspend;
  final Future<void> Function()? onSimulateResume;
  final VoidCallback? onTriggerConflict;
  final VoidCallback? onEmitRemoteEvent;
  final Future<void> Function(String itemId)? onSimulateNotification;
  final VoidCallback? onSimulateMalformedNotification;

  const ReadinessApp({
    super.key,
    required this.controller,
    this.onHideToTray,
    this.onRestoreFromTray,
    this.onSimulateSuspend,
    this.onSimulateResume,
    this.onTriggerConflict,
    this.onEmitRemoteEvent,
    this.onSimulateNotification,
    this.onSimulateMalformedNotification,
  });

  static const List<ShellDestination> _destinations = [
    ShellDestination(
      icon: Icons.checklist_outlined,
      selectedIcon: Icons.checklist,
      label: 'Work Items',
    ),
    ShellDestination(
      icon: Icons.terminal_outlined,
      selectedIcon: Icons.terminal,
      label: 'Diagnostics',
    ),
    ShellDestination(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      label: 'Simulation',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora Desktop Readiness',
      debugShowCheckedModeBanner: false,
      theme: ThemePreset.aurora.light(),
      darkTheme: ThemePreset.aurora.dark(),
      home: _ReadinessHome(
        controller: controller,
        onHideToTray: onHideToTray,
        onRestoreFromTray: onRestoreFromTray,
        onSimulateSuspend: onSimulateSuspend,
        onSimulateResume: onSimulateResume,
        onTriggerConflict: onTriggerConflict,
        onEmitRemoteEvent: onEmitRemoteEvent,
        onSimulateNotification: onSimulateNotification,
        onSimulateMalformedNotification: onSimulateMalformedNotification,
      ),
    );
  }
}

class _ReadinessHome extends StatelessWidget {
  final ReadinessController controller;
  final Future<void> Function()? onHideToTray;
  final Future<void> Function()? onRestoreFromTray;
  final Future<void> Function()? onSimulateSuspend;
  final Future<void> Function()? onSimulateResume;
  final VoidCallback? onTriggerConflict;
  final VoidCallback? onEmitRemoteEvent;
  final Future<void> Function(String itemId)? onSimulateNotification;
  final VoidCallback? onSimulateMalformedNotification;

  const _ReadinessHome({
    required this.controller,
    this.onHideToTray,
    this.onRestoreFromTray,
    this.onSimulateSuspend,
    this.onSimulateResume,
    this.onTriggerConflict,
    this.onEmitRemoteEvent,
    this.onSimulateNotification,
    this.onSimulateMalformedNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.selectedTab.value;
      return AdaptiveShell(
        destinations: ReadinessApp._destinations,
        selectedIndex: tab,
        onDestinationSelected: controller.selectTab,
        appBar: AppBar(
          title: const Text('Velora Desktop Readiness'),
          actions: [
            IconButton(
              tooltip: 'Sync now',
              onPressed: controller.retrySyncNow,
              icon: const Icon(Icons.sync),
            ),
            if (onHideToTray != null)
              IconButton(
                tooltip: 'Hide to tray',
                onPressed: onHideToTray,
                icon: const Icon(Icons.visibility_off_outlined),
              ),
          ],
        ),
        brandHeader: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Icon(Icons.desktop_windows, size: 28),
        ),
        statusFooter: Obx(() {
          final state = controller.realtimeState.value;
          return Tooltip(
            message: 'Realtime: ${state.name}',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Icon(
                state == ReadinessRealtimeState.connected
                    ? Icons.cloud_done
                    : state == ReadinessRealtimeState.unauthorized
                    ? Icons.lock_outline
                    : Icons.cloud_off,
                size: 20,
              ),
            ),
          );
        }),
        status: _ConnectivityStatusBanner(controller: controller),
        body: IndexedStack(
          index: tab,
          children: [
            _WorkItemsView(controller: controller),
            _DiagnosticsView(controller: controller),
            _SimulationView(
              controller: controller,
              onHideToTray: onHideToTray,
              onRestoreFromTray: onRestoreFromTray,
              onSimulateSuspend: onSimulateSuspend,
              onSimulateResume: onSimulateResume,
              onTriggerConflict: onTriggerConflict,
              onEmitRemoteEvent: onEmitRemoteEvent,
              onSimulateNotification: onSimulateNotification,
              onSimulateMalformedNotification: onSimulateMalformedNotification,
            ),
          ],
        ),
      );
    });
  }
}

class _ConnectivityStatusBanner extends StatelessWidget {
  final ReadinessController controller;

  const _ConnectivityStatusBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final online = controller.isOnline.value;
      final reachable = controller.endpointReachable.value;
      final rt = controller.realtimeState.value;
      final hidden = controller.isHiddenToTray.value;
      final activated = controller.lastActivatedItemId.value;

      final Color bg;
      final Color fg;
      final String label;

      if (rt == ReadinessRealtimeState.unauthorized) {
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        label = 'Unauthorized — outbox paused until credentials are restored';
      } else if (!online) {
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        label = 'Offline — edits queued durably in local SQLite outbox';
      } else if (!reachable) {
        bg = scheme.tertiaryContainer;
        fg = scheme.onTertiaryContainer;
        label = 'Endpoint unreachable — waiting to replay outbox';
      } else {
        bg = scheme.primaryContainer;
        fg = scheme.onPrimaryContainer;
        label = 'Online • Realtime: ${rt.name}';
      }

      return Material(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: fg),
              ),
              if (hidden)
                Text(
                  '[Tray Mode]',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: fg),
                ),
              if (activated != null)
                Text(
                  'Activated: $activated',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: fg),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _WorkItemsView extends StatelessWidget {
  final ReadinessController controller;

  const _WorkItemsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.items.toList();
      final selected = controller.selectedItem.value;
      final step = controller.wizardStep.value;

      if (step > 0) {
        return _EditWizardPane(controller: controller);
      }

      if (list.isEmpty) {
        return const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No work items',
          message: 'Seeded work items will appear here.',
        );
      }

      return MasterDetail<WorkItem>(
        selected: selected,
        onSelected: controller.selectItem,
        emptyDetail: const EmptyState(
          icon: Icons.touch_app_outlined,
          title: 'Select a work item',
          message: 'Choose an item from the list to inspect or edit.',
        ),
        masterBuilder: (context, onSelect) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = list[index];
            final isSelected = selected?.id == item.id;
            return ContextMenuRegion<String>(
              items: const [
                PopupMenuItem(value: 'edit', child: Text('Edit in Wizard')),
                PopupMenuItem(value: 'sync', child: Text('Sync Now')),
              ],
              onSelected: (action) {
                if (action == 'edit') {
                  controller.startWizard(item);
                } else if (action == 'sync') {
                  controller.retrySyncNow();
                }
              },
              child: SurfaceCard(
                onTap: () => onSelect(item),
                color: isSelected
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text('${item.id} • v${item.version}'),
                              Text('P${item.priority}'),
                              Text(item.syncStatus.name),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit ${item.id}',
                      onPressed: () => controller.startWizard(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        detailBuilder: (context, item) =>
            _WorkItemDetailPane(controller: controller, item: item),
      );
    });
  }
}

class _WorkItemDetailPane extends StatelessWidget {
  final ReadinessController controller;
  final WorkItem item;

  const _WorkItemDetailPane({required this.controller, required this.item});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('ID: ${item.id}')),
                    Chip(label: Text('Priority: ${item.priority}')),
                    Chip(label: Text('Version: ${item.version}')),
                    Chip(label: Text('Status: ${item.syncStatus.name}')),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => controller.startWizard(item),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit in 2-Step Wizard'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.retrySyncNow,
                      icon: const Icon(Icons.sync),
                      label: const Text('Flush Outbox'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item.syncStatus == SyncStatus.conflict) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sync Conflict Detected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Local title: ${item.title}'),
                  Text('Server title: ${item.serverTitle ?? '(unknown)'}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () =>
                            controller.resolveConflictKeepLocal(item.id),
                        child: const Text('Keep Local'),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            controller.resolveConflictAcceptServer(item.id),
                        child: const Text('Accept Server'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (item.syncStatus == SyncStatus.permanentFailure) ...[
            const SizedBox(height: 16),
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permanent Auth Failure',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(item.lastError ?? 'Authorization required.'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditWizardPane extends StatefulWidget {
  final ReadinessController controller;

  const _EditWizardPane({required this.controller});

  @override
  State<_EditWizardPane> createState() => _EditWizardPaneState();
}

class _EditWizardPaneState extends State<_EditWizardPane> {
  late final TextEditingController _titleController;
  String? _boundItemId;

  @override
  void initState() {
    super.initState();
    _boundItemId = widget.controller.wizardItemId.value;
    _titleController = TextEditingController(
      text: widget.controller.wizardTitle.value,
    );
  }

  @override
  void didUpdateWidget(covariant _EditWizardPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentId = widget.controller.wizardItemId.value;
    final currentTitle = widget.controller.wizardTitle.value;
    if (_boundItemId != currentId || _titleController.text != currentTitle) {
      _boundItemId = currentId;
      _titleController.value = TextEditingValue(
        text: currentTitle,
        selection: TextSelection.collapsed(offset: currentTitle.length),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = widget.controller.wizardStep.value;
      final priority = widget.controller.wizardPriority.value;
      final title = widget.controller.wizardTitle.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Work Item — Step $step of 2',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (step == 1) ...[
                TextField(
                  key: const Key('wizard-title-field'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      widget.controller.updateWizardStep1(title: value),
                ),
                const SizedBox(height: 16),
                Text('Priority', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in [1, 2, 3, 4])
                      ChoiceChip(
                        label: Text('P$p'),
                        selected: priority == p,
                        onSelected: (_) =>
                            widget.controller.updateWizardStep1(priority: p),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      key: const Key('wizard-next-button'),
                      onPressed: title.trim().isEmpty
                          ? null
                          : widget.controller.nextWizardStep,
                      child: const Text('Next'),
                    ),
                    OutlinedButton(
                      onPressed: widget.controller.cancelWizard,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ] else ...[
                Text('Title: $title'),
                const SizedBox(height: 8),
                Text('Priority: P$priority'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      key: const Key('wizard-submit-button'),
                      onPressed: widget.controller.submitWizard,
                      child: const Text('Save & Sync'),
                    ),
                    OutlinedButton(
                      onPressed: widget.controller.previousWizardStep,
                      child: const Text('Back'),
                    ),
                    TextButton(
                      onPressed: widget.controller.cancelWizard,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _DiagnosticsView extends StatelessWidget {
  final ReadinessController controller;

  const _DiagnosticsView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = controller.diagnostics.reversed.toList();
      if (entries.isEmpty) {
        return const EmptyState(
          icon: Icons.terminal_outlined,
          title: 'No diagnostics yet',
          message: 'Lifecycle and sync events will appear here (redacted).',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${entry.category}] ${entry.message}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (entry.metadata.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.metadata.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }
}

class _SimulationView extends StatelessWidget {
  final ReadinessController controller;
  final Future<void> Function()? onHideToTray;
  final Future<void> Function()? onRestoreFromTray;
  final Future<void> Function()? onSimulateSuspend;
  final Future<void> Function()? onSimulateResume;
  final VoidCallback? onTriggerConflict;
  final VoidCallback? onEmitRemoteEvent;
  final Future<void> Function(String itemId)? onSimulateNotification;
  final VoidCallback? onSimulateMalformedNotification;

  const _SimulationView({
    required this.controller,
    this.onHideToTray,
    this.onRestoreFromTray,
    this.onSimulateSuspend,
    this.onSimulateResume,
    this.onTriggerConflict,
    this.onEmitRemoteEvent,
    this.onSimulateNotification,
    this.onSimulateMalformedNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final online = controller.isOnline.value;
      final reachable = controller.endpointReachable.value;
      final unauthorized =
          controller.realtimeState.value == ReadinessRealtimeState.unauthorized;
      final hidden = controller.isHiddenToTray.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulation Controls',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Network Online'),
                    value: online,
                    onChanged: controller.coordinator.setNetworkOnline,
                  ),
                  SwitchListTile(
                    title: const Text('Endpoint Reachable'),
                    value: reachable,
                    onChanged: controller.coordinator.setEndpointReachable,
                  ),
                  SwitchListTile(
                    title: const Text('Unauthorized Mode'),
                    value: unauthorized,
                    onChanged: controller.coordinator.setUnauthorizedMode,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: hidden ? onRestoreFromTray : onHideToTray,
                        child: Text(
                          hidden ? 'Restore from Tray' : 'Hide to Tray',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onSimulateSuspend,
                        child: const Text('Simulate Sleep'),
                      ),
                      OutlinedButton(
                        onPressed: onSimulateResume,
                        child: const Text('Simulate Wake'),
                      ),
                      OutlinedButton(
                        onPressed: onTriggerConflict,
                        child: const Text('Arm Conflict on Next Sync'),
                      ),
                      OutlinedButton(
                        onPressed: onEmitRemoteEvent,
                        child: const Text('Emit Remote Event'),
                      ),
                      OutlinedButton(
                        onPressed: () => onSimulateNotification?.call('WI-102'),
                        child: const Text('Simulate Notification (WI-102)'),
                      ),
                      OutlinedButton(
                        onPressed: onSimulateMalformedNotification,
                        child: const Text('Simulate Malformed Notification'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
