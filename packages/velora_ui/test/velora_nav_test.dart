import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

/// Pumps [child] under a Velora theme + Material scaffold so the components
/// can resolve `context.veloraTokens` and the `ColorScheme`.
Future<void> pumpUnderTheme(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: VeloraTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  const destinations = [
    VeloraNavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    VeloraNavDestination(icon: Icons.search, label: 'Search'),
    VeloraNavDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  group('VeloraNavBar', () {
    testWidgets('renders all destination labels', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraNavBar(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows selectedIcon for the selected item', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraNavBar(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      );

      // Home is selected: shows the filled `selectedIcon`, not the outline.
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      // Settings is not selected: shows the outline `icon`.
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('fires onDestinationSelected with the tapped index', (
      tester,
    ) async {
      int? tapped;
      await pumpUnderTheme(
        tester,
        VeloraNavBar(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (i) => tapped = i,
        ),
      );

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(tapped, 2);
    });

    testWidgets('exposes the selected flag on the selected destination', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpUnderTheme(
        tester,
        VeloraNavBar(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      );

      expect(
        tester.getSemantics(find.text('Home')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.text('Search')),
        isSemantics(isSelected: false),
      );

      handle.dispose();
    });

    test('throws an AssertionError for an out-of-range selectedIndex', () {
      expect(
        () => VeloraNavBar(
          destinations: destinations,
          selectedIndex: 5,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('throws an AssertionError when destinations is empty', () {
      expect(
        () => VeloraNavBar(
          destinations: const [],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('VeloraNavRail', () {
    testWidgets('renders all destination labels', (tester) async {
      await pumpUnderTheme(
        tester,
        SizedBox(
          height: 600,
          child: VeloraNavRail(
            destinations: destinations,
            selectedIndex: 1,
            onDestinationSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('fires onDestinationSelected with the tapped index', (
      tester,
    ) async {
      int? tapped;
      await pumpUnderTheme(
        tester,
        SizedBox(
          height: 600,
          child: VeloraNavRail(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (i) => tapped = i,
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('renders optional leading and trailing widgets', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        SizedBox(
          height: 600,
          child: VeloraNavRail(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            leading: const Icon(Icons.bolt),
            trailing: const Icon(Icons.more_horiz),
          ),
        ),
      );

      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('builds correctly under RTL directionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VeloraTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  height: 600,
                  child: VeloraNavRail(
                    destinations: destinations,
                    selectedIndex: 1,
                    onDestinationSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(VeloraNavRail), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    test('throws an AssertionError for an out-of-range selectedIndex', () {
      expect(
        () => VeloraNavRail(
          destinations: destinations,
          selectedIndex: 5,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('throws an AssertionError when destinations is empty', () {
      expect(
        () => VeloraNavRail(
          destinations: const [],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('VeloraTabs', () {
    const tabs = ['Day', 'Week', 'Month'];

    testWidgets('renders all tab labels', (tester) async {
      await pumpUnderTheme(
        tester,
        SizedBox(
          width: 300,
          child: VeloraTabs(tabs: tabs, selectedIndex: 0, onChanged: (_) {}),
        ),
      );

      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });

    testWidgets('fires onChanged with the tapped index', (tester) async {
      int? changed;
      await pumpUnderTheme(
        tester,
        SizedBox(
          width: 300,
          child: VeloraTabs(
            tabs: tabs,
            selectedIndex: 0,
            onChanged: (i) => changed = i,
          ),
        ),
      );

      await tester.tap(find.text('Week'));
      // No pumpAndSettle: the selected-segment pill/label animate via
      // AnimatedPositioned/AnimatedDefaultTextStyle on the token's motion
      // duration, so a single fixed pump past it is enough (and non-flaky).
      await tester.pump(VeloraTokens.light.motionNormal);
      expect(changed, 1);
    });

    testWidgets('reflects selectedIndex in the sliding pill position', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        SizedBox(
          width: 300,
          child: VeloraTabs(tabs: tabs, selectedIndex: 1, onChanged: (_) {}),
        ),
      );
      await tester.pump(VeloraTokens.light.motionNormal);

      final positioned = tester.widget<AnimatedPositionedDirectional>(
        find.byType(AnimatedPositionedDirectional),
      );
      // 3 equal segments: the pill's directional-start edge should sit
      // exactly one segment-width in for selectedIndex 1, whatever the
      // track's padded content width works out to.
      expect(positioned.start, closeTo(positioned.width!, 0.01));
    });

    testWidgets('throws an AssertionError when tabs is empty', (tester) async {
      expect(
        () => VeloraTabs(tabs: const [], selectedIndex: 0, onChanged: (_) {}),
        throwsAssertionError,
      );
    });

    test('throws an AssertionError for an out-of-range selectedIndex', () {
      expect(
        () => VeloraTabs(tabs: tabs, selectedIndex: 5, onChanged: (_) {}),
        throwsAssertionError,
      );
    });

    testWidgets('exposes the selected flag on the selected segment', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pumpUnderTheme(
        tester,
        SizedBox(
          width: 300,
          child: VeloraTabs(tabs: tabs, selectedIndex: 1, onChanged: (_) {}),
        ),
      );

      expect(
        tester.getSemantics(find.text('Week')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.text('Day')),
        isSemantics(isSelected: false),
      );

      handle.dispose();
    });

    testWidgets('builds correctly under RTL directionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VeloraTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: VeloraTabs(
                    tabs: tabs,
                    selectedIndex: 1,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(VeloraTokens.light.motionNormal);

      expect(find.byType(AnimatedPositionedDirectional), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
    });
  });

  group('VeloraScaffold', () {
    testWidgets('renders title, body, and bottomNavigationBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VeloraTheme.light(),
          home: VeloraScaffold(
            title: 'Dashboard',
            body: const Text('Body content'),
            bottomNavigationBar: VeloraNavBar(
              destinations: destinations,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Body content'), findsOneWidget);
      expect(find.byType(VeloraNavBar), findsOneWidget);
    });

    testWidgets('renders no AppBar when title/leading/actions are all null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VeloraTheme.light(),
          home: const VeloraScaffold(body: Text('Just content')),
        ),
      );

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Just content'), findsOneWidget);
    });
  });
}
