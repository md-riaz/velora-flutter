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
  testWidgets('components expose semantics and handle large text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePreset.aurora.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: AdaptiveShell(
          destinations: const [
            ShellDestination(icon: Icons.home, label: 'Home'),
            ShellDestination(icon: Icons.search, label: 'Search'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          body: SingleChildScrollView(
            child: Column(
              children: [
                InlineAlert(
                  message: 'A long notice that should wrap at large text sizes',
                  onClose: () {},
                ),
                const EmptyState(
                  icon: Icons.inbox,
                  title: 'Nothing here yet',
                  message: 'Try again later',
                ),
                const Skeleton(),
                ResponsiveDataTable<String>(
                  rows: const ['Alice'],
                  columns: [
                    ResponsiveDataColumn(
                      id: 'name',
                      label: 'A long column name',
                      cell: (row) => Text(row),
                      sortable: true,
                    ),
                  ],
                  onSelectionChanged: (_) {},
                  onSortChanged: (_) {},
                  rowLabel: (row) => row,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Dismiss'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Checkbox && w.semanticLabel == 'Select Alice',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Semantics>(
            find
                .ancestor(
                  of: find.text(
                    'A long notice that should wrap at large text sizes',
                  ),
                  matching: find.byWidgetPredicate(
                    (w) => w is Semantics && w.properties.liveRegion == true,
                  ),
                )
                .first,
          )
          .properties
          .liveRegion,
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byType(Skeleton),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    handle.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'ThemePreset.copyWith and native customization options re-derive themes',
    () {
      final customPreset = ThemePreset.aurora.copyWith(
        name: 'brand',
        seedColor: Colors.teal,
        radius: 14,
        fontFamily: 'Roboto',
      );
      expect(customPreset.name, 'brand');
      expect(customPreset.seedColor, Colors.teal);
      expect(customPreset.radius, 14);
      expect(customPreset.fontFamily, 'Roboto');

      final customTokens = DesignTokens.light.copyWith(
        radiusMd: 20,
        radiusLg: 28,
      );
      const customStatus = StatusColors(
        success: StatusColorPair(Color(0xFF1B5E20), Color(0xFFFFFFFF)),
        warning: StatusColorPair(Color(0xFFE65100), Color(0xFFFFFFFF)),
        info: StatusColorPair(Color(0xFF0D47A1), Color(0xFFFFFFFF)),
        error: StatusColorPair(Color(0xFFB71C1C), Color(0xFFFFFFFF)),
      );
      final theme = ThemePreset.aurora.light(
        tokens: customTokens,
        statusColors: customStatus,
        fontFamily: 'Inter',
        extensions: const [_AppExtension(tag: 'voip')],
      );

      expect(theme.extension<DesignTokens>()?.radiusMd, 20);
      expect(theme.extension<StatusColors>(), customStatus);
      expect(theme.extension<_AppExtension>()?.tag, 'voip');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(cardShape.borderRadius, BorderRadius.circular(28));
    },
  );

  testWidgets('AdaptiveShell forwards Scaffold and NavigationRail options', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePreset.aurora.light(),
        home: AdaptiveShell(
          destinations: const [
            ShellDestination(icon: Icons.call, label: 'Calls'),
            ShellDestination(icon: Icons.contacts, label: 'Contacts'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          backgroundColor: Colors.amber.shade50,
          drawer: const Drawer(child: Text('Menu')),
          extendedRail: true,
          body: const Text('Body'),
        ),
      ),
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, Colors.amber.shade50);
    expect(scaffold.drawer, isNotNull);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.labelType, NavigationRailLabelType.none);
  });
}

class _AppExtension extends ThemeExtension<_AppExtension> {
  const _AppExtension({required this.tag});
  final String tag;

  @override
  _AppExtension copyWith({String? tag}) => _AppExtension(tag: tag ?? this.tag);

  @override
  _AppExtension lerp(covariant _AppExtension? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
