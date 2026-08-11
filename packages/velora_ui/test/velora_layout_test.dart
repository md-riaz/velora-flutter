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

/// A minimal [ImageProvider] that always fails to load, synchronously —
/// used to exercise [VeloraAvatar]'s error fallback without depending on
/// real (and potentially async/flaky) image decoding.
class _BrokenImageProvider extends ImageProvider<_BrokenImageProvider> {
  const _BrokenImageProvider();

  @override
  Future<_BrokenImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future<_BrokenImageProvider>.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _BrokenImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(Exception('broken image')),
    );
  }
}

void main() {
  group('VeloraAvatar', () {
    testWidgets('renders initials derived from a name', (tester) async {
      await pumpUnderTheme(tester, const VeloraAvatar(name: 'Ada Lovelace'));
      expect(find.text('AL'), findsOneWidget);
    });

    testWidgets('renders a single-letter initial for a one-word name', (
      tester,
    ) async {
      await pumpUnderTheme(tester, const VeloraAvatar(name: 'Ada'));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('falls back to a person icon when name and image are null', (
      tester,
    ) async {
      await pumpUnderTheme(tester, const VeloraAvatar());
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('falls back to initials when the image fails to load', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        const VeloraAvatar(name: 'Grace Hopper', image: _BrokenImageProvider()),
      );
      // Let the failed image-load future settle so the errorBuilder
      // fallback rebuild happens.
      await tester.pump();
      expect(find.text('GH'), findsOneWidget);
    });
  });

  group('VeloraListTile', () {
    testWidgets('renders title, subtitle, leading, and trailing', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        const VeloraListTile(
          leading: Icon(Icons.folder),
          title: 'Project plan',
          subtitle: 'Updated 2 hours ago',
          trailing: Icon(Icons.chevron_right),
        ),
      );

      expect(find.text('Project plan'), findsOneWidget);
      expect(find.text('Updated 2 hours ago'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var taps = 0;
      await pumpUnderTheme(
        tester,
        VeloraListTile(title: 'Tap me', onTap: () => taps++),
      );

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.text('Tap me'));
      expect(taps, 1);
    });

    testWidgets('renders no InkWell when onTap is null', (tester) async {
      await pumpUnderTheme(tester, const VeloraListTile(title: 'Static row'));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('VeloraSectionHeader', () {
    testWidgets('renders title, subtitle, and action', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraSectionHeader(
          title: 'Recent activity',
          subtitle: 'Last 7 days',
          action: TextButton(onPressed: () {}, child: const Text('See all')),
        ),
      );

      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('Last 7 days'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('renders without subtitle or action', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraSectionHeader(title: 'Plain header'),
      );
      expect(find.text('Plain header'), findsOneWidget);
    });
  });

  group('VeloraDivider', () {
    testWidgets('renders a horizontal Divider by default', (tester) async {
      await pumpUnderTheme(tester, const VeloraDivider());
      expect(find.byType(Divider), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('renders a VerticalDivider when vertical is true', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        const SizedBox(height: 40, child: VeloraDivider(vertical: true)),
      );
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });
  });

  group('VeloraProgress', () {
    testWidgets('linear renders determinate with the given value', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        const SizedBox(width: 200, child: VeloraProgress.linear(value: 0.4)),
      );
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.4);
    });

    testWidgets('linear renders indeterminate when value is null', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        const SizedBox(width: 200, child: VeloraProgress.linear()),
      );
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, isNull);
    });

    testWidgets('circular renders determinate with the given value', (
      tester,
    ) async {
      await pumpUnderTheme(
        tester,
        const VeloraProgress.circular(value: 0.75, size: 48),
      );
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.75);

      final box = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(CircularProgressIndicator),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, 48);
      expect(box.height, 48);
    });

    testWidgets('circular renders indeterminate when value is null', (
      tester,
    ) async {
      await pumpUnderTheme(tester, const VeloraProgress.circular());
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, isNull);
    });
  });
}
