import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

void main() {
  group('AdaptiveShell compactOnly', () {
    const destinations = [
      ShellDestination(icon: Icons.call, label: 'Calls'),
      ShellDestination(icon: Icons.dialpad, label: 'Keypad', compactOnly: true),
      ShellDestination(icon: Icons.contacts, label: 'Contacts'),
      ShellDestination(icon: Icons.settings, label: 'Settings'),
    ];

    testWidgets('shows compactOnly in NavigationBar at compact width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePreset.aurora.light(),
          home: AdaptiveShell(
            destinations: destinations,
            selectedIndex: 1,
            onDestinationSelected: (i) => tapped = i,
            body: const Text('Body'),
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Keypad'), findsOneWidget);

      await tester.tap(find.text('Contacts'));
      expect(tapped, 2);
    });

    testWidgets('omits compactOnly in NavigationRail and maps indices safely', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePreset.aurora.light(),
          home: AdaptiveShell(
            destinations: destinations,
            selectedIndex: 1, // points to compactOnly 'Keypad'
            onDestinationSelected: (i) => tapped = i,
            brandHeader: const Text('Brand'),
            statusFooter: const Text('Online'),
            body: const Text('Body'),
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Keypad'), findsNothing);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, isNull);
      expect(rail.destinations.length, 3);

      // Tapping 'Contacts' (rail index 1) should report original index 2.
      await tester.tap(find.text('Contacts'));
      expect(tapped, 2);
    });
  });

  group('MasterDetail', () {
    testWidgets('renders side-by-side at wide width and updates detail', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePreset.aurora.light(),
          home: Scaffold(
            body: MasterDetail<String>(
              emptyDetail: const Text('Select an item'),
              masterWidth: 280,
              masterBuilder: (context, onSelect) => ListView(
                children: [
                  ListTile(
                    title: const Text('Alpha'),
                    onTap: () => onSelect('Alpha'),
                  ),
                  ListTile(
                    title: const Text('Beta'),
                    onTap: () => onSelect('Beta'),
                  ),
                ],
              ),
              detailBuilder: (context, item) => Text('Detail: $item'),
            ),
          ),
        ),
      );

      expect(find.text('Select an item'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(find.text('Detail: Alpha'), findsOneWidget);
      expect(find.text('Select an item'), findsNothing);
    });

    testWidgets('pushes detail route on compact width', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePreset.aurora.light(),
          home: Scaffold(
            body: MasterDetail<String>(
              emptyDetail: const Text('Select an item'),
              masterBuilder: (context, onSelect) => ListView(
                children: [
                  ListTile(
                    title: const Text('Alpha'),
                    onTap: () => onSelect('Alpha'),
                  ),
                ],
              ),
              detailBuilder: (context, item) => Scaffold(
                appBar: AppBar(title: Text(item)),
                body: Text('Detail: $item'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select an item'), findsNothing);
      expect(find.byType(VerticalDivider), findsNothing);

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(find.text('Detail: Alpha'), findsOneWidget);
    });
  });

  group('SurfaceCard', () {
    testWidgets('wraps ListTile and InkWell in MaterialType.card safely', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePreset.aurora.light(),
          home: Scaffold(
            body: SurfaceCard(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              onTap: () => tapped = true,
              child: const ListTile(
                leading: Icon(Icons.phone),
                title: Text('Call Log'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final material = tester.widget<Material>(
        find
            .ancestor(
              of: find.byType(ListTile),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.type, MaterialType.card);
      expect(material.clipBehavior, Clip.antiAlias);

      await tester.tap(find.byType(SurfaceCard));
      expect(tapped, isTrue);
    });
  });

  group('ContextMenuRegion', () {
    testWidgets('opens menu on secondary tap and reports selection', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePreset.aurora.light(),
          home: Scaffold(
            body: Center(
              child: ContextMenuRegion<String>(
                items: const [
                  PopupMenuItem(value: 'copy', child: Text('Copy')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) => selected = v,
                child: const SizedBox(
                  width: 200,
                  height: 80,
                  child: Center(child: Text('Target')),
                ),
              ),
            ),
          ),
        ),
      );

      final center = tester.getCenter(find.text('Target'));
      final gesture = await tester.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(selected, 'copy');
    });

    testWidgets('opens menu on long press and respects enabled: false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePreset.aurora.light(),
          home: Scaffold(
            body: Column(
              children: [
                ContextMenuRegion<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                  ],
                  child: const SizedBox(
                    width: 200,
                    height: 60,
                    child: Center(child: Text('EnabledTarget')),
                  ),
                ),
                const ContextMenuRegion<String>(
                  enabled: false,
                  items: [
                    PopupMenuItem(value: 'hidden', child: Text('Hidden')),
                  ],
                  child: SizedBox(
                    width: 200,
                    height: 60,
                    child: Center(child: Text('DisabledTarget')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.longPress(find.text('DisabledTarget'));
      await tester.pumpAndSettle();
      expect(find.text('Hidden'), findsNothing);

      await tester.longPress(find.text('EnabledTarget'));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
    });
  });
}
