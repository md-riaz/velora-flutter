# Changelog

## Unreleased

### Breaking

- Custom `VeloraDesktopWindowPort` and `VeloraDesktopService` implementations must implement title bar style and window button visibility setters.

- Core visual APIs, feedback renderers, theme service, permission widgets, responsive helper and attachment widgets were removed; `run(showErrorToast:)` is now `run(reportError:)` and `showLoader` was removed. Apps own presentation through `FeedbackPresenter`. `velora_ui` now uses native widgets, `ThemePreset`, `DesignTokens`, `StatusColors`, and renamed composite components. The complete removed and renamed API list and replacements are in [the migration guide](docs/migration/v-next.md).
- Removed `VeloraApp`, `ThemeService`, core `VeloraTheme`, `Velora.toast`, `Velora.dialog`, `Velora.loader`, `VeloraToast`, `VeloraDialog`, `VeloraLoader`, `Can`, `Responsive`, `VeloraResponsive`, `VeloraResponsiveContext`, `VeloraEmptyState`, `VeloraErrorView`, `VeloraFormField`, `VeloraLoadingButton`, `VeloraLoadingOutlinedButton`, `VeloraAttachmentChip`, `VeloraAttachmentStrip`, and `VeloraAttachmentPickerSheet`.
- Removed UI `VeloraButton`, `VeloraButtonVariant`, `VeloraButtonSize`, `VeloraTextField`, `VeloraCard`, `VeloraCheckbox`, `VeloraSwitch`, `VeloraRadioGroup`, `VeloraRadioOption`, `VeloraSelect`, `VeloraSelectOption`, `VeloraChip`, `VeloraBadge`, `VeloraBadgeStyle`, `VeloraAvatar`, `VeloraDivider`, `VeloraTooltip`, `VeloraDialog`, `VeloraBottomSheet`, `VeloraToast`, `VeloraNavRail`, `VeloraNavBar`, `VeloraTabs`, `VeloraStepper`, `VeloraStep`, `VeloraStepState`, `VeloraProgress`, `VeloraListTile`, `VeloraScaffold`, `VeloraSectionHeader`, `VeloraPagination`, `VeloraWizard`, `VeloraMasterDetailShell`, and `VeloraStatusStrip`.
- Renamed `VeloraThemePreset` to `ThemePreset`, `VeloraTokens` to `DesignTokens`, `VeloraStatus` to `StatusTone`, `VeloraStatusColors` to `StatusColors`, `VeloraAdaptiveShell` to `AdaptiveShell`, `VeloraShellBreakpoint` to `ShellBreakpoint`, `VeloraNavDestination` to `ShellDestination`, `VeloraDataTable` to `ResponsiveDataTable`, `VeloraDataColumn` to `ResponsiveDataColumn`, `VeloraSortState` to `TableSortState`, `VeloraSkeleton` to `Skeleton`, UI `VeloraEmptyState` to `EmptyState`, and `VeloraAlert` to `InlineAlert`. Removed `buildVeloraTheme`, UI `VeloraTheme`, `veloraTextTheme`, `VeloraTokensContext`, `context.veloraTokens`, and `VeloraStatusResolver`.
- **Toolchain baseline raised to Flutter 3.47.0 / Dart 3.13.0** for every package, example, and generated app (`sdk: ^3.13.0`, `flutter: '>=3.47.0'`). Older SDKs are unsupported; there is no compatibility path. See `docs/toolchain.md`.
- Dependency lines moved to new majors: `file_picker` 13, `flutter_secure_storage` 11, `connectivity_plus` 7, `firebase_core` 5, `firebase_messaging` 17, `flutter_local_notifications` 23, `flutter_timezone` 5, `timezone` 0.11. Apps that use these plugins directly must move to the same lines.

### Changed

- An unknown command now suggests the closest command name.
- `velora doctor` prints the required and detected Flutter/Dart versions and warns when either is missing or below the baseline.
- `velora new` generates apps with the baseline `environment` constraints.
- `velora new` adds `velora_cli` as a dev dependency of the generated app, so `dart run velora_cli …` works from the app root.
- CI on pull requests now analyzes and tests only affected packages, in parallel, instead of every package on every PR.
- CI pins Flutter 3.47.9, rejects older toolchains, checks formatting, resolves every package from a clean checkout with enforced lockfiles, and now also tests `velora_cli` and `velora_lints`.

### Added

- `velora_desktop` supports title bar style and native window button visibility configuration and runtime updates.

- `velora search`, `velora component`, `velora docs`, and `velora manifest`: look up components, guides, packages, and commands from the versions a project has installed. Each takes `--json` and prints a versioned envelope; failures carry stable `ERR_*` codes. See `docs/agent-tooling.md`.
- `velora make:agents` writes a managed lookup section into `AGENTS.md`; `velora new` includes it, and `velora doctor` warns when it is out of date.
- `velora_ui` Layer 7: `VeloraDataTable` (typed columns, selection, sort, row actions, loading/empty/error, compact card layout, keyboard row navigation) with `VeloraPagination`; `VeloraStepper` and `VeloraWizard`; `VeloraAdaptiveShell`, `VeloraMasterDetailShell`, and `VeloraStatusStrip`. All controlled and state-management independent.
- UI gallery: a data/flows section and a resizable desktop scenario.

### Removed

- `packages/velora` no longer declares `equatable` or `intl`; neither was imported. Apps that relied on getting them transitively must declare them.

### Docs

- `docs/adr/0001-package-graph.md`: inventory of `packages/velora` and the proposed package graph for splitting it. Proposal only; no code moved.

- Documentation synced with shipped code: `velora_ui` Layers 4–6, all six installable packages, CLI commands, the `.ai/` files, and package READMEs. `velora.md` is marked historical.
- `tool/check_docs.sh` fails CI when docs drift from the CLI command registry, the installable-package registry, `packages/velora_ui/components.json`, the SDK baseline, or when a local link or documented path is broken.
- `velora help` now prints each command's summary and the installable packages.

### Fixed

- `VeloraMediaService.pickMultiImage` awaits inside its `try`, so a failure while reading a picked file's size honours `rethrowErrors` instead of escaping the handler.

## 0.0.1

- Initialized Velora monorepo.
- Added runtime package, CLI package, and starter app skeleton.
