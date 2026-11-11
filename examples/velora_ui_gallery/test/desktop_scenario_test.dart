import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';
import 'package:velora_ui_gallery/desktop_scenario.dart';

void _setWindow(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpScenario(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: VeloraTheme.light(), home: const DesktopScenarioPage()),
  );
  await tester.pump();
}

/// Presses Tab until the focused widget's bounds contain the centre of
/// [target]. Keyboard only: nothing is tapped.
Future<void> _tabTo(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 60; i++) {
    final focus = FocusManager.instance.primaryFocus;
    // The route's own scope spans the window; only a real control counts.
    if (focus != null &&
        focus is! FocusScopeNode &&
        focus.context != null &&
        target.evaluate().isNotEmpty &&
        focus.rect.contains(tester.getCenter(target.first))) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Tab never reached $target');
}

void main() {
  testWidgets('table → detail → wizard is operable without a pointer', (
    tester,
  ) async {
    _setWindow(tester, 1280);
    await _pumpScenario(tester);

    // Open a record from the table with the keyboard.
    await _tabTo(tester, find.text('Ada Lovelace'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Role: Member'), findsOneWidget);
    expect(find.text('Open record: Alan Turing'), findsOneWidget);

    // From the detail pane, start the wizard.
    await _tabTo(tester, find.text('Edit in wizard'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Wizard step: 1 of 3'), findsOneWidget);
    expect(find.widgetWithText(VeloraTextField, 'Alan Turing'), findsOneWidget);

    // Walk the wizard to the end and save.
    await _tabTo(tester, find.text('Continue'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await _tabTo(tester, find.text('Continue'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Wizard step: 3 of 3'), findsOneWidget);

    await _tabTo(tester, find.text('Save'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    // A second Enter while saving must not submit again.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Saved Alan Turing'), findsOneWidget);
    expect(find.text('Wizard step: 1 of 3'), findsOneWidget);

    // Let the toast finish so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('caller-owned state survives every breakpoint', (tester) async {
    _setWindow(tester, 1280);
    await _pumpScenario(tester);

    await tester.tap(find.bySemanticsLabel('Select Grace Hopper'));
    await tester.tap(find.text('Linus Torvalds'));
    await tester.pumpAndSettle();
    expect(find.text('Selected rows: 1'), findsOneWidget);
    expect(find.text('Seats: 3'), findsOneWidget);

    // Medium: rail, no secondary pane. The record stays open.
    _setWindow(tester, 900);
    await tester.pumpAndSettle();
    expect(find.byType(VeloraNavRail), findsOneWidget);
    expect(find.text('Selected rows: 1'), findsNothing);
    expect(find.text('Seats: 3'), findsOneWidget);

    // Compact: bottom bar, detail covers the list.
    _setWindow(tester, 400);
    await tester.pumpAndSettle();
    expect(find.byType(VeloraNavBar), findsOneWidget);
    expect(find.text('Seats: 3'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsNothing);
    expect(tester.takeException(), isNull);

    // Back to expanded: selection and the open record are intact.
    _setWindow(tester, 1280);
    await tester.pumpAndSettle();
    expect(find.text('Selected rows: 1'), findsOneWidget);
    expect(find.text('Open record: Linus Torvalds'), findsOneWidget);

    // Escape closes the detail.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Open record: none'), findsOneWidget);
  });

  testWidgets('status and external selection come from caller state', (
    tester,
  ) async {
    _setWindow(tester, 1280);
    await _pumpScenario(tester);
    expect(find.byType(VeloraStatusStrip), findsNothing);

    await tester.tap(find.byTooltip('Cycle connection status'));
    await tester.pump();
    expect(find.textContaining('Offline'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.textContaining('Synchronizing'), findsOneWidget);

    await tester.tap(find.byTooltip('Cycle connection status'));
    await tester.pump();
    expect(find.byType(VeloraStatusStrip), findsNothing);

    // Something outside the shell picks a destination.
    final handle = tester.ensureSemantics();
    await tester.tap(find.byTooltip('Simulate an external link to Settings'));
    await tester.pumpAndSettle();
    final rail = find.byType(VeloraNavRail);
    expect(
      tester.getSemantics(
        find.descendant(of: rail, matching: find.text('Settings')),
      ),
      isSemantics(isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('fits a 400px window at 200% text', (tester) async {
    _setWindow(tester, 400);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 900),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: VeloraTheme.light(),
          useInheritedMediaQuery: true,
          home: const DesktopScenarioPage(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
