# Next major migration

Core is UI-agnostic. Register an app-owned `FeedbackPresenter` with `Velora.boot(feedback: ...)`; `Velora.feedback` exposes it. Without one, messages are ignored and confirmation throws. See [architecture](../architecture.md).

| Removed or renamed | Replacement |
|---|---|
| `VeloraApp` | App-owned `GetMaterialApp` or another root |
| `ThemeService`, core `VeloraTheme` | App-owned `ThemeMode` and `ThemeData`; see [theme mode recipe](../packages/ui.md#persist-theme-mode) |
| `Velora.toast`, `Velora.dialog`, `Velora.loader`, `VeloraToast`, `VeloraDialog`, `VeloraLoader` | `Velora.feedback` with an app presenter; render loading from controller `loading` |
| `run(showLoader: ...)` | Bind the page to `loading` |
| `run(showErrorToast: ...)` | `run(reportError: ...)` |
| Core `VeloraEmptyState`, `VeloraErrorView`, `VeloraFormField`, `VeloraLoadingButton` | App widgets or native Flutter widgets; use `errors` and `loading` |
| `VeloraAttachmentChip`, `VeloraAttachmentStrip`, `VeloraAttachmentPickerSheet` | App-owned attachment UI; core attachment models and controller remain |
| Permission widgets and `Responsive` | App-owned widgets and layout breakpoints |
| `VeloraThemePreset`, `VeloraTheme`, `buildVeloraTheme` | `ThemePreset`, `ThemePreset.aurora.light()` / `.dark()` |
| `VeloraTokens`, `context.veloraTokens`, `VeloraTokensContext` | `DesignTokens`, `DesignTokens.of(context)` |
| `veloraTextTheme` | App-owned `TextTheme` |
| `VeloraStatus`, `VeloraStatusColors`, `VeloraStatusResolver` | `StatusTone`, `StatusColors`, `StatusColors.of(context)` |
| `VeloraAdaptiveShell`, `VeloraShellBreakpoint`, `VeloraNavDestination` | `AdaptiveShell`, `ShellBreakpoint`, `ShellDestination` |
| `VeloraDataTable`, `VeloraDataColumn`, `VeloraSortState` | `ResponsiveDataTable`, `ResponsiveDataColumn`, `TableSortState` |
| UI `VeloraEmptyState`, `VeloraSkeleton`, `VeloraAlert` | `EmptyState`, `Skeleton`, `InlineAlert` |
| `Can` | Check `Velora.permission` in app-owned UI |
| `VeloraResponsive`, `VeloraResponsiveContext`, `Responsive` | Flutter `LayoutBuilder` / `MediaQuery` and app-owned breakpoints |
| `VeloraLoadingOutlinedButton` | `OutlinedButton` driven by `loading` |
| `VeloraMasterDetailShell`, `VeloraStatusStrip`, `VeloraPagination`, `VeloraWizard` | App-owned layouts and controls |
| `VeloraStep`, `VeloraStepState` | Flutter `Step`, `StepState` |
| `VeloraRadioOption` | App-owned values with Flutter `Radio` |
| `VeloraButtonVariant`, `VeloraButtonSize`, `VeloraBadgeStyle` | Native button and badge styling |

The [native widget table](../packages/ui.md#deleted-wrappers) lists the deleted UI wrappers and their Flutter replacements. Migrate wrapper-specific options and enum values to the corresponding native widget configuration.
