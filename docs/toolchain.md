# Toolchain baseline

Every Velora package, example, and generated app requires:

| Tool | Minimum | CI pin |
|---|---|---|
| Flutter | 3.47.0 | 3.47.9 (stable) |
| Dart | 3.13.0 | 3.13.7 (bundled with Flutter 3.47.9) |

```yaml title="pubspec.yaml"
environment:
  sdk: ^3.13.0
  flutter: '>=3.47.0' # Flutter packages and apps only
```

Pure Dart packages (`velora_cli`, `velora_lints`) declare only the `sdk` line.

Older Flutter and Dart versions are unsupported. There is no compatibility path: `pub get` refuses to resolve on an older SDK, and CI fails before running anything else.

## Local setup

```bash
flutter upgrade            # or install Flutter >=3.47.0 from flutter.dev
flutter --version          # Flutter 3.47.x • Dart 3.13.x
tool/check_baseline.sh     # verifies the SDKs and every pubspec.yaml
tool/pub_get_all.sh        # resolves every package and example
tool/check_docs.sh         # verifies docs against shipped code
```

`tool/check_baseline.sh` checks three things: the active Flutter/Dart versions, that every tracked `pubspec.yaml` declares the constraints above (the list comes from `git ls-files`, so new packages are covered automatically), and that no file imports a deprecated desktop `legacy.dart` library (`window_manager`, `tray_manager`, `screen_retriever`).

`tool/pub_get_all.sh` uses `--enforce-lockfile` wherever a `pubspec.lock` is committed (the examples and `velora_cli`), so a stale lockfile fails instead of being rewritten. After changing dependencies, refresh the lockfiles and commit them:

```bash
tool/pub_get_all.sh --upgrade-locks
```

In an app, `dart run velora_cli doctor` prints the required and detected Flutter/Dart versions and warns when either is below the baseline.

## Upgrading an app to this baseline

1. `flutter upgrade`, then confirm with `flutter --version`.
2. Set the `environment` block shown above in your `pubspec.yaml`.
3. `flutter pub upgrade --major-versions`, then `flutter analyze` and `flutter test`.
4. `dart run velora_cli doctor`.

Dart 3.13 reports two diagnostics that older SDKs did not: `unawaited_return_in_try_block` (add `await`) and `analysis_options_deprecated_plugins` (see `custom_lint` below).

## Dependency status

Refreshed on Flutter 3.47.9 / Dart 3.13.7 with `flutter pub outdated` / `dart pub outdated`. Direct dependencies moved to a new major line:

| Package | Dependency | From | To |
|---|---|---|---|
| `velora` | `file_picker` | ^8.0.0 | ^13.3.3 |
| `velora` | `flutter_secure_storage` | ^10.3.1 | ^11.2.0 |
| `velora` | `equatable` | ^2.0.7 | ^3.0.0 |
| `velora_offline` | `connectivity_plus` | ^6.0.0 | ^7.3.2 |
| `velora_offline` | `flutter_secure_storage` | ^10.3.1 | ^11.2.0 |
| `velora_fcm` | `firebase_core` | ^3.6.0 | ^5.1.0 |
| `velora_fcm` | `firebase_messaging` | ^15.1.0 | ^17.0.1 |
| `velora_local_notifications` | `flutter_local_notifications` | ^18.0.0 | ^23.0.1 |
| `velora_local_notifications` | `flutter_timezone` | ^2.0.0 | ^5.1.1 |
| `velora_local_notifications` | `timezone` | ^0.9.0 | ^0.11.2 |
| examples | `cupertino_icons` | ^1.0.8 | ^2.0.0 |

Apps that depend on these plugins directly must move to the same lines, and should re-read each plugin's platform setup notes for the new major version.

No desktop packages (`window_manager`, `tray_manager`, `screen_retriever`, …) are dependencies yet; they arrive with the `velora_desktop` work and must use their nativeapi-backed releases, never the `legacy.dart` imports.

### Still behind latest stable

| Package | Dependency | Resolved | Latest | Why |
|---|---|---|---|---|
| `velora_lints` | `custom_lint_builder` | 0.6.4 | 0.8.1 | Needs the lint rules ported to the analyzer 8 API. |
| `velora_lints` | `analyzer` | 6.4.1 | 14.7.0 | Capped by `custom_lint_builder`. |
| `velora_lints` | `test` (dev) | 1.26.3 | 1.33.0 | Capped by `analyzer` 6. |
| `velora`, examples | `custom_lint` (dev) | 0.6.4 | 0.8.1 | Must match `velora_lints`. |

`custom_lint` loads through the legacy analyzer plugin API, which Dart 3.13 deprecates (`analysis_options_deprecated_plugins`). Packages that enable it silence that one diagnostic in `analysis_options.yaml`. The lint rules still run and pass on Dart 3.13. The fix is to port `velora_lints` to `analysis_server_plugin`, which removes `custom_lint` and this whole table.
