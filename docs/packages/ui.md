# velora_ui

An optional Material theme foundation independent of core and usable alongside other UI libraries. Use Flutter's native widgets for standard controls. See [architecture](../architecture.md).

<!-- generated:ui-layers source=packages/velora_ui/components.json — do not edit; run tool/check_docs.sh --write -->
| Layer | Focus | Exports |
|---|---|---|
| 1 | Theme and components | `ThemePreset`, `DesignTokens`, `StatusTone`, `StatusColors`, `StatusColorPair`, `AdaptiveShell`, `ShellBreakpoint`, `ShellDestination`, `ResponsiveDataTable`, `ResponsiveDataColumn`, `TableSortState`, `Skeleton`, `EmptyState`, `InlineAlert` |
<!-- /generated:ui-layers -->

## Presets and native widgets

```dart
MaterialApp(
  theme: ThemePreset.aurora.light(),
  darkTheme: ThemePreset.aurora.dark(),
  themeMode: ThemeMode.system,
);
```

Presets are `aurora`, `meadow`, `neutral`, and `corporate`. Their `light()` and `dark()` methods accept `colorScheme`, `seedColor`, `visualDensity`, `textTheme`, `fontFamily`, `tokens`, `statusColors`, and `extensions`; `colorScheme` takes precedence over `seedColor`. You can also derive a custom preset with `ThemePreset.aurora.copyWith(...)`. Pass overrides to the preset method rather than calling `ThemeData.copyWith(colorScheme: ...)` so component themes re-derive from the final scheme and tokens. Any `extensions` passed are merged alongside `DesignTokens` and `StatusColors`.

`DesignTokens.of(context)` reads spacing, radius, elevation and motion. `StatusColors.of(context)` provides success, warning, info and error `StatusColorPair`s; select one with `forTone(StatusTone.warning)`. Both require a preset theme.

Composite exports: `AdaptiveShell`, `ShellBreakpoint`, `ShellDestination`, `ResponsiveDataTable`, `ResponsiveDataColumn`, `TableSortState`, `Skeleton`, `EmptyState`, and `InlineAlert`.

## Fonts

Presets use the platform font. Declare your font under `flutter: fonts:` in the app's pubspec, then pass `fontFamily:` (or a custom `textTheme:`) to `light()` / `dark()` or `ThemePreset.copyWith(...)`.

## Persist theme mode

After `Velora.boot`, store the mode name in `VeloraStorageService` and bind it to the app root. Missing or unknown values fall back to system mode.

```dart
final storage = Velora.storage;
final saved = storage.get<String>('themeMode');
final mode = ThemeMode.values.firstWhere(
  (value) => value.name == saved,
  orElse: () => ThemeMode.system,
).obs;

Future<void> setThemeMode(ThemeMode value) async {
  mode.value = value;
  await storage.set('themeMode', value.name);
}

Obx(() => GetMaterialApp(
  theme: ThemePreset.aurora.light(),
  darkTheme: ThemePreset.aurora.dark(),
  themeMode: mode.value,
));
```

## Deleted wrappers

| Removed | Flutter replacement |
|---|---|
| `VeloraButton` | `FilledButton`, `OutlinedButton`, `TextButton` |
| `VeloraTextField` | `TextField`, `TextFormField` |
| `VeloraCard` | `Card` |
| `VeloraCheckbox`, `VeloraSwitch`, `VeloraRadioGroup` | `Checkbox`, `Switch`, `RadioGroup` and `Radio` |
| `VeloraSelect`, `VeloraSelectOption` | `DropdownMenu` |
| `VeloraChip`, `VeloraBadge`, `VeloraAvatar` | `Chip`, `Badge`, `CircleAvatar` |
| `VeloraDivider`, `VeloraTooltip` | `Divider`, `Tooltip` |
| `VeloraDialog`, `VeloraBottomSheet`, `VeloraToast` | `showDialog`, `showModalBottomSheet`, `ScaffoldMessenger.showSnackBar` |
| `VeloraNavRail`, `VeloraNavBar` | `NavigationRail`, `NavigationBar` |
| `VeloraTabs`, `VeloraStepper`, `VeloraProgress`, `VeloraListTile` | `TabBar`, `Stepper`, progress indicators, `ListTile` |
| `VeloraScaffold` | `Scaffold` |
| `VeloraSectionHeader` | `Row` with `TextTheme.titleMedium` |

See the [migration guide](../migration/v-next.md) for breaking changes.
