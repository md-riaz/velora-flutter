import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});
  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemePreset preset = ThemePreset.aurora;
  bool dark = false;
  bool compact = false;
  int destination = 0;

  @override
  Widget build(BuildContext context) {
    final density = compact ? VisualDensity.compact : VisualDensity.standard;
    return MaterialApp(
      title: 'ThemePreset Gallery',
      theme: preset.light(visualDensity: density),
      darkTheme: preset.dark(visualDensity: density),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: AdaptiveShell(
        destinations: const [
          ShellDestination(icon: Icons.palette_outlined, label: 'Showcase'),
          ShellDestination(icon: Icons.table_chart_outlined, label: 'Data'),
        ],
        selectedIndex: destination,
        onDestinationSelected: (value) => setState(() => destination = value),
        appBar: AppBar(title: const Text('ThemePreset Gallery')),
        body: Builder(
          builder: (context) {
            final tokens = DesignTokens.of(context);
            return ListView(
              padding: EdgeInsets.all(tokens.spacingMd),
              children: [
                Wrap(
                  spacing: tokens.spacingMd,
                  runSpacing: tokens.spacingSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownMenu<ThemePreset>(
                      key: const ValueKey('preset'),
                      label: const Text('Preset'),
                      initialSelection: preset,
                      dropdownMenuEntries: [
                        for (final p in [
                          ThemePreset.aurora,
                          ThemePreset.meadow,
                          ThemePreset.neutral,
                          ThemePreset.corporate,
                        ])
                          DropdownMenuEntry(value: p, label: p.name),
                      ],
                      onSelected: (value) {
                        if (value != null) setState(() => preset = value);
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Dark'),
                        Switch(
                          key: const ValueKey('brightness'),
                          value: dark,
                          onChanged: (value) => setState(() => dark = value),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Compact'),
                        Switch(
                          key: const ValueKey('density'),
                          value: compact,
                          onChanged: (value) => setState(() => compact = value),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: tokens.spacingLg),
                Text(
                  '${preset.name} / ${dark ? 'dark' : 'light'} / ${compact ? 'compact' : 'standard'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: tokens.spacingLg),
                if (destination == 0)
                  const Showcase()
                else
                  const DataShowcase(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class Showcase extends StatefulWidget {
  const Showcase({super.key});
  @override
  State<Showcase> createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> {
  bool checked = true;
  bool enabled = true;
  String choice = 'One';

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final colors = StatusColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Buttons and inputs',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: tokens.spacingMd),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: [
            FilledButton(onPressed: () {}, child: const Text('Filled')),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            TextButton(onPressed: () {}, child: const Text('Text')),
            const FilledButton(onPressed: null, child: Text('Disabled')),
          ],
        ),
        SizedBox(height: tokens.spacingMd),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter a name',
          ),
        ),
        SizedBox(height: tokens.spacingMd),
        DropdownMenu<String>(
          label: const Text('Role'),
          initialSelection: 'Member',
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 'Member', label: 'Member'),
            DropdownMenuEntry(value: 'Admin', label: 'Admin'),
          ],
        ),
        CheckboxListTile(
          title: const Text('Checkbox'),
          value: checked,
          onChanged: (v) => setState(() => checked = v ?? false),
        ),
        SwitchListTile(
          title: const Text('Switch'),
          value: enabled,
          onChanged: (v) => setState(() => enabled = v),
        ),
        RadioGroup<String>(
          groupValue: choice,
          onChanged: (v) => setState(() => choice = v ?? choice),
          child: const Row(
            children: [
              Radio<String>(value: 'One'),
              Text('One'),
              Radio<String>(value: 'Two'),
              Text('Two'),
            ],
          ),
        ),
        const Divider(),
        DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Details'),
                ],
              ),
              SizedBox(
                height: 64,
                child: TabBarView(
                  children: [
                    Center(child: Text('Overview content')),
                    Center(child: Text('Details content')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: CircleAvatar(child: Text('A')),
                title: Text('Ada Lovelace'),
                subtitle: Text('Member'),
                trailing: Badge(
                  label: Text('3'),
                  child: Icon(Icons.notifications_outlined),
                ),
              ),
              const Divider(),
              Padding(
                padding: EdgeInsets.all(tokens.spacingMd),
                child: const Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('Active')),
                    Tooltip(
                      message: 'More information',
                      child: Icon(Icons.info_outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacingMd),
        const LinearProgressIndicator(value: .65),
        SizedBox(height: tokens.spacingMd),
        const Align(
          alignment: Alignment.centerLeft,
          child: CircularProgressIndicator(value: .4),
        ),
        SizedBox(height: tokens.spacingLg),
        Text('Status colors', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: tokens.spacingSm),
        Wrap(
          spacing: tokens.spacingSm,
          runSpacing: tokens.spacingSm,
          children: [
            for (final tone in StatusTone.values)
              Chip(
                avatar: CircleAvatar(
                  backgroundColor: colors.forTone(tone).color,
                ),
                label: Text(tone.name),
              ),
          ],
        ),
        SizedBox(height: tokens.spacingMd),
        for (final tone in StatusTone.values) ...[
          InlineAlert(
            status: tone,
            title: tone.name,
            message: 'A themed ${tone.name} message.',
          ),
          SizedBox(height: tokens.spacingSm),
        ],
        const Skeleton.text(width: 180),
        const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nothing here yet',
          message: 'An example empty state.',
        ),
      ],
    );
  }
}

class DataShowcase extends StatefulWidget {
  const DataShowcase({super.key});
  @override
  State<DataShowcase> createState() => _DataShowcaseState();
}

class _DataShowcaseState extends State<DataShowcase> {
  TableSortState sort = const TableSortState('name');
  Set<String> selected = {};
  @override
  Widget build(BuildContext context) {
    final rows = ['Ada', 'Grace', 'Alan']
      ..sort((a, b) => sort.ascending ? a.compareTo(b) : b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Responsive data table',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        ResponsiveDataTable<String>(
          rows: rows,
          columns: [
            ResponsiveDataColumn<String>(
              id: 'name',
              label: 'Name',
              sortable: true,
              cell: (row) => Text(row),
            ),
          ],
          sort: sort,
          onSortChanged: (value) => setState(() => sort = value),
          selected: selected,
          onSelectionChanged: (value) => setState(() => selected = value),
          rowLabel: (row) => row,
        ),
        Text('Selected: ${selected.length}'),
      ],
    );
  }
}
