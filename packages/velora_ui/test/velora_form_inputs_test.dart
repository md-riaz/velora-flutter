import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

/// Pumps [child] under a Velora theme + Material scaffold.
Future<void> pumpUnderTheme(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: VeloraTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  group('VeloraTextField', () {
    testWidgets('shows label/hint and reports changes', (tester) async {
      String? latest;
      await pumpUnderTheme(
        tester,
        VeloraTextField(
          label: 'Email',
          hint: 'you@example.com',
          onChanged: (v) => latest = v,
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'hi@velora.dev');
      expect(latest, 'hi@velora.dev');
    });

    testWidgets('renders the error text', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraTextField(label: 'Email', errorText: 'Required'),
      );
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('obscure toggle flips visibility', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraTextField(label: 'Password', obscureText: true),
      );

      // Starts obscured -> shows the "reveal" icon.
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group('VeloraCheckbox', () {
    testWidgets('toggles when the row is tapped', (tester) async {
      bool? next;
      await pumpUnderTheme(
        tester,
        VeloraCheckbox(
          value: false,
          label: 'Accept terms',
          onChanged: (v) => next = v,
        ),
      );

      await tester.tap(find.text('Accept terms'));
      expect(next, isTrue);
    });

    testWidgets('is disabled when onChanged is null', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraCheckbox(
          value: false,
          label: 'Locked',
          onChanged: null,
        ),
      );
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, isNull);
    });
  });

  group('VeloraSwitch', () {
    testWidgets('toggles when the row is tapped', (tester) async {
      bool? next;
      await pumpUnderTheme(
        tester,
        VeloraSwitch(
          value: true,
          label: 'Notifications',
          onChanged: (v) => next = v,
        ),
      );

      await tester.tap(find.text('Notifications'));
      expect(next, isFalse);
    });

    testWidgets('is disabled when onChanged is null', (tester) async {
      await pumpUnderTheme(
        tester,
        const VeloraSwitch(value: true, label: 'Locked', onChanged: null),
      );
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.onChanged, isNull);
    });

    testWidgets('renders the error text', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraSwitch(
          value: false,
          label: 'Required toggle',
          errorText: 'You must enable this',
          onChanged: (_) {},
        ),
      );
      expect(find.text('You must enable this'), findsOneWidget);
    });
  });

  group('VeloraRadioGroup', () {
    testWidgets('selects an option and reflects the group value', (
      tester,
    ) async {
      String? chosen;
      await pumpUnderTheme(
        tester,
        VeloraRadioGroup<String>(
          label: 'Plan',
          groupValue: 'free',
          options: const [
            VeloraRadioOption(value: 'free', label: 'Free'),
            VeloraRadioOption(value: 'pro', label: 'Pro'),
          ],
          onChanged: (v) => chosen = v,
        ),
      );

      // The selected option shows the filled glyph; the other the empty one.
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

      await tester.tap(find.text('Pro'));
      expect(chosen, 'pro');
    });

    testWidgets('does not fire onChanged when disabled', (tester) async {
      var fired = false;
      await pumpUnderTheme(
        tester,
        VeloraRadioGroup<String>(
          groupValue: 'free',
          options: const [
            VeloraRadioOption(value: 'free', label: 'Free'),
            VeloraRadioOption(value: 'pro', label: 'Pro'),
          ],
          onChanged: null,
        ),
      );

      await tester.tap(find.text('Pro'));
      expect(fired, isFalse);
    });

    testWidgets('renders the error text', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraRadioGroup<String>(
          groupValue: null,
          errorText: 'Pick one',
          options: const [VeloraRadioOption(value: 'a', label: 'A')],
          onChanged: (_) {},
        ),
      );
      expect(find.text('Pick one'), findsOneWidget);
    });
  });

  group('VeloraSelect', () {
    testWidgets('shows label and opens options on tap', (tester) async {
      String? chosen;
      await pumpUnderTheme(
        tester,
        VeloraSelect<String>(
          label: 'Country',
          value: null,
          hint: 'Choose',
          options: const [
            VeloraSelectOption(value: 'bd', label: 'Bangladesh'),
            VeloraSelectOption(value: 'us', label: 'United States'),
          ],
          onChanged: (v) => chosen = v,
        ),
      );

      expect(find.text('Country'), findsOneWidget);

      await tester.tap(find.byType(VeloraSelect<String>));
      await tester.pumpAndSettle();
      // The menu is open — tap an item.
      await tester.tap(find.text('United States').last);
      await tester.pumpAndSettle();
      expect(chosen, 'us');
    });

    testWidgets('renders the error text', (tester) async {
      await pumpUnderTheme(
        tester,
        VeloraSelect<String>(
          label: 'Country',
          value: null,
          errorText: 'Required',
          options: const [VeloraSelectOption(value: 'bd', label: 'Bangladesh')],
          onChanged: (_) {},
        ),
      );
      expect(find.text('Required'), findsOneWidget);
    });
  });
}
