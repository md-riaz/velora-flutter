import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';
import 'package:velora_ui_gallery/main.dart';

void main() {
  testWidgets('preset, brightness and density update the theme', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.tap(find.byKey(const ValueKey('preset')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('corporate').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('brightness')));
    await tester.tap(find.byKey(const ValueKey('density')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('corporate / dark / compact'), findsOneWidget);
    final context = tester.element(find.text('corporate / dark / compact'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).visualDensity, VisualDensity.compact);
    expect(DesignTokens.of(context).radiusMd, 6);
    expect(StatusColors.of(context).success.color, isNotNull);
  });

  testWidgets('data destination sorts and selects rows', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GalleryApp());
    await tester.tap(find.text('Data'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.bySemanticsLabel('Select Ada'));
    await tester.pump();
    expect(find.text('Selected: 1'), findsOneWidget);
    await tester.tap(find.text('Name'));
    await tester.pump();
    final table = tester.widget<ResponsiveDataTable<String>>(
      find.byType(ResponsiveDataTable<String>),
    );
    expect(table.rows.first, 'Grace');
  });
}
