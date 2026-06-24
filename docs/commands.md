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
