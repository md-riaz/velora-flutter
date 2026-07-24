import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

/// Pumps [child] under a Velora theme + Material scaffold so the components
/// can resolve `context.veloraTokens` and the `ColorScheme`.
Future<void> pumpUnderTheme(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark
          ? VeloraTheme.dark()
          : VeloraTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('VeloraButton', () {
    testWidgets('renders its label and fires onPressed', (tester) async {
      var taps = 0;
      await pumpUnderTheme(
        tester,
        VeloraButton(label: 'Save', onPressed: () => taps++),
      );

      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.byType(VeloraButton));
      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraButton(label: 'Disabled', onPressed: null),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('shows a spinner and swallows taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await pumpUnderTheme(
        tester,
        VeloraButton(
          label: 'Save',
          loading: true,
          onPressed: () => taps++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      await tester.tap(find.byType(VeloraButton));
      expect(taps, 0);
    });

    testWidgets('renders a leading icon when provided', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraButton(label: 'Add', icon: Icons.add, onPressed: () {}),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('VeloraCard', () {
    testWidgets('renders its child', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraCard(child: Text('Card body')),
      );
      expect(find.text('Card body'), findsOneWidget);
    });

    testWidgets('is tappable when onTap is set', (tester) async {
      var taps = 0;
      await pumpUnderTheme(
        tester,
        VeloraCard(onTap: () => taps++, child: const Text('Tap me')),
      );

      await tester.tap(find.text('Tap me'));
      expect(taps, 1);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders no InkWell when not tappable', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraCard(child: Text('Static')),
      );
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('VeloraBadge', () {
    testWidgets('renders its label', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraBadge(label: 'New', status: VeloraStatus.success),
      );
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('renders a leading icon when provided', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraBadge(label: '3', icon: Icons.star),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('VeloraChip', () {
    testWidgets('toggles via onTap', (tester) async {
      var taps = 0;
      await pumpUnderTheme(
        tester,
        VeloraChip(label: 'Filter', onTap: () => taps++),
      );

      await tester.tap(find.text('Filter'));
      expect(taps, 1);
    });

    testWidgets('shows a delete affordance that fires onDeleted', (
      tester,
    ) async {
      var deleted = 0;
      await pumpUnderTheme(
        tester,
        VeloraChip(label: 'Tag', onDeleted: () => deleted++),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(deleted, 1);
    });

    testWidgets('shows no delete icon when onDeleted is null', (tester) async {
      await pumpUnderTheme(tester, const VeloraChip(label: 'Plain'));
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('VeloraAlert', () {
    testWidgets('renders title, message, and default status icon', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        const VeloraAlert(
          title: 'Saved',
          message: 'Your changes were saved.',
          status: VeloraStatus.success,
        ),
      );

      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Your changes were saved.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('shows a close button that fires onClose', (tester) async {
      var closed = 0;
      await pumpUnderTheme(
        tester,
        VeloraAlert(message: 'Heads up', onClose: () => closed++),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, 1);
    });
  });

  group('VeloraEmptyState', () {
    testWidgets('renders icon, title, message, and action', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraEmptyState(
          icon: Icons.inbox,
          title: 'No messages',
          message: 'Start a conversation.',
          action: VeloraButton(label: 'New chat', onPressed: () {}),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No messages'), findsOneWidget);
      expect(find.text('Start a conversation.'), findsOneWidget);
      expect(find.text('New chat'), findsOneWidget);
    });
  });

  group('VeloraSkeleton', () {
    testWidgets('animates by default (has a running ticker)', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraSkeleton(width: 100, height: 20),
      );
      // A repeating animation means the test scheduler still has a frame
      // pending after the first pump.
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('renders statically under reduced motion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VeloraTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Center(child: VeloraSkeleton(width: 100, height: 20)),
            ),
          ),
        ),
      );

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(VeloraSkeleton), findsOneWidget);
    });

    testWidgets('circle constructor builds a square box', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraSkeleton.circle(diameter: 40),
      );
      expect(find.byType(VeloraSkeleton), findsOneWidget);
    });

    testWidgets(
      'survives a reduced-motion false -> true -> false toggle without '
      'a second ticker',
      (tester) async {
        Widget frame(bool reduce) => MaterialApp(
          theme: VeloraTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: const Scaffold(
              body: Center(child: VeloraSkeleton(width: 100, height: 20)),
            ),
          ),
        );

        // Animating -> stopped -> animating again. The same State (and its
        // single ticker) is reused across pumps, so recreating a controller
        // here would trip SingleTickerProviderStateMixin's assertion.
        await tester.pumpWidget(frame(false));
        expect(tester.hasRunningAnimations, isTrue);

        await tester.pumpWidget(frame(true));
        expect(tester.hasRunningAnimations, isFalse);

        await tester.pumpWidget(frame(false));
        expect(tester.hasRunningAnimations, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
