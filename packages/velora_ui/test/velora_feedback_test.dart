import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

/// Pumps a themed [Scaffold] and hands back a [BuildContext] under it, so a
/// test can drive the imperative `show`/`confirm`/toast helpers, which all
/// need a `Scaffold`/`Navigator` ancestor.
Future<BuildContext> pumpWithContext(WidgetTester tester) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(
    MaterialApp(
      theme: VeloraTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return capturedContext;
}

void main() {
  group('VeloraDialog.confirm', () {
    testWidgets('renders the title and default Confirm/Cancel labels', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);

      unawaited(VeloraDialog.confirm(context, title: 'Delete item?'));
      await tester.pumpAndSettle();

      expect(find.text('Delete item?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Confirm pops true', (tester) async {
      final context = await pumpWithContext(tester);
      bool? result;

      unawaited(
        VeloraDialog.confirm(
          context,
          title: 'Delete item?',
        ).then((value) => result = value),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('tapping Cancel pops false', (tester) async {
      final context = await pumpWithContext(tester);
      bool? result;

      unawaited(
        VeloraDialog.confirm(
          context,
          title: 'Delete item?',
        ).then((value) => result = value),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('respects custom labels and shows the error icon when '
        'destructive', (tester) async {
      final context = await pumpWithContext(tester);

      unawaited(
        VeloraDialog.confirm(
          context,
          title: 'Delete account?',
          confirmLabel: 'Delete',
          cancelLabel: 'Keep it',
          destructive: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Keep it'), findsOneWidget);
      expect(find.byIcon(VeloraStatus.error.icon), findsOneWidget);

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
    });
  });

  group('VeloraDialog.show', () {
    testWidgets('renders a custom content widget below the message', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);

      unawaited(
        VeloraDialog.show<void>(
          context,
          title: 'Rename',
          message: 'Choose a new name:',
          content: const TextField(key: Key('rename-field')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Choose a new name:'), findsOneWidget);
      expect(find.byKey(const Key('rename-field')), findsOneWidget);
    });
  });

  group('VeloraBottomSheet.show', () {
    testWidgets('renders the builder content, title, and a drag handle', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);

      unawaited(
        VeloraBottomSheet.show<void>(
          context,
          title: 'Options',
          builder: (_) => const Text('Sheet content'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Options'), findsOneWidget);
      expect(find.text('Sheet content'), findsOneWidget);
      // The title header is separated from the content by a Divider, and a
      // small rounded bar above it serves as the drag handle.
      expect(find.byType(Divider), findsOneWidget);
      expect(
        find.byKey(const Key('velora-bottom-sheet-drag-handle')),
        findsOneWidget,
      );
    });

    testWidgets('omits the drag handle when showDragHandle is false', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);

      unawaited(
        VeloraBottomSheet.show<void>(
          context,
          showDragHandle: false,
          builder: (_) => const Text('No handle here'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No handle here'), findsOneWidget);
      expect(
        find.byKey(const Key('velora-bottom-sheet-drag-handle')),
        findsNothing,
      );
    });

    testWidgets('pops the value passed to Navigator.pop from the builder', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);
      Object? result;

      unawaited(
        VeloraBottomSheet.show<String>(
          context,
          builder: (sheetContext) => TextButton(
            onPressed: () => Navigator.of(sheetContext).pop('done'),
            child: const Text('Close'),
          ),
        ).then((value) => result = value),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(result, 'done');
    });

    testWidgets('tapping the barrier dismisses an isDismissible sheet', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);
      var closed = false;

      unawaited(
        VeloraBottomSheet.show<void>(
          context,
          builder: (_) => const Text('Dismiss me'),
        ).then((_) => closed = true),
      );
      await tester.pumpAndSettle();
      expect(closed, isFalse);

      // Tap near the top of the screen, outside the sheet's bounds, to hit
      // the modal barrier.
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
    });

    testWidgets('hosts a scrollable ListView builder without overflow', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);

      unawaited(
        VeloraBottomSheet.show<void>(
          context,
          isScrollControlled: true,
          builder: (_) => ListView(
            shrinkWrap: false,
            children: [for (var i = 0; i < 40; i++) Text('Row $i')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The Flexible slot bounds the ListView's height to the sheet, so it
      // lays out (and its first rows build) instead of asserting on unbounded
      // height. No exception is the assertion here.
      expect(tester.takeException(), isNull);
      expect(find.text('Row 0'), findsOneWidget);
    });
  });

  group('VeloraToast.show', () {
    testWidgets('displays a SnackBar containing the message', (tester) async {
      final context = await pumpWithContext(tester);

      VeloraToast.show(context, message: 'Saved successfully');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Saved successfully'), findsOneWidget);
    });

    testWidgets('shows the status icon when a status is passed', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);

      VeloraToast.show(
        context,
        message: 'Upload failed',
        status: VeloraStatus.error,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Upload failed'), findsOneWidget);
      expect(find.byIcon(VeloraStatus.error.icon), findsOneWidget);
    });

    testWidgets('an explicit icon overrides the status default glyph', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);

      VeloraToast.show(
        context,
        message: 'Synced',
        status: VeloraStatus.success,
        icon: Icons.cloud_done_outlined,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The explicit icon wins; the status's default glyph is not shown.
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
      expect(find.byIcon(VeloraStatus.success.icon), findsNothing);
    });

    testWidgets('shows an action and fires onAction when tapped', (
      tester,
    ) async {
      final context = await pumpWithContext(tester);
      var tapped = false;

      VeloraToast.show(
        context,
        message: 'Item removed',
        actionLabel: 'Undo',
        onAction: () => tapped = true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Undo'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('VeloraTooltip', () {
    testWidgets('builds its child and a Tooltip carrying the message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VeloraTheme.light(),
          home: const Scaffold(
            body: Center(
              child: VeloraTooltip(
                message: 'Copy to clipboard',
                child: Icon(Icons.copy),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Copy to clipboard');
    });
  });
}
