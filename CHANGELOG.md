# Changelog

## Unreleased

### Breaking

- **Toolchain baseline raised to Flutter 3.47.0 / Dart 3.13.0** for every package, example, and generated app (`sdk: ^3.13.0`, `flutter: '>=3.47.0'`). Older SDKs are unsupported; there is no compatibility path. See `docs/toolchain.md`.
- Dependency lines moved to new majors: `file_picker` 13, `flutter_secure_storage` 11, `equatable` 3, `connectivity_plus` 7, `firebase_core` 5, `firebase_messaging` 17, `flutter_local_notifications` 23, `flutter_timezone` 5, `timezone` 0.11. Apps that use these plugins directly must move to the same lines.

### Changed

- `velora doctor` prints the required and detected Flutter/Dart versions and warns when either is missing or below the baseline.
- `velora new` generates apps with the baseline `environment` constraints.
- CI pins Flutter 3.47.9, rejects older toolchains, checks formatting, resolves every package from a clean checkout with enforced lockfiles, and now also tests `velora_cli` and `velora_lints`.

### Docs

- Documentation synced with shipped code: `velora_ui` Layers 4–6, all six installable packages, CLI commands, the `.ai/` files, and package READMEs. `velora.md` is marked historical.
- `tool/check_docs.sh` fails CI when docs drift from the CLI command registry, the installable-package registry, `packages/velora_ui/components.json`, the SDK baseline, or when a local link or documented path is broken.
- `velora help` now prints each command's summary and the installable packages.

### Fixed

- `VeloraMediaService.pickMultiImage` awaits inside its `try`, so a failure while reading a picked file's size honours `rethrowErrors` instead of escaping the handler.

## 0.0.1

- Initialized Velora monorepo.
- Added runtime package, CLI package, and starter app skeleton.
