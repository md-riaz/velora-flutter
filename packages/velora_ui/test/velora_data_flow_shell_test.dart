import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora_ui/velora_ui.dart';

class _User {
  const _User(this.name, this.email, this.age);
  final String name;
  final String email;
  final int age;
}

const _users = [
  _User('Ada', 'ada@example.com', 36),
  _User('Grace', 'grace@example.com', 45),
  _User('Linus', 'linus@example.com', 28),
];

final _columns = <VeloraDataColumn<_User>>[
  VeloraDataColumn(
    id: 'name',
    label: 'Name',
    cell: (u) => Text(u.name),
    sortable: true,
  ),
  VeloraDataColumn(id: 'email', label: 'Email', cell: (u) => Text(u.email)),
  VeloraDataColumn(
    id: 'age',
    label: 'Age',
    cell: (u) => Text('${u.age}'),
    numeric: true,
    sortable: true,
  ),
];

void _setWindow(WidgetTester tester, double width, [double height = 800]) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child, {ThemeData? theme, bool scroll = true}) {
  return MaterialApp(
    theme: theme ?? VeloraTheme.light(),
    home: Scaffold(body: scroll ? SingleChildScrollView(child: child) : child),
  );
}

/// A widget with private state, to prove a subtree survives a re-layout.
class _Counter extends StatefulWidget {
  const _Counter({required this.label});
  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => count++),
      child: Text('${widget.label}: $count'),
    );
  }
}

void main() {
  group('VeloraDataTable', () {
    testWidgets('renders headers and cells in the wide layout', (tester) async {
      _setWindow(tester, 1000);
      await tester.pumpWidget(
        _app(VeloraDataTable<_User>(rows: _users, columns: _columns)),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('linus@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports the requested sort and toggles direction', (
      tester,
    ) async {
      _setWindow(tester, 1000);
      VeloraSortState? sort;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _app(
            VeloraDataTable<_User>(
              rows: _users,
              columns: _columns,
              sort: sort,
              onSortChanged: (s) => setState(() => sort = s),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Name'));
      await tester.pump();
      expect(sort, const VeloraSortState('name'));
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      await tester.tap(find.text('Name'));
      await tester.pump();
      expect(sort, const VeloraSortState('name', ascending: false));
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      // The table itself never reorders rows.
      expect(
        tester.getTopLeft(find.text('Ada')).dy,
        lessThan(tester.getTopLeft(find.text('Linus')).dy),
      );
    });

    testWidgets('multi-select toggles rows and select-all', (tester) async {
      _setWindow(tester, 1000);
      var selected = <_User>{};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _app(
            VeloraDataTable<_User>(
              rows: _users,
              columns: _columns,
              selected: selected,
              rowLabel: (u) => u.name,
              onSelectionChanged: (s) => setState(() => selected = s),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Select Grace'));
      await tester.pump();
      expect(selected, {_users[1]});

      await tester.tap(find.bySemanticsLabel('Select all rows'));
      await tester.pump();
      expect(selected, _users.toSet());

      await tester.tap(find.bySemanticsLabel('Select all rows'));
      await tester.pump();
      expect(selected, isEmpty);
    });

    testWidgets('single-select replaces the selection', (tester) async {
      _setWindow(tester, 1000);
      var selected = <_User>{};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _app(
            VeloraDataTable<_User>(
              rows: _users,
              columns: _columns,
              selected: selected,
              multiSelect: false,
              rowLabel: (u) => u.name,
              onSelectionChanged: (s) => setState(() => selected = s),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Select all rows'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Select Ada'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Select Linus'));
      await tester.pump();
      expect(selected, {_users[2]});
    });

    testWidgets('keeps selected rows that are not on the current page', (
      tester,
    ) async {
      _setWindow(tester, 1000);
      const offPage = _User('Zed', 'zed@example.com', 50);
      var selected = <_User>{offPage};
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _app(
            VeloraDataTable<_User>(
              rows: _users,
              columns: _columns,
              selected: selected,
              onSelectionChanged: (s) => setState(() => selected = s),
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Select all rows'));
      await tester.pump();
      expect(selected, {offPage, ..._users});
      await tester.tap(find.bySemanticsLabel('Select all rows'));
      await tester.pump();
      expect(selected, {offPage});
    });

    testWidgets('is operable with the keyboard alone', (tester) async {
      _setWindow(tester, 1000);
      var selected = <_User>{};
      _User? opened;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _app(
            VeloraDataTable<_User>(
              rows: _users,
              columns: _columns,
              selected: selected,
              onSelectionChanged: (s) => setState(() => selected = s),
              onSortChanged: (_) {},
              onRowTap: (u) => opened = u,
            ),
          ),
        ),
      );

      // Tab: select-all, Name header, Age header, then the first row.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, {_users[0]});

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, _users[2]);

      // Arrow keys stop at the ends instead of leaving the table.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, {_users[0], _users[2]});

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, _users[1]);
    });

    testWidgets('stacks rows as labelled cards on compact widths', (
      tester,
    ) async {
      _setWindow(tester, 360);
      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: _users,
            columns: _columns,
            sort: const VeloraSortState('name'),
            onSortChanged: (_) {},
          ),
        ),
      );

      // Every row repeats every column label, and nothing overflows.
      expect(find.text('Email'), findsNWidgets(_users.length));
      expect(find.text('grace@example.com'), findsOneWidget);
      expect(find.byTooltip('Sort'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolls horizontally instead of squeezing columns', (
      tester,
    ) async {
      _setWindow(tester, 700);
      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: _users,
            columns: _columns,
            minColumnWidth: 400,
          ),
        ),
      );

      final scrollable = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(scrollable, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives 200% text scaling in both layouts', (tester) async {
      for (final width in [360.0, 1000.0]) {
        _setWindow(tester, width);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: _app(
              VeloraDataTable<_User>(
                rows: _users,
                columns: _columns,
                selected: {_users[0]},
                onSelectionChanged: (_) {},
                onSortChanged: (_) {},
                rowActions: (_) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
                footer: VeloraPagination(
                  page: 1,
                  pageCount: 3,
                  onPageChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });

    testWidgets('shows skeletons when loading with no rows', (tester) async {
      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: const [],
            columns: _columns,
            loading: true,
            empty: const Text('Nothing here'),
          ),
        ),
      );
      expect(find.byType(VeloraSkeleton), findsNWidgets(3));
      expect(find.text('Nothing here'), findsNothing);
    });

    testWidgets('keeps rows visible while refreshing', (tester) async {
      _setWindow(tester, 1000);
      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: _users,
            columns: _columns,
            loading: true,
          ),
        ),
      );
      expect(find.text('Ada'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty and error slots', (tester) async {
      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: const [],
            columns: _columns,
            empty: const Text('Nothing here'),
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: _users,
            columns: _columns,
            error: const Text('Could not load'),
          ),
        ),
      );
      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('Ada'), findsNothing);
    });

    testWidgets('exposes sort state and selection to screen readers', (
      tester,
    ) async {
      _setWindow(tester, 1000);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: _users,
            columns: _columns,
            sort: const VeloraSortState('age', ascending: false),
            onSortChanged: (_) {},
            selected: {_users[0]},
            onSelectionChanged: (_) {},
            rowLabel: (u) => u.name,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Age, sorted descending'), findsOneWidget);
      expect(find.bySemanticsLabel('Name, not sorted'), findsOneWidget);
      expect(find.bySemanticsLabel('Select Ada'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('renders under the dark theme', (tester) async {
      _setWindow(tester, 1000);
      await tester.pumpWidget(
        _app(
          VeloraDataTable<_User>(
            rows: _users,
            columns: _columns,
            selected: {_users[1]},
            onSelectionChanged: (_) {},
          ),
          theme: VeloraTheme.dark(),
        ),
      );
      expect(find.text('Grace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('VeloraPagination', () {
    testWidgets('reports the requested page and disables at the ends', (
      tester,
    ) async {
      int? requested;
      await tester.pumpWidget(
        _app(
          VeloraPagination(
            page: 1,
            pageCount: 2,
            onPageChanged: (p) => requested = p,
          ),
        ),
      );
      expect(find.text('Page 1 of 2'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous page'));
      expect(requested, isNull);
      await tester.tap(find.byTooltip('Next page'));
      expect(requested, 2);
    });
  });

  group('VeloraStepper', () {
    const steps = [
      VeloraStep(title: 'Account'),
      VeloraStep(title: 'Address', description: 'Where to ship'),
      VeloraStep(title: 'Extras', optional: true),
      VeloraStep(title: 'Locked', state: VeloraStepState.disabled),
    ];

    testWidgets('derives state from currentStep unless overridden', (
      tester,
    ) async {
      final stepper = VeloraStepper(steps: steps, currentStep: 1);
      expect(stepper.stateOf(0), VeloraStepState.completed);
      expect(stepper.stateOf(1), VeloraStepState.current);
      expect(stepper.stateOf(2), VeloraStepState.upcoming);
      expect(stepper.stateOf(3), VeloraStepState.disabled);

      _setWindow(tester, 1000);
      await tester.pumpWidget(_app(stepper));
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Where to ship'), findsOneWidget);
    });

    testWidgets('announces position, title, and state', (tester) async {
      _setWindow(tester, 1000);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(VeloraStepper(steps: steps, currentStep: 1)),
      );
      expect(
        find.bySemanticsLabel('Step 2 of 4, Address, current'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Step 3 of 4, Extras, optional, upcoming'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('reports taps, except on disabled steps', (tester) async {
      _setWindow(tester, 1000);
      final tapped = <int>[];
      await tester.pumpWidget(
        _app(
          VeloraStepper(steps: steps, currentStep: 1, onStepTapped: tapped.add),
        ),
      );
      await tester.tap(find.text('Account'));
      await tester.tap(find.text('Locked'));
      expect(tapped, [0]);
    });

    testWidgets('collapses to one line when there is no room', (tester) async {
      _setWindow(tester, 300);
      await tester.pumpWidget(
        _app(VeloraStepper(steps: steps, currentStep: 1)),
      );
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Account'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vertical layout fits a small phone at 200% text', (
      tester,
    ) async {
      _setWindow(tester, 320);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _app(
            VeloraStepper(
              steps: steps,
              currentStep: 2,
              direction: Axis.vertical,
            ),
          ),
        ),
      );
      expect(find.text('Account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not animate when motion is reduced', (tester) async {
      _setWindow(tester, 1000);
      Widget build(int current) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(VeloraStepper(steps: steps, currentStep: current)),
      );
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('VeloraWizard', () {
    const steps = [
      VeloraStep(title: 'Name'),
      VeloraStep(title: 'Plan'),
      VeloraStep(title: 'Confirm'),
    ];

    Widget wizard({
      required int step,
      required void Function(int) go,
      FutureOr<void> Function()? onSubmit,
      bool busy = false,
      bool canContinue = true,
      String? errorText,
    }) {
      return _app(
        VeloraWizard(
          steps: steps,
          currentStep: step,
          busy: busy,
          canContinue: canContinue,
          errorText: errorText,
          onNext: () => go(step + 1),
          onBack: () => go(step - 1),
          onSubmit: onSubmit ?? () {},
          stepBuilder: (context, index) => index == 0
              ? const TextField(key: Key('name'))
              : Text('Content $index'),
        ),
      );
    }

    testWidgets('keeps entered state when navigating back', (tester) async {
      _setWindow(tester, 1000);
      var step = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              wizard(step: step, go: (s) => setState(() => step = s)),
        ),
      );

      expect(find.text('Back'), findsNothing);
      await tester.enterText(find.byKey(const Key('name')), 'Ada');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(step, 1);
      expect(find.text('Content 1'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(step, 0);
      expect(find.text('Ada'), findsOneWidget);
    });

    testWidgets('does not build steps that were never visited', (tester) async {
      _setWindow(tester, 1000);
      await tester.pumpWidget(wizard(step: 0, go: (_) {}));
      expect(find.text('Content 2', skipOffstage: false), findsNothing);
    });

    testWidgets('prevents double submission while a Future is pending', (
      tester,
    ) async {
      _setWindow(tester, 1000);
      final completer = Completer<void>();
      var submissions = 0;
      await tester.pumpWidget(
        wizard(
          step: 2,
          go: (_) {},
          onSubmit: () {
            submissions++;
            return completer.future;
          },
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(submissions, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // The button is disabled and Back is too.
      await tester.tap(find.byType(VeloraButton).last, warnIfMissed: false);
      await tester.tap(find.text('Back'), warnIfMissed: false);
      await tester.pump();
      expect(submissions, 1);

      completer.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(submissions, 2);
    });

    testWidgets('busy, canContinue, and errorText are caller-controlled', (
      tester,
    ) async {
      _setWindow(tester, 1000);
      var step = 1;
      await tester.pumpWidget(
        wizard(step: step, go: (s) => step = s, canContinue: false),
      );
      await tester.tap(find.text('Continue'));
      expect(step, 1);

      await tester.pumpWidget(
        wizard(step: step, go: (s) => step = s, busy: true),
      );
      await tester.tap(find.text('Back'), warnIfMissed: false);
      expect(step, 1);

      await tester.pumpWidget(
        wizard(step: 2, go: (_) {}, errorText: 'Card declined'),
      );
      expect(find.text('Card declined'), findsOneWidget);
    });

    testWidgets('moves focus into the new step', (tester) async {
      _setWindow(tester, 1000);
      var step = 1;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              wizard(step: step, go: (s) => setState(() => step = s)),
        ),
      );

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      // Focus is on the step region; one Tab reaches its first field.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final field = tester.widget<EditableText>(find.byType(EditableText));
      expect(field.focusNode.hasFocus, isTrue);
    });

    testWidgets('keeps the current step across a resize', (tester) async {
      _setWindow(tester, 1000);
      var step = 0;
      Widget build() => StatefulBuilder(
        builder: (context, setState) =>
            wizard(step: step, go: (s) => setState(() => step = s)),
      );
      await tester.pumpWidget(build());
      await tester.enterText(find.byKey(const Key('name')), 'Grace');

      _setWindow(tester, 260);
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Grace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('VeloraAdaptiveShell', () {
    const destinations = [
      VeloraNavDestination(icon: Icons.inbox, label: 'Inbox'),
      VeloraNavDestination(icon: Icons.people, label: 'People'),
      VeloraNavDestination(icon: Icons.settings, label: 'Settings'),
    ];

    Widget shell({
      int selected = 0,
      ValueChanged<int>? onSelected,
      Widget? status,
      Widget? pane,
    }) {
      return MaterialApp(
        theme: VeloraTheme.light(),
        home: VeloraAdaptiveShell(
          destinations: destinations,
          selectedIndex: selected,
          onDestinationSelected: onSelected ?? (_) {},
          status: status,
          secondaryPane: pane,
          body: const _Counter(label: 'body'),
        ),
      );
    }

    test('classifies widths', () {
      expect(
        VeloraShellBreakpoint.forWidth(599),
        VeloraShellBreakpoint.compact,
      );
      expect(VeloraShellBreakpoint.forWidth(600), VeloraShellBreakpoint.medium);
      expect(
        VeloraShellBreakpoint.forWidth(1024),
        VeloraShellBreakpoint.expanded,
      );
    });

    testWidgets('adapts navigation and the secondary pane to width', (
      tester,
    ) async {
      _setWindow(tester, 400);
      await tester.pumpWidget(shell(pane: const Text('Pane')));
      expect(find.byType(VeloraNavBar), findsOneWidget);
      expect(find.byType(VeloraNavRail), findsNothing);
      expect(find.text('Pane'), findsNothing);

      _setWindow(tester, 800);
      await tester.pumpAndSettle();
      expect(find.byType(VeloraNavBar), findsNothing);
      expect(find.byType(VeloraNavRail), findsOneWidget);
      expect(find.text('Pane'), findsNothing);

      _setWindow(tester, 1280);
      await tester.pumpAndSettle();
      expect(find.byType(VeloraNavRail), findsOneWidget);
      expect(find.text('Pane'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps body state and selection across breakpoints', (
      tester,
    ) async {
      _setWindow(tester, 400);
      var selected = 1;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => shell(
            selected: selected,
            onSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      await tester.tap(find.text('body: 0'));
      await tester.pump();
      expect(find.text('body: 1'), findsOneWidget);

      for (final width in [800.0, 1280.0, 400.0]) {
        _setWindow(tester, width);
        await tester.pumpAndSettle();
        expect(find.text('body: 1'), findsOneWidget, reason: 'width $width');
        expect(selected, 1);
      }
    });

    testWidgets('selection is driven by caller-owned state', (tester) async {
      _setWindow(tester, 800);
      final handle = tester.ensureSemantics();
      var selected = 0;
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return shell(selected: selected, onSelected: (_) {});
          },
        ),
      );

      // Tapping reports but does not select: the caller decides.
      await tester.tap(find.text('People'));
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Inbox')),
        isSemantics(isSelected: true),
      );

      // An external activation (deep link, notification) only has to change
      // the caller's index.
      update(() => selected = 2);
      await tester.pump();
      expect(
        tester.getSemantics(find.text('Settings')),
        isSemantics(isSelected: true),
      );
      handle.dispose();
    });

    testWidgets('shows a caller-supplied status strip', (tester) async {
      _setWindow(tester, 800);
      await tester.pumpWidget(
        shell(
          status: const VeloraStatusStrip(
            message: 'Offline',
            icon: Icons.cloud_off,
          ),
        ),
      );
      expect(find.text('Offline'), findsOneWidget);

      await tester.pumpWidget(
        shell(status: const VeloraStatusStrip(message: 'Syncing', busy: true)),
      );
      expect(find.text('Syncing'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(shell());
      expect(find.byType(VeloraStatusStrip), findsNothing);
      // The body kept its place in the tree while the strip came and went.
      expect(find.text('body: 0'), findsOneWidget);
    });

    testWidgets('destinations come before the body in Tab order', (
      tester,
    ) async {
      _setWindow(tester, 800);
      var selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => shell(
            selected: selected,
            onSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 1);
    });
  });

  group('VeloraMasterDetailShell', () {
    Widget shell({required int? open, required ValueChanged<int?> onOpen}) {
      return MaterialApp(
        theme: VeloraTheme.light(),
        home: Scaffold(
          body: VeloraMasterDetailShell(
            master: Column(
              children: [
                const _Counter(label: 'list'),
                for (var i = 0; i < 2; i++)
                  TextButton(
                    onPressed: () => onOpen(i),
                    child: Text('Item $i'),
                  ),
              ],
            ),
            detail: open == null
                ? null
                : TextButton(onPressed: () {}, child: Text('Detail $open')),
            placeholder: const Text('Select an item'),
            onCloseDetail: () => onOpen(null),
          ),
        ),
      );
    }

    testWidgets('shows both sides when wide', (tester) async {
      _setWindow(tester, 1200);
      await tester.pumpWidget(shell(open: null, onOpen: (_) {}));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Select an item'), findsOneWidget);

      await tester.pumpWidget(shell(open: 1, onOpen: (_) {}));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Detail 1'), findsOneWidget);
    });

    testWidgets('covers the list with the detail when narrow', (tester) async {
      _setWindow(tester, 400);
      await tester.pumpWidget(shell(open: null, onOpen: (_) {}));
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Select an item'), findsNothing);

      await tester.pumpWidget(shell(open: 0, onOpen: (_) {}));
      expect(find.text('Detail 0'), findsOneWidget);
      expect(find.text('Item 0'), findsNothing);
      // Still mounted, just offstage.
      expect(find.text('Item 0', skipOffstage: false), findsOneWidget);
    });

    testWidgets('keeps list state across open, close, and resize', (
      tester,
    ) async {
      _setWindow(tester, 400);
      int? open;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              shell(open: open, onOpen: (i) => setState(() => open = i)),
        ),
      );
      await tester.tap(find.text('list: 0'));
      await tester.pump();

      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();
      expect(find.text('Detail 1'), findsOneWidget);

      _setWindow(tester, 1200);
      await tester.pumpAndSettle();
      expect(find.text('list: 1'), findsOneWidget);
      expect(find.text('Detail 1'), findsOneWidget);
      expect(open, 1);
    });

    testWidgets('Escape closes the detail and focus returns to the row', (
      tester,
    ) async {
      _setWindow(tester, 400);
      int? open;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) =>
              shell(open: open, onOpen: (i) => setState(() => open = i)),
        ),
      );

      // Tab to "Item 1" (counter, Item 0, Item 1) and open it by keyboard.
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(open, 1);

      // Focus moved into the detail; Enter there must not re-open anything.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(open, isNull);

      // Focus is back on the row that opened the detail.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(open, 1);
    });
  });
}
