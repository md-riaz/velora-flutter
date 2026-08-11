import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui_gallery/main.dart';

/// Drags [listView] upward in small, bounded steps (pumping once after each
/// drag, never `pumpAndSettle`) until [finder] is built into the tree.
///
/// The gallery's body is a plain (eagerly-listed, but lazily-built)
/// `ListView`, and one section runs an indefinitely-repeating
/// [AnimationController] (`VeloraSkeleton`'s pulse) plus a real
/// `NetworkImage` — both of which make `pumpAndSettle` either hang or hit
/// the network, so every scroll/settle step in this file uses fixed,
/// finite `pump()` calls instead.
Future<void> _scrollUntilFound(
  WidgetTester tester,
  Finder finder,
  Finder listView,
) async {
  const maxAttempts = 20;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(listView, const Offset(0, -300));
    await tester.pump();
  }
}

void main() {
  testWidgets('renders the gallery app with its top-level structure', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    // A couple of fixed pumps let the first frame (and VeloraSkeleton's
    // pulse animation) settle without ever waiting for "no more frames" —
    // which would never arrive while the skeletons keep pulsing.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Velora UI Gallery'), findsOneWidget);
    // The "Buttons" section header is the first section and renders inside
    // the initial viewport without needing to scroll.
    expect(find.text('Buttons'), findsOneWidget);
  });

  testWidgets('brightness toggle flips the theme mode', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    final before = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(before.themeMode, ThemeMode.light);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pump();

    final after = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(after.themeMode, ThemeMode.dark);
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
  });

  testWidgets('preset toggle switches between aurora and meadow', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    expect(find.text('Velora Aurora · Light'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to Velora Meadow'));
    await tester.pump();

    expect(find.text('Velora Meadow · Light'), findsOneWidget);
  });

  testWidgets('a checkbox deep in the inputs section toggles via setState', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    final listView = find.byType(ListView);
    final checkboxFinder = find.byType(Checkbox);

    await _scrollUntilFound(tester, checkboxFinder, listView);
    expect(checkboxFinder, findsOneWidget);

    // Being present in the element tree only means it was *built* (the
    // ListView's default cache extent builds a little past the viewport
    // edge) — ensureVisible scrolls it fully into the visible viewport so
    // the subsequent tap's hit test actually lands on it.
    await tester.ensureVisible(checkboxFinder);
    await tester.pump();

    final before = tester.widget<Checkbox>(checkboxFinder).value;
    await tester.tap(checkboxFinder);
    await tester.pump();
    final after = tester.widget<Checkbox>(checkboxFinder).value;

    expect(after, isNot(equals(before)));
  });
}
