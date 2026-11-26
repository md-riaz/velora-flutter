import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

void main() {
  for (final preset in [
    ThemePreset.aurora,
    ThemePreset.meadow,
    ThemePreset.neutral,
    ThemePreset.corporate,
  ]) {
    for (final brightness in Brightness.values) {
      test('${preset.name} $brightness', () {
        final theme = brightness == Brightness.light
            ? preset.light()
            : preset.dark();
        expect(theme.brightness, brightness);
        expect(
          theme.colorScheme,
          ColorScheme.fromSeed(
            seedColor: preset.seedColor,
            brightness: brightness,
            dynamicSchemeVariant: identical(preset, ThemePreset.neutral)
                ? DynamicSchemeVariant.monochrome
                : DynamicSchemeVariant.tonalSpot,
          ),
        );
        expect(theme.extension<DesignTokens>(), isNotNull);
        expect(theme.extension<StatusColors>(), isNotNull);
        expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
        expect(
          theme.navigationBarTheme.indicatorColor,
          theme.colorScheme.secondaryContainer,
        );
        expect(
          theme.checkboxTheme.fillColor!.resolve({WidgetState.selected}),
          theme.colorScheme.primary,
        );
        expect(
          theme.switchTheme.thumbColor!.resolve({WidgetState.selected}),
          isNot(theme.switchTheme.trackColor!.resolve({WidgetState.selected})),
        );
        expect(
          theme.switchTheme.thumbColor!.resolve({}),
          isNot(theme.switchTheme.trackColor!.resolve({})),
        );
      });
    }
  }
  test('scheme wins over seed and seed wins over preset', () {
    const seed = Colors.orange;
    final scheme = ColorScheme.fromSeed(seedColor: Colors.red);
    expect(
      ThemePreset.meadow
          .light(seedColor: seed, colorScheme: scheme)
          .colorScheme,
      scheme,
    );
    expect(
      ThemePreset.meadow.light(seedColor: seed).colorScheme,
      ColorScheme.fromSeed(seedColor: seed),
    );
    expect(
      ThemePreset.corporate
          .light(visualDensity: VisualDensity.compact)
          .visualDensity,
      VisualDensity.compact,
    );
  });
  testWidgets('retained components render', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePreset.aurora.light(),
        home: AdaptiveShell(
          destinations: const [
            ShellDestination(icon: Icons.home, label: 'Home'),
            ShellDestination(icon: Icons.search, label: 'Search'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          body: const Column(
            children: [
              InlineAlert(message: 'Notice'),
              EmptyState(icon: Icons.inbox, title: 'Empty'),
              Skeleton(),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Notice'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('native widgets pick up preset theme and compact density', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePreset.aurora.light(visualDensity: VisualDensity.compact),
        home: Scaffold(
          body: Column(
            children: [
              FilledButton(onPressed: () {}, child: const Text('Go')),
              const TextField(),
              const Card(child: Text('Card')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(Card), findsOneWidget);
    final standardHeight = ThemePreset.aurora
        .light()
        .visualDensity
        .baseSizeAdjustment
        .dy;
    final compactHeight = ThemePreset.aurora
        .light(visualDensity: VisualDensity.compact)
        .visualDensity
        .baseSizeAdjustment
        .dy;
    expect(compactHeight, lessThan(standardHeight));
  });
  testWidgets('responsive table renders rows and reports sorting', (
    tester,
  ) async {
    TableSortState? sort;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePreset.meadow.light(),
        home: Scaffold(
          body: ResponsiveDataTable<String>(
            rows: const ['Alice'],
            columns: [
              ResponsiveDataColumn<String>(
                id: 'name',
                label: 'Name',
                cell: (row) => Text(row),
                sortable: true,
              ),
            ],
            onSortChanged: (value) => sort = value,
          ),
        ),
      ),
    );
    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.text('Name').first);
    expect(sort, const TableSortState('name'));
  });
  testWidgets('missing theme extensions throw', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(() => DesignTokens.of(context), throwsStateError);
    expect(() => StatusColors.of(context), throwsStateError);
  });
}
