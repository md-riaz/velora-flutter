# Commands

Run commands from the package or generated app directory they target. No project-wide command is required for MVP setup.

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
dart run velora_cli make:auth --sanctum
dart run velora_cli make:module users --crud
dart run velora_cli make:notifications
dart run velora_cli install:push --fcm
dart run velora_cli install:push --local
dart run velora_cli install velora_offline
```

## Starter app

```bash
cd examples/velora_starter
flutter pub get
flutter run
flutter test
```

Generated apps use the same CLI commands from their root after adding `velora_cli` to the local development workflow.

## Notification commands

`make:notifications` writes an analyzer-friendly notification module under `lib/app/modules/notifications`, plus `.ai/notifications.md` and platform reminder docs.

`install:push --fcm` writes FCM setup placeholders, including `web/firebase-messaging-sw.js`, and reminders for Android, iOS, Web, and Laravel. Placeholder Firebase credentials must be replaced by the app team.

`install:push --local` writes the local notification adapter placeholder and setup reminders without requiring FCM server credentials. Keep the generated noop/mock adapter bound until real platform push is configured.

## Installing a plugin package

`install <package>` is the Laravel-style "install a package and it's wired for you" step for the Velora plugin ecosystem:

1. Adds the package as a dependency in `pubspec.yaml` (idempotent — running it again does not duplicate the entry).
2. Wires the plugin into `lib/main.dart` by adding the package import and inserting the plugin expression into the `plugins: [...]` list passed to `Velora.boot(...)` (creating the list if `Velora.boot` has no `plugins:` argument yet). Also idempotent.
3. Runs `flutter pub get` (falling back to `dart pub get`) to fetch the new dependency, unless `--no-pub-get` is passed.

Flags:

- `--no-wire` — only add the pubspec dependency; skip editing `lib/main.dart`.
- `--no-pub-get` — skip running `pub get` (useful in CI or when offline).

Currently available packages: `velora_offline` (see `packages/velora_offline`). Until it is published to pub.dev, override it with a git or path dependency after installing.

```bash
dart run velora_cli install velora_offline
```
