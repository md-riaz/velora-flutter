# velora_ui

**What you'll do:** Install `velora_ui`, plug `VeloraTheme.light()`/`.dark()` into your `MaterialApp`, and read Velora's design tokens anywhere via `context.veloraTokens`.

---

## What it does

`velora_ui` is Velora's own, original design system — **token-first theming**, expressed the Flutter way. It's informed by (not copied from) the architecture surveyed in the internal `velora-ui-design-reference` planning note, but the palette, token taxonomy, and API are entirely Velora's: no external branding, no borrowed theme names.

The package ships seven layers, all exported from `package:velora_ui/velora_ui.dart`:

<!-- generated:ui-layers source=packages/velora_ui/components.json — do not edit; run tool/check_docs.sh --write -->
| Layer | Focus | Exports |
|---|---|---|
| 1 | Tokens & theme | `VeloraTokens`, `VeloraThemePreset`, `buildVeloraTheme`, `VeloraTheme`, `veloraTextTheme`, `VeloraTokensContext` |
| 2 | Core components | `VeloraButton`, `VeloraButtonVariant`, `VeloraButtonSize`, `VeloraCard`, `VeloraBadge`, `VeloraBadgeStyle`, `VeloraChip`, `VeloraAlert`, `VeloraEmptyState`, `VeloraSkeleton`, `VeloraStatus`, `VeloraStatusColors`, `VeloraStatusResolver` |
| 3 | Form inputs | `VeloraTextField`, `VeloraSelect`, `VeloraSelectOption`, `VeloraCheckbox`, `VeloraSwitch`, `VeloraRadioGroup`, `VeloraRadioOption` |
| 4 | Layout & content display | `VeloraAvatar`, `VeloraListTile`, `VeloraSectionHeader`, `VeloraDivider`, `VeloraProgress` |
| 5 | Navigation & scaffolding | `VeloraNavDestination`, `VeloraNavBar`, `VeloraNavRail`, `VeloraTabs`, `VeloraScaffold` |
| 6 | Feedback & overlays | `VeloraDialog`, `VeloraBottomSheet`, `VeloraToast`, `VeloraTooltip` |
| 7 | Data, flows & app shell | `VeloraDataTable`, `VeloraDataColumn`, `VeloraSortState`, `VeloraPagination`, `VeloraStepper`, `VeloraStep`, `VeloraStepState`, `VeloraWizard`, `VeloraAdaptiveShell`, `VeloraShellBreakpoint`, `VeloraMasterDetailShell`, `VeloraStatusStrip` |
<!-- /generated:ui-layers -->

Every component reads its colors, spacing, radius, and motion from the active theme, and depends only on `flutter`. What you get:

**Layer 1 — tokens & theme:**

- **`VeloraTokens`** — a [`ThemeExtension`](https://api.flutter.dev/flutter/material/ThemeExtension-class.html) carrying the design tokens that don't already live in Flutter's `ColorScheme`/`TextTheme`: spacing, radius, semantic colors (success/warning/info), elevation presets, and motion durations.
- **`VeloraThemePreset`** — a named Velora brand (a seed color + light/dark `VeloraTokens`), used to build a full Material 3 `ColorScheme` via `ColorScheme.fromSeed`.
- **`buildVeloraTheme(...)`** — builds a `ThemeData` (Material 3, `useMaterial3: true`) from a preset and a `Brightness`, with the matching `VeloraTokens` attached via `ThemeData.extensions`.
- **`VeloraTheme.light()` / `VeloraTheme.dark()`** — convenience helpers for the default preset, mirroring the `ClaudeTheme.light()`/`.dark()` shape already used in `examples/claude_clone`.
- **`context.veloraTokens`** — a `BuildContext` extension getter (`VeloraTokensContext`) that reads the `VeloraTokens` off the current `Theme`.
- **`veloraTextTheme(...)`** — the type scale `buildVeloraTheme` applies; call it directly to build a `TextTheme` with your own `fontFamily`.

**Layer 2 — components:** a focused set of presentational widgets (`VeloraButton`, `VeloraCard`, `VeloraBadge`, `VeloraChip`, `VeloraAlert`, `VeloraEmptyState`, `VeloraSkeleton`) that each read their colors, spacing, radius, and motion from the active theme — see [Components](#components) below.

**Layer 3 — form inputs:** controlled input widgets (`VeloraTextField`, `VeloraSelect`, `VeloraCheckbox`, `VeloraSwitch`, `VeloraRadioGroup`) with a `value` + `onChanged` + `errorText` API that binds to any controller — including a `VeloraFormController` field — see [Form inputs](#form-inputs) below.

**Layer 4 — layout & content display:** `VeloraAvatar`, `VeloraListTile`, `VeloraSectionHeader`, `VeloraDivider`, `VeloraProgress` — see [Layout and content display](#layout-and-content-display).

**Layer 5 — navigation & scaffolding:** `VeloraNavBar`, `VeloraNavRail`, `VeloraTabs`, `VeloraScaffold`, sharing the `VeloraNavDestination` model — see [Navigation and scaffolding](#navigation-and-scaffolding).

**Layer 6 — feedback & overlays:** `VeloraDialog`, `VeloraBottomSheet`, `VeloraToast`, `VeloraTooltip` — see [Feedback and overlays](#feedback-and-overlays).

**Layer 7 — data, flows & app shell:** `VeloraDataTable`, `VeloraStepper`, `VeloraWizard`, `VeloraAdaptiveShell`, `VeloraMasterDetailShell` — see [Data table](#data-table), [Stepper and wizard](#stepper-and-wizard), and [App shell](#app-shell).

`velora_ui` is **not** a [Velora plugin](../plugins.md) and doesn't wire into `Velora.boot(plugins: [...])` — it's just Flutter theming, applied via your app's `theme:`/`darkTheme:` arguments (or a `VeloraApp` wrapper, if your app uses one), exactly like any other `ThemeData`.

## Install

```yaml
dependencies:
  velora_ui:
    path: packages/velora_ui # or the pub.dev version once published
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:velora_ui/velora_ui.dart';

MaterialApp(
  theme: VeloraTheme.light(),
  darkTheme: VeloraTheme.dark(),
  themeMode: ThemeMode.system,
  home: const MyHomePage(),
);
```

Read tokens anywhere below that `MaterialApp`:

```dart
Widget build(BuildContext context) {
  final tokens = context.veloraTokens;

  return Container(
    padding: EdgeInsets.all(tokens.spacingMd),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      boxShadow: tokens.shadowSm,
    ),
    child: Text(
      'Saved',
      style: TextStyle(color: tokens.success),
    ),
  );
}
```

If you need a specific brand preset (or brightness) rather than the default, call `buildVeloraTheme(...)` directly:

```dart
buildVeloraTheme(brightness: Brightness.dark, preset: VeloraThemePreset.meadow);
```

## Token categories

`VeloraTokens` only carries what Material's `ColorScheme`/`TextTheme` don't already give you — everything else (primary/secondary/surface colors, the type scale) comes for free from `ColorScheme.fromSeed` in `buildVeloraTheme`.

| Category | Fields | Notes |
|---|---|---|
| Spacing | `spacingXs` … `spacingXxl` (4 / 8 / 16 / 24 / 32 / 48) | Logical pixels; use directly or via `EdgeInsets`. |
| Radius | `radiusSm` / `radiusMd` / `radiusLg` / `radiusPill` (4 / 8 / 16 / 999) | For `BorderRadius.circular(...)`; `radiusPill` always renders as a stadium shape. |
| Semantic colors | `success`/`onSuccess`, `warning`/`onWarning`, `info`/`onInfo` | The three states Material's `ColorScheme` doesn't define (it only has `error`/`onError`). Different values per `Brightness`. |
| Elevation | `elevation1` … `elevation4` (doubles) + `shadowSm`/`shadowMd` (`BoxShadow` presets) | For custom-painted surfaces that want a shadow without a full `Material`/`Card` widget. |
| Motion | `motionFast` / `motionNormal` / `motionSlow` (120ms / 220ms / 360ms) | `Duration`s for implicit/explicit animations, kept consistent app-wide. |

All fields are `final`; `copyWith(...)` overrides individual tokens, and `lerp(...)` interpolates between two token sets (used automatically by Flutter when animating between themes).

## The palette

Velora's name evokes "velvet" and "aurora" — the default preset leans into the latter.

- **`VeloraThemePreset.aurora`** (default) — seed `#5B4FE6`, a saturated indigo-violet. A twilight-sky hue that's confident and modern without echoing Flutter's default blue (`#2196F3`), Material 3's own demo seed (`#6750A4`), or any other product's brand color.
- **`VeloraThemePreset.meadow`** — seed `#1E8A6E`, a grounded teal-green, offered as a calmer, growth/productivity-flavored alternate identity.

Each seed expands into a full Material 3 tonal `ColorScheme` via `ColorScheme.fromSeed` — you don't hand-pick every surface color, just the one brand hue. Semantic colors (hand-picked, not derived from the seed) for the default token set:

| Token | Light | Dark |
|---|---|---|
| `success` / `onSuccess` | `#1E7D46` / `#FFFFFF` | `#6FDC9D` / `#063823` |
| `warning` / `onWarning` | `#8A5300` / `#FFFFFF` | `#FFC46B` / `#452B00` |
| `info` / `onInfo` | `#1A5FB4` / `#FFFFFF` | `#9CC8FF` / `#0B3564` |

## Components

Every Layer 2 widget is a pure presentational widget that reads its colors, spacing, radius, and motion from the active theme (`context.veloraTokens` + `ColorScheme`) — so it tracks light/dark and any token override automatically, and never hard-codes a hex value. They depend only on `flutter` (no Velora core needed), so you can drop them into any Flutter app that applies a Velora theme.

| Component | What it's for | Highlights |
|---|---|---|
| `VeloraButton` | The primary action control. | `variant` (primary/secondary/outline/ghost/danger), `size` (small/medium/large), built-in `loading` spinner (also swallows taps), optional `icon`, `fullWidth`. |
| `VeloraCard` | A padded, rounded surface for grouped content. | Token radius/padding/shadow; optional `onTap` (ripple clipped to the corners); `elevated` and `color` overrides. |
| `VeloraBadge` | A small status pill — a count or a state label. | `VeloraStatus`-driven color; `solid` or `soft` style; optional leading `icon`. |
| `VeloraChip` | An interactive filter/selection/tag chip. | `selected` state, `onTap` to toggle, `onDeleted` for a dismiss affordance, optional `icon`. |
| `VeloraAlert` | An inline semantic message banner. | `VeloraStatus` accent + default icon, optional `title`, optional `onClose` button (caller controls visibility). |
| `VeloraEmptyState` | A centered "nothing here yet" placeholder. | Muted `icon`, `title`, optional `message`, optional `action` (typically a `VeloraButton`). |
| `VeloraSkeleton` | A loading placeholder. | Gentle opacity pulse (`motionSlow`); auto-static under `MediaQuery.disableAnimations`; `.circle(...)` and `.text(...)` constructors. |

`VeloraStatus` (`success` / `warning` / `info` / `error`) is the shared enum behind the status-driven components; it resolves to a `VeloraStatusColors` from `VeloraTokens` (success/warning/info) or the `ColorScheme` (error) via `status.colors(context)` (the `VeloraStatusResolver` extension). The button and badge options are the `VeloraButtonVariant`, `VeloraButtonSize`, and `VeloraBadgeStyle` enums.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const VeloraAlert(
      status: VeloraStatus.success,
      title: 'Saved',
      message: 'Your changes were saved.',
    ),
    SizedBox(height: context.veloraTokens.spacingMd),
    // Wrap the reactive read in Obx so the button rebuilds when the flag
    // changes (reading `.value` outside Obx never re-subscribes).
    Obx(
      () => VeloraButton(
        label: 'Continue',
        icon: Icons.arrow_forward,
        loading: controller.isLoading.value,
        onPressed: controller.submit,
      ),
    ),
  ],
);
```

## Form inputs

Layer 3 adds the controlled form inputs. Each is **presentational and
framework-agnostic** (depends only on `flutter`) but exposes the exact shape a
form controller wants: a current `value`, an `onChanged` callback, and a
nullable `errorText`. Because `VeloraFormController` (in `package:velora`)
exposes per-field values and errors, wiring a field to the framework's form
layer is just passing those through — no coupling in either direction.

| Input | Notes |
|---|---|
| `VeloraTextField` | Single/multi-line text. `label`/`hint`/`helperText`/`errorText`, `prefixIcon`/`suffixIcon`, a built-in show/hide toggle when `obscureText` is true, plus the usual `keyboardType`/`maxLines`/`inputFormatters`. Manages its own `TextEditingController` if you don't pass one. |
| `VeloraSelect<T>` | A dropdown over `VeloraSelectOption<T>`s, matching `VeloraTextField`'s decoration and error styling. |
| `VeloraCheckbox` | A labeled, full-row-tappable checkbox with optional `subtitle` and `errorText`. |
| `VeloraSwitch` | A settings-style labeled switch row. |
| `VeloraRadioGroup<T>` | A vertical single-select group of `VeloraRadioOption<T>`s with an optional group `label` and `errorText`. |

Sketch of binding a text field to a `VeloraFormController`, whose `firstError(field)` returns the first validation message for a field (or null when valid):

```dart
class SignUpController extends VeloraFormController {
  final email = TextEditingController();
  // ...submit() calls setErrors(...) from the server's 422 response.
}

// In the view:
Obx(
  () => VeloraTextField(
    label: 'Email',
    controller: c.email,
    keyboardType: TextInputType.emailAddress,
    errorText: c.firstError('email'), // reactive; null when valid
  ),
);
```

The inputs never reach into the framework themselves — you decide how `value`/
`onChanged`/`errorText` map to your controller, so the same widgets work with a
plain `setState`, a GetX controller, or `VeloraFormController`.

## Layout and content display

Layer 4 arranges other widgets rather than collecting input.

| Component | What it's for | Parameters |
|---|---|---|
| `VeloraAvatar` | A circular photo, initials, or icon avatar. | `image`, `name` (initials fallback), `size`, `backgroundColor`, `foregroundColor`. |
| `VeloraListTile` | A token-styled row. | `leading`, `title`, `subtitle`, `trailing`, `onTap`. |
| `VeloraSectionHeader` | A titled header for a content section. | `title`, `subtitle`, `action` (trailing widget). |
| `VeloraDivider` | A thin themed separator. | `vertical`, `indent`, `endIndent`, `color`. |
| `VeloraProgress` | A progress indicator. | `VeloraProgress.linear(value:)` and `VeloraProgress.circular(value:, size:)`; a null `value` is indeterminate. |

## Navigation and scaffolding

Layer 5 is controlled, like the form inputs: the caller owns the selected index and passes it back in. The widgets hold no navigation state and know nothing about routes.

| Component | What it's for | Parameters |
|---|---|---|
| `VeloraNavDestination` | Immutable icon + label model shared by the bar and rail. | `icon`, `selectedIcon`, `label`. |
| `VeloraNavBar` | Bottom navigation for compact layouts. | `destinations`, `selectedIndex`, `onDestinationSelected`. |
| `VeloraNavRail` | Side navigation for wide layouts. | Same three, plus `leading` and `trailing`. |
| `VeloraTabs` | A pill segmented control for switching views within a screen. | `tabs`, `selectedIndex`, `onChanged`. |
| `VeloraScaffold` | A thin `Scaffold` wrapper. | `title`, `actions`, `leading`, `body`, `bottomNavigationBar`, `floatingActionButton`. |

```dart
VeloraScaffold(
  title: 'Inbox',
  body: pages[index],
  bottomNavigationBar: VeloraNavBar(
    destinations: const [
      VeloraNavDestination(icon: Icons.inbox_outlined, label: 'Inbox'),
      VeloraNavDestination(icon: Icons.settings_outlined, label: 'Settings'),
    ],
    selectedIndex: index,
    onDestinationSelected: (i) => setState(() => index = i),
  ),
);
```

## Feedback and overlays

Layer 6 covers what interrupts or floats above the current screen. The chrome comes from `buildVeloraTheme`'s `dialogTheme`, `snackBarTheme`, `tooltipTheme`, and `bottomSheetTheme`, so apply a Velora theme for these to look right.

| Component | What it's for | API |
|---|---|---|
| `VeloraDialog` | A token-styled modal. | Widget with `title`, `message`, `content`, `actions`, `icon`, `status`; `VeloraDialog.show(context, ...)`; `VeloraDialog.confirm(context, ...)` with `confirmLabel`, `cancelLabel`, `destructive`. |
| `VeloraBottomSheet` | A modal bottom sheet. | `VeloraBottomSheet.show(context, builder:, title:, showDragHandle:, isScrollControlled:, isDismissible:)`. |
| `VeloraToast` | Transient `ScaffoldMessenger` feedback. | `VeloraToast.show(context, ...)` with an optional `VeloraStatus` icon and action. |
| `VeloraTooltip` | A themed wrapper around Material's `Tooltip`. | `message`, `child`. |

`VeloraToast` needs a `ScaffoldMessenger` above it and a `BuildContext`. `Velora.toast` in `package:velora` is the separate, context-free facade for controllers; `velora_ui` does not depend on it.

## Data table

`VeloraDataTable<T>` displays one page of rows. It does not fetch, sort, filter, or page; the caller does, and passes the result back in. That keeps it usable with `setState`, a Velora controller, or anything else.

```dart
VeloraDataTable<User>(
  rows: pageOfUsers,                       // already sorted and paged
  columns: [
    VeloraDataColumn(
      id: 'name',
      label: 'Name',
      sortable: true,
      cell: (user) => Text(user.name),
    ),
    VeloraDataColumn(
      id: 'seats',
      label: 'Seats',
      numeric: true,
      cell: (user) => Text('${user.seats}'),
    ),
  ],
  selected: selected,
  onSelectionChanged: (next) => setState(() => selected = next),
  sort: sort,
  onSortChanged: (next) => setState(() {
    sort = next;
    pageOfUsers = sortAndPage(allUsers, next, page);
  }),
  onRowTap: (user) => setState(() => open = user),
  rowLabel: (user) => user.name,
  loading: loading,
  empty: const VeloraEmptyState(icon: Icons.inbox_outlined, title: 'No users'),
  footer: VeloraPagination(
    page: page,
    pageCount: pageCount,
    onPageChanged: (p) => setState(() => page = p),
  ),
);
```

| Parameter | Meaning |
|---|---|
| `rows`, `columns` | The page of rows and the `VeloraDataColumn<T>` definitions (`id`, `label`, `cell`, `sortable`, `numeric`, `flex`). |
| `selected`, `onSelectionChanged`, `multiSelect` | Controlled selection as a `Set<T>`, matched by `==`. A null callback makes the table non-selectable. `multiSelect: false` replaces the selection and hides select-all. Selected rows that are not on the current page are preserved. |
| `sort`, `onSortChanged` | A `VeloraSortState(columnId, ascending:)` shown in the header, and the sort the user asked for. Tapping a sorted column flips its direction. |
| `onRowTap`, `rowActions` | Row activation, and a builder for trailing per-row actions. |
| `rowLabel` | Describes a row for screen readers ("Select Ada Lovelace"). |
| `loading`, `error`, `empty` | See states below. |
| `footer` | The pagination slot. `VeloraPagination(page:, pageCount:, onPageChanged:)` fits it; pages start at 1. |
| `compactBreakpoint`, `minColumnWidth`, `skeletonRows` | 600, 120, and 3 by default. |

**States.** `error` replaces the rows. `loading` with no rows shows skeleton rows; `loading` with rows keeps them on screen under a progress bar. No rows and not loading shows `empty` (or "No results").

**Widths.** Below `compactBreakpoint` each row becomes a card with every value labelled, plus a sort menu and select-all. Above it, if the columns need more than `minColumnWidth × flex` each, the table scrolls horizontally instead of squeezing. The breakpoint is the table's own width, not the window's, so a table inside a narrow pane goes compact too.

**Keyboard and accessibility.** Tab reaches select-all, each sortable header, then each row. On a row, Up/Down move between rows, Enter calls `onRowTap`, and Space toggles selection. The focused row has a `primary`-colored outline. Headers announce "Name, sorted ascending"; checkboxes announce "Select …". Rows grow with text scale.

**Tokens.** Spacing and radius from `VeloraTokens`; `primary`, `primaryContainer`, `outlineVariant`, `surfaceContainerLow`, and `onSurfaceVariant` from the `ColorScheme`.

**Common mistakes.**

- Expecting the table to sort. It reports `onSortChanged`; sort or re-query, then pass new `rows`.
- Passing every record. The table builds all rows it is given; pass one page.
- Selecting by a model without `==`. After a refetch the new instances will not match `selected`; implement `==`/`hashCode` on an id.
- With a Velora controller, wrap the table in `Obx` and read the reactive values inside it: `Obx(() => VeloraDataTable(rows: c.rows.toList(), selected: c.selected.toSet(), ...))`. Passing an `RxList` without reading it registers no subscription.

## Stepper and wizard

`VeloraStepper` shows progress. `VeloraWizard` adds the current step's content and Back / Continue / Submit. Neither owns flow state or validation.

```dart
VeloraWizard(
  steps: const [
    VeloraStep(title: 'Account'),
    VeloraStep(title: 'Plan', description: 'Change it any time'),
    VeloraStep(title: 'Invite', optional: true),
  ],
  currentStep: step,
  stepBuilder: (context, index) => switch (index) {
    0 => VeloraTextField(label: 'Email', controller: email, errorText: emailError),
    1 => PlanPicker(value: plan, onChanged: (p) => setState(() => plan = p)),
    _ => const InviteForm(),
  },
  onNext: () {
    if (step == 0 && !email.text.contains('@')) {
      setState(() => emailError = 'Enter a valid email');
      return;                               // validation stays in the app
    }
    setState(() => step++);
  },
  onBack: () => setState(() => step--),
  onSubmit: () async => api.createAccount(email.text, plan),
  errorText: submitError,
);
```

`VeloraStep` has `title`, `description`, `optional`, and `state`. A step's state is derived from `currentStep` (before it: `completed`; at it: `current`; after it: `upcoming`) unless `state` overrides it; use the override for `VeloraStepState.error` and `VeloraStepState.disabled`.

| `VeloraStepper` | |
|---|---|
| `steps`, `currentStep` | Required. |
| `onStepTapped` | Reports taps on any step that is not disabled. Null makes steps non-interactive. |
| `direction` | `Axis.horizontal` (default) or `Axis.vertical`. |

| `VeloraWizard` | |
|---|---|
| `steps`, `currentStep`, `stepBuilder` | Required. `stepBuilder(context, index)` builds a step's content. |
| `onNext`, `onBack`, `onSubmit` | What was pressed. The primary button calls `onSubmit` on the last step and `onNext` otherwise. `onNext` and `onSubmit` may return a `Future`. |
| `busy`, `canContinue`, `errorText` | Caller-controlled: disable everything and show a spinner; disable the primary button; show an error above the actions. |
| `onStepTapped`, `stepperDirection` | Passed to the stepper. |
| `backLabel`, `nextLabel`, `submitLabel` | "Back", "Continue", "Submit". |

**Behavior.**

- Visited steps stay mounted, so going back keeps what was typed. Steps never visited are not built.
- If `onNext` or `onSubmit` returns a `Future`, all actions are disabled until it completes. A second press cannot submit twice.
- When `currentStep` changes, focus moves to the new step, so the next Tab lands on its first field.
- A horizontal stepper needs about 96 px per step (more at larger text sizes). With less, it collapses to "Step 2 of 5", the current title, and a progress bar. Vertical never collapses.
- Each step announces "Step 2 of 5, Plan, current". The indicator's color change is skipped when the platform asks for reduced motion.

**With `VeloraFormController`.** The wizard is not coupled to it. Validate in `onNext`, put the messages in the controller with `setErrors`, and read them back with `firstError`:

```dart
onNext: () {
  form.clearErrors();
  if (step == 0 && !form.email.text.contains('@')) {
    form.setErrors({'email': ['Enter a valid email']});
    return;
  }
  setState(() => step++);
},
// in stepBuilder:
Obx(
  () => VeloraTextField(
    label: 'Email',
    controller: form.email,
    errorText: form.firstError('email'),
  ),
),
```

Here `form` is your own `VeloraFormController` subclass that owns the `email` `TextEditingController`. Server-side 422 errors go through the same `setErrors` call from `onSubmit`.

**Common mistakes.**

- Advancing `currentStep` inside `stepBuilder` or a field's `onChanged`. Only `onNext`/`onBack`/`onStepTapped` should move it.
- Creating `TextEditingController`s inside `stepBuilder`. Own them in your state or controller; the wizard keeps widgets alive, not objects you rebuild.
- Putting a tall wizard in a fixed-height box. It sizes to its content; wrap it in a scroll view.

## App shell

`VeloraAdaptiveShell` is a `Scaffold` whose navigation follows the width: a `VeloraNavBar` at the bottom below 600 px, a `VeloraNavRail` at the side from 600 px, and an optional secondary pane from 1024 px. `VeloraShellBreakpoint.forWidth(width)` returns `compact`, `medium`, or `expanded` using the same thresholds.

```dart
VeloraAdaptiveShell(
  destinations: const [
    VeloraNavDestination(icon: Icons.inbox_outlined, label: 'Inbox'),
    VeloraNavDestination(icon: Icons.people_outline, label: 'People'),
  ],
  selectedIndex: index,
  onDestinationSelected: (i) => setState(() => index = i),   // or your router
  appBar: AppBar(title: const Text('Acme')),
  status: offline
      ? const VeloraStatusStrip(icon: Icons.cloud_off_outlined, message: 'Offline')
      : null,
  body: IndexedStack(index: index, children: pages),
);
```

| Parameter | Meaning |
|---|---|
| `destinations`, `selectedIndex`, `onDestinationSelected` | Controlled navigation. The shell reports a choice and never selects on its own. |
| `body` | The current page. The app owns what goes here. |
| `appBar`, `floatingActionButton` | Passed to the `Scaffold`. |
| `status` | A strip under the app bar. `VeloraStatusStrip(message:, icon:, busy:, action:)` is provided; it is a live region, so changes are announced. |
| `secondaryPane`, `secondaryPaneWidth` | A side pane shown only when expanded (360 px). |
| `railLeading`, `railTrailing` | Slots above and below the rail destinations, e.g. an account switcher. |
| `mediumBreakpoint`, `expandedBreakpoint` | 600 and 1024. |

`VeloraMasterDetailShell` handles list and detail:

```dart
VeloraMasterDetailShell(
  master: UserTable(onOpen: (u) => setState(() => open = u)),
  detail: open == null ? null : UserDetail(open!),
  placeholder: const VeloraEmptyState(icon: Icons.person_outline, title: 'Select a user'),
  onCloseDetail: () => setState(() => open = null),
);
```

From 840 px (`breakpoint`) the list (`masterWidth`, 360 px) and the detail sit side by side. Below that the detail covers the list while one is open, and system back or Escape calls `onCloseDetail`.

**What the shell does not do.** It has no route names and parses nothing. A deep link or notification selects a destination by changing the `selectedIndex` you pass; your app decides which index a link maps to. It does not detect connectivity or sync state either; `status` shows what you give it.

**State across resizing.** `body`, `secondaryPane`, the master, and the detail keep their `State` when the window crosses a breakpoint. In the stacked layout the list stays mounted while covered, so its scroll position survives. To keep pages alive when switching destinations, use an `IndexedStack` as the body; the shell shows whatever body it is given.

**Focus.** Destinations come before the body in Tab order. When the detail closes, focus returns to what was focused in the list, normally the row that opened it. When it opens, focus moves into the detail.

**Windows.** The shell reads only its own constraints, so it responds to any resize. It holds no timers or listeners, so nothing needs handling when the window is hidden, inactive, or restored. There is no enforced minimum window size: the layouts are tested down to 320 px wide and at 200% text scale. If your app sets a minimum, 360 × 480 is a reasonable floor.

**Common mistakes.**

- Putting a `Scaffold` in `body`. The shell is the `Scaffold`; a nested one doubles the safe-area padding.
- Changing `selectedIndex` in `onDestinationSelected` without changing the body. They are separate inputs.
- Expecting `secondaryPane` to appear on phones. It is expanded-only; on smaller widths show that content elsewhere.

## Not included

There is no virtualized table for very large row sets, no column resizing or reordering, and no dedicated `VeloraFormController` binding helper. `velora make:module` does not generate pages that use these widgets yet.

---

**See also:** [Plugins →](../plugins.md) for how `velora_ui` differs from a `VeloraPlugin` package (it wires via `theme:`, not `Velora.boot(plugins:)`).
