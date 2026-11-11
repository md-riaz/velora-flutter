import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

import '../desktop_scenario.dart';

/// A row in the gallery's demo table.
class DemoRecord {
  /// Creates a demo record.
  const DemoRecord(this.id, this.name, this.role, this.seats);

  /// Stable identifier.
  final int id;

  /// Display name.
  final String name;

  /// Role label.
  final String role;

  /// A number, to demo numeric columns and sorting.
  final int seats;
}

/// The records every data demo in the gallery uses.
const demoRecords = <DemoRecord>[
  DemoRecord(1, 'Ada Lovelace', 'Owner', 12),
  DemoRecord(2, 'Grace Hopper', 'Admin', 8),
  DemoRecord(3, 'Linus Torvalds', 'Member', 3),
  DemoRecord(4, 'Margaret Hamilton', 'Admin', 20),
  DemoRecord(5, 'Alan Turing', 'Member', 5),
  DemoRecord(6, 'Katherine Johnson', 'Member', 7),
  DemoRecord(7, 'Dennis Ritchie', 'Member', 2),
];

/// Returns [records] ordered by [sort]. The table never sorts; its caller
/// does, which is what this stands in for.
List<DemoRecord> sortRecords(List<DemoRecord> records, VeloraSortState? sort) {
  if (sort == null) return records;
  final sorted = [...records];
  int compare(DemoRecord a, DemoRecord b) => switch (sort.columnId) {
    'seats' => a.seats.compareTo(b.seats),
    'role' => a.role.compareTo(b.role),
    _ => a.name.compareTo(b.name),
  };
  sorted.sort((a, b) => sort.ascending ? compare(a, b) : compare(b, a));
  return sorted;
}

/// The column set shared by the gallery's table demos.
final demoColumns = <VeloraDataColumn<DemoRecord>>[
  VeloraDataColumn(
    id: 'name',
    label: 'Name',
    flex: 2,
    sortable: true,
    cell: (r) => Text(r.name),
  ),
  VeloraDataColumn(
    id: 'role',
    label: 'Role',
    sortable: true,
    cell: (r) => VeloraBadge(
      label: r.role,
      status: r.role == 'Owner' ? VeloraStatus.success : VeloraStatus.info,
      style: VeloraBadgeStyle.soft,
    ),
  ),
  VeloraDataColumn(
    id: 'seats',
    label: 'Seats',
    numeric: true,
    sortable: true,
    cell: (r) => Text('${r.seats}'),
  ),
];

/// Showcases velora_ui's Layer 7: [VeloraDataTable] in every state and at
/// phone/tablet/full widths, [VeloraStepper], and [VeloraWizard]. The
/// adaptive shell needs a whole window, so it lives on its own page,
/// [DesktopScenarioPage], opened from the button at the end.
class DataSection extends StatefulWidget {
  /// Creates the data and flows showcase section.
  const DataSection({super.key});

  @override
  State<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<DataSection> {
  static const _states = ['Data', 'Loading', 'Refreshing', 'Empty', 'Error'];
  static const _widths = ['Phone', 'Tablet', 'Full'];
  static const _pageSize = 4;

  int _state = 0;
  int _width = 2;
  int _page = 1;
  VeloraSortState? _sort = const VeloraSortState('name');
  Set<DemoRecord> _selected = {};

  int _wizardStep = 0;
  bool _wizardDone = false;
  final _nameController = TextEditingController();
  String? _nameError;
  String _plan = 'Team';

  static const _wizardSteps = [
    VeloraStep(title: 'Workspace'),
    VeloraStep(title: 'Plan', description: 'Change it any time'),
    VeloraStep(title: 'Invite', optional: true),
    VeloraStep(title: 'Review'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<DemoRecord> get _pageRows {
    if (_state == 1 || _state == 3) return const [];
    final sorted = sortRecords(demoRecords, _sort);
    final start = (_page - 1) * _pageSize;
    return sorted.skip(start).take(_pageSize).toList();
  }

  void _next() {
    if (_wizardStep == 0 && _nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Give the workspace a name');
      return;
    }
    setState(() {
      _nameError = null;
      _wizardStep++;
    });
  }

  Future<void> _submit() async {
    // Stands in for a network call; the wizard blocks a second press.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _wizardDone = true);
  }

  Widget _wizardStepContent(BuildContext context, int index) {
    final tokens = context.veloraTokens;
    return switch (index) {
      0 => VeloraTextField(
        label: 'Workspace name',
        controller: _nameController,
        errorText: _nameError,
      ),
      1 => VeloraRadioGroup<String>(
        label: 'Plan',
        groupValue: _plan,
        onChanged: (v) => setState(() => _plan = v),
        options: const [
          VeloraRadioOption(value: 'Solo', label: 'Solo'),
          VeloraRadioOption(value: 'Team', label: 'Team'),
        ],
      ),
      2 => const VeloraTextField(
        label: 'Invite by email',
        hint: 'Optional — skip with Continue',
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workspace: ${_nameController.text}'),
          SizedBox(height: tokens.spacingXs),
          Text('Plan: $_plan'),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.veloraTokens;
    final pageCount = (demoRecords.length / _pageSize).ceil();
    final previewWidth = switch (_width) {
      0 => 360.0,
      1 => 720.0,
      _ => double.infinity,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VeloraSectionHeader(
          title: 'Data table',
          subtitle: 'Controlled rows, selection, sort, and paging',
        ),
        VeloraTabs(
          tabs: _states,
          selectedIndex: _state,
          onChanged: (i) => setState(() => _state = i),
        ),
        SizedBox(height: tokens.spacingSm),
        VeloraTabs(
          tabs: _widths,
          selectedIndex: _width,
          onChanged: (i) => setState(() => _width = i),
        ),
        SizedBox(height: tokens.spacingMd),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: previewWidth.isFinite
                  ? previewWidth
                  : MediaQuery.sizeOf(context).width - tokens.spacingMd * 2,
            ),
            child: VeloraCard(
              child: VeloraDataTable<DemoRecord>(
                rows: _pageRows,
                columns: demoColumns,
                selected: _selected,
                onSelectionChanged: (s) => setState(() => _selected = s),
                sort: _sort,
                onSortChanged: (s) => setState(() {
                  _sort = s;
                  _page = 1;
                }),
                rowLabel: (r) => r.name,
                loading: _state == 1 || _state == 2,
                error: _state == 4
                    ? VeloraAlert(
                        status: VeloraStatus.error,
                        title: 'Could not load records',
                        message: 'Check your connection and try again.',
                        onClose: () => setState(() => _state = 0),
                      )
                    : null,
                empty: const VeloraEmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No records yet',
                  message: 'Records you add will show up here.',
                ),
                rowActions: (r) => IconButton(
                  tooltip: 'More actions for ${r.name}',
                  icon: const Icon(Icons.more_vert),
                  onPressed: () =>
                      VeloraToast.show(context, message: 'Actions: ${r.name}'),
                ),
                footer: VeloraPagination(
                  page: _page,
                  pageCount: pageCount,
                  onPageChanged: (p) => setState(() => _page = p),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.spacingSm),
        Text('Selected: ${_selected.length}'),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Stepper',
          subtitle: 'Completed, current, error, optional, and disabled steps',
        ),
        VeloraStepper(
          currentStep: 1,
          direction: Axis.vertical,
          steps: const [
            VeloraStep(title: 'Cart'),
            VeloraStep(title: 'Shipping', description: 'Where should it go?'),
            VeloraStep(title: 'Payment', state: VeloraStepState.error),
            VeloraStep(title: 'Gift wrap', optional: true),
            VeloraStep(title: 'Tracking', state: VeloraStepState.disabled),
          ],
        ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Wizard',
          subtitle: 'The caller owns the step, validation, and submission',
        ),
        if (_wizardDone)
          VeloraAlert(
            status: VeloraStatus.success,
            title: 'Workspace created',
            message: '${_nameController.text} is on the $_plan plan.',
            onClose: () => setState(() {
              _wizardDone = false;
              _wizardStep = 0;
            }),
          )
        else
          VeloraCard(
            child: VeloraWizard(
              steps: _wizardSteps,
              currentStep: _wizardStep,
              stepBuilder: _wizardStepContent,
              onNext: _next,
              onBack: () => setState(() => _wizardStep--),
              onSubmit: _submit,
              submitLabel: 'Create workspace',
            ),
          ),
        SizedBox(height: tokens.spacingLg),
        const VeloraSectionHeader(
          title: 'Adaptive shell',
          subtitle: 'Table, detail pane, wizard, and status in one window',
        ),
        VeloraButton(
          label: 'Open desktop scenario',
          icon: Icons.desktop_windows_outlined,
          variant: VeloraButtonVariant.outline,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DesktopScenarioPage(),
            ),
          ),
        ),
      ],
    );
  }
}
