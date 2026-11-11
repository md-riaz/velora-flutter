import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

import 'sections/data_section.dart';

/// What the scenario pretends the app's connection is doing. In a real app
/// this comes from the app's own connectivity and sync services; velora_ui
/// only renders what it is told.
enum _Connection { online, offline, syncing }

/// A resizable, keyboard-operable scenario that puts Layer 7 together:
/// a [VeloraAdaptiveShell] around a [VeloraMasterDetailShell] with a
/// [VeloraDataTable], a [VeloraWizard] destination, a caller-driven
/// [VeloraStatusStrip], and a button that selects a destination the way a
/// deep link or notification would — by changing caller-owned state.
///
/// Resize the window (or use the width menu) to cross the compact, medium,
/// and expanded breakpoints: the selected destination, the open record, the
/// table selection, and the wizard's step and text all survive.
class DesktopScenarioPage extends StatefulWidget {
  /// Creates the scenario page.
  const DesktopScenarioPage({super.key});

  @override
  State<DesktopScenarioPage> createState() => _DesktopScenarioPageState();
}

class _DesktopScenarioPageState extends State<DesktopScenarioPage> {
  static const _destinations = [
    VeloraNavDestination(
      icon: Icons.table_rows_outlined,
      selectedIcon: Icons.table_rows,
      label: 'Records',
    ),
    VeloraNavDestination(
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle,
      label: 'New',
    ),
    VeloraNavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  static const _steps = [
    VeloraStep(title: 'Details'),
    VeloraStep(title: 'Role'),
    VeloraStep(title: 'Confirm'),
  ];

  int _destination = 0;
  _Connection _connection = _Connection.online;
  double? _previewWidth;

  DemoRecord? _open;
  Set<DemoRecord> _selected = {};
  VeloraSortState? _sort = const VeloraSortState('name');

  int _step = 0;
  final _nameController = TextEditingController();
  String _role = 'Member';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget? get _status => switch (_connection) {
    _Connection.online => null,
    _Connection.offline => VeloraStatusStrip(
      icon: Icons.cloud_off_outlined,
      message: 'Offline — changes will sync when you reconnect',
      action: TextButton(
        onPressed: () => setState(() => _connection = _Connection.syncing),
        child: const Text('Retry'),
      ),
    ),
    _Connection.syncing => const VeloraStatusStrip(
      busy: true,
      message: 'Synchronizing 3 pending changes…',
    ),
  };

  Widget _records() {
    return VeloraMasterDetailShell(
      onCloseDetail: () => setState(() => _open = null),
      placeholder: const VeloraEmptyState(
        icon: Icons.touch_app_outlined,
        title: 'Select a record',
        message: 'Use the arrow keys and Enter, or click a row.',
      ),
      master: SingleChildScrollView(
        padding: EdgeInsets.all(context.veloraTokens.spacingSm),
        child: VeloraDataTable<DemoRecord>(
          rows: sortRecords(demoRecords, _sort),
          columns: demoColumns,
          selected: _selected,
          onSelectionChanged: (s) => setState(() => _selected = s),
          sort: _sort,
          onSortChanged: (s) => setState(() => _sort = s),
          rowLabel: (r) => r.name,
          onRowTap: (r) => setState(() => _open = r),
        ),
      ),
      detail: _open == null ? null : _detail(_open!),
    );
  }

  Widget _detail(DemoRecord record) {
    final tokens = context.veloraTokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Close (Esc)',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _open = null),
              ),
            ],
          ),
          SizedBox(height: tokens.spacingSm),
          Text('Role: ${record.role}'),
          Text('Seats: ${record.seats}'),
          SizedBox(height: tokens.spacingMd),
          VeloraButton(
            label: 'Edit in wizard',
            icon: Icons.edit_outlined,
            onPressed: () => setState(() {
              _nameController.text = record.name;
              _role = record.role;
              _step = 0;
              _destination = 1;
            }),
          ),
        ],
      ),
    );
  }

  Widget _wizard() {
    final tokens = context.veloraTokens;
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spacingMd),
      child: VeloraWizard(
        steps: _steps,
        currentStep: _step,
        onNext: () => setState(() => _step++),
        onBack: () => setState(() => _step--),
        onStepTapped: (i) => setState(() => _step = i),
        onSubmit: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          VeloraToast.show(
            context,
            status: VeloraStatus.success,
            message: 'Saved ${_nameController.text}',
          );
          setState(() {
            _step = 0;
            _destination = 0;
          });
        },
        submitLabel: 'Save',
        stepBuilder: (context, index) => switch (index) {
          0 => VeloraTextField(label: 'Name', controller: _nameController),
          1 => VeloraSelect<String>(
            label: 'Role',
            value: _role,
            onChanged: (v) => setState(() => _role = v ?? _role),
            options: const [
              VeloraSelectOption(value: 'Owner', label: 'Owner'),
              VeloraSelectOption(value: 'Admin', label: 'Admin'),
              VeloraSelectOption(value: 'Member', label: 'Member'),
            ],
          ),
          _ => Text('${_nameController.text} · $_role'),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final shell = VeloraAdaptiveShell(
      destinations: _destinations,
      selectedIndex: _destination,
      onDestinationSelected: (i) => setState(() => _destination = i),
      status: _status,
      appBar: AppBar(
        title: const Text('Desktop scenario'),
        actions: [
          IconButton(
            tooltip: 'Cycle connection status',
            icon: Icon(switch (_connection) {
              _Connection.online => Icons.cloud_done_outlined,
              _Connection.offline => Icons.cloud_off_outlined,
              _Connection.syncing => Icons.cloud_sync_outlined,
            }),
            onPressed: () => setState(
              () => _connection = _Connection
                  .values[(_connection.index + 1) % _Connection.values.length],
            ),
          ),
          IconButton(
            tooltip: 'Simulate an external link to Settings',
            icon: const Icon(Icons.link),
            onPressed: () => setState(() => _destination = 2),
          ),
          PopupMenuButton<double?>(
            tooltip: 'Preview width',
            icon: const Icon(Icons.aspect_ratio),
            onSelected: (w) => setState(() => _previewWidth = w),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 400, child: Text('Phone (400)')),
              PopupMenuItem(value: 800, child: Text('Tablet (800)')),
              PopupMenuItem(value: null, child: Text('Window width')),
            ],
          ),
          SizedBox(width: tokens.spacingSm),
        ],
      ),
      secondaryPane: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VeloraSectionHeader(title: 'Activity'),
            Text('Selected rows: ${_selected.length}'),
            Text('Open record: ${_open?.name ?? 'none'}'),
            Text('Wizard step: ${_step + 1} of ${_steps.length}'),
          ],
        ),
      ),
      // One body per destination, all kept alive, so switching destinations
      // (or being sent to one by a link) never drops what was typed.
      body: IndexedStack(
        index: _destination,
        children: [
          _records(),
          _wizard(),
          const Center(child: Text('Settings')),
        ],
      ),
    );

    final width = _previewWidth;
    if (width == null) return shell;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(width: width, child: shell),
      ),
    );
  }
}
