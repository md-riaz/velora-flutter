# Commands

Run commands from the package or generated app directory they target. No project-wide command is required for MVP setup.

## CLI commands

`dart run velora_cli help` prints the same list.

<!-- generated:cli-commands source=packages/velora_cli/lib/velora_cli.dart — do not edit; run tool/check_docs.sh --write -->
| Command | What it does |
|---|---|
| `velora new <name>` | Create a new Velora app skeleton. |
| `velora make:module <name> [--crud]` | Generate a module: factory, routes, model, data source, repository, service, controller, and pages. |
| `velora make:auth --sanctum` | Scaffold the login and auth flow. |
| `velora make:notifications` | Generate the in-app notification center module. |
| `velora make:pwa` | Write a production web manifest and an offline service worker. |
| `velora install:push --fcm \| --local` | Write FCM or local-notification setup placeholders and reminders. |
| `velora install <package> [--no-pub-get] [--no-wire]` | Add an official Velora package and wire it into Velora.boot() when it can be. |
| `velora doctor` | Check the velora dependency, Velora.boot() wiring, unwired plugins, the managed AGENTS.md section, and the Flutter/Dart baseline. |
| `velora make:agents` | Write or refresh the managed Velora section in AGENTS.md. |
| `velora search <query> [--type <type>] [--limit <n>] [--json]` | Search components, docs topics, packages, and commands. |
| `velora component [<name>] [--detail brief\|full] [--source] [--json]` | Describe a velora_ui component from the installed version, or list them all. |
| `velora docs [<topic>] [--json]` | Print a documentation topic, or list the topics. |
| `velora manifest [--json]` | Describe this CLI: commands, packages, output types, and error codes. |
<!-- /generated:cli-commands -->

## Runtime package

```bash
cd packages/velora
flutter pub get
flutter analyze
flutter test
```

## CLI package

```bash
cd packages/velora_cli
dart pub get
dart analyze
dart test
dart run velora_cli doctor
dart run velora_cli new admin_panel
```

The commands above run fine from `packages/velora_cli` because `dart run velora_cli new admin_panel` creates a fresh app elsewhere. `make:*` and `install*` generators, though, read and write files in the **current directory's app** (`pubspec.yaml`, `lib/`, `web/`), so run them from that app's root instead — e.g. after `cd admin_panel`:

```bash
cd admin_panel
dart run velora_cli make:auth --sanctum
dart run velora_cli make:module users --crud
dart run velora_cli make:notifications
dart run velora_cli make:pwa
dart run velora_cli install:push --fcm
dart run velora_cli install:push --local
dart run velora_cli install velora_offline
```

## Example app

```bash
cd examples/claude_clone
flutter pub get
flutter run
flutter test
```

`examples/claude_clone` is a hand-built reference app (not CLI-generated) that exercises Velora at a larger scale. Generated apps (from `velora new`) use the same `flutter pub get` / `flutter run` / `flutter test` commands from their own root.

## Lookup commands

`search`, `component`, `docs`, and `manifest` read from the packages the project has installed and accept `--json`. `make:agents` writes the managed section in `AGENTS.md`. See [Agent Tooling](agent-tooling.md) for the options, the JSON envelope, and the error codes.

## Notification commands

`make:notifications` writes an analyzer-friendly notification module under `lib/app/modules/notifications`, plus `.ai/notifications.md` and platform reminder docs.

`install:push --fcm` writes FCM setup placeholders, including `web/firebase-messaging-sw.js`, and reminders for Android, iOS, Web, and Laravel. Placeholder Firebase credentials must be replaced by the app team.

`install:push --local` writes the local notification adapter placeholder and setup reminders without requiring FCM server credentials. Keep the generated noop/mock adapter bound until real platform push is configured.

## PWA command

`make:pwa` writes a production `web/manifest.json` (real name/description, `display: standalone`, `orientation: any`, neutral colors, the existing maskable icon set) in place of the `flutter create` default. It also generates `web/service_worker.js` and registers it in `web/index.html`, so the app shell (and `velora_db`'s Web WASM assets) still cache for offline use now that Flutter no longer ships a default service worker. It then prints a checklist covering offline data and how to test the result. Run it from the app root; it requires a `web/` directory (`flutter create --platforms web .` first if you don't have one yet). See [Web & PWA →](pwa.md) for the full guide.

## Installing a plugin package

`install <package>` is the Laravel-style "install a package and it's wired for you" step for the Velora plugin ecosystem:

1. Adds the package as a dependency in `pubspec.yaml` (idempotent — running it again does not duplicate the entry).
2. For `VeloraPlugin` packages, wires the plugin into `lib/main.dart` by adding the package import and inserting the plugin expression into the `plugins: [...]` list passed to `Velora.boot(...)` (creating the list if `Velora.boot` has no `plugins:` argument yet). Also idempotent. Other packages are not wired; their manual steps are printed instead.
3. Runs `flutter pub get` (falling back to `dart pub get`) to fetch the new dependency, unless `--no-pub-get` is passed.

Flags:

- `--no-wire` — only add the pubspec dependency; skip editing `lib/main.dart`.
- `--no-pub-get` — skip running `pub get` (useful in CI or when offline).

Installable packages:

<!-- generated:installable-packages source=packages/velora_cli/lib/velora_cli.dart — do not edit; run tool/check_docs.sh --write -->
| Package | What it is | Wiring | Docs |
|---|---|---|---|
| `velora_offline` | Offline-first data layer: connectivity, write outbox, optimistic repository over velora_db. | `plugins: [VeloraOfflinePlugin()]` (automatic) | [offline](packages/offline.md) |
| `velora_db` | Reactive local database on drift (native and web WASM SQLite). | `plugins: [VeloraDbPlugin()]` (automatic) | [db](packages/db.md) |
| `velora_env` | `.env` config and dev/staging/prod flavors. | `plugins: [VeloraEnvPlugin()]` (automatic) | [env](packages/env.md) |
| `velora_fcm` | Firebase Cloud Messaging push adapter. | `pushAdapter: VeloraFcmAdapter()` (manual) | [fcm](packages/fcm.md) |
| `velora_local_notifications` | On-device local notifications adapter. | `localAdapter: VeloraLocalNotificationsAdapter()` (manual) | [local-notifications](packages/local-notifications.md) |
| `velora_ui` | Token-first design system: theme, tokens, and components. | `theme: VeloraTheme.light()` on your app (manual) | [ui](packages/ui.md) |
<!-- /generated:installable-packages -->

Packages marked *automatic* are `VeloraPlugin`s and get spliced into `plugins: [...]`. Packages marked *manual* only get the pubspec dependency; the command prints the remaining wiring steps. None of these are published to pub.dev yet, so override each with a git or path dependency after installing.

```bash
dart run velora_cli install velora_offline
```
