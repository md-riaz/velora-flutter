# Scaffolding

Run CLI commands from `packages/velora_cli` while developing the CLI, or from a generated app once the CLI is installed there.

```sh
dart run velora_cli new admin_panel
dart run velora_cli make:auth --sanctum
dart run velora_cli make:module users --crud
dart run velora_cli make:notifications
dart run velora_cli install:push --fcm
dart run velora_cli install:push --local
dart run velora_cli doctor
```

`new` creates a Flutter app skeleton, routes, a theme file, and `.ai/` context files. `make:auth --sanctum` creates the login screen. `make:module users --crud` creates the module folder, binding, controller, service, model, routes, and CRUD pages. `make:notifications` creates the notification center module. `install:push --fcm` creates FCM setup placeholders and platform reminders. `install:push --local` creates local notification placeholders and reminders without Firebase credentials.

Module code should follow the corrected architecture:

```text
View -> Controller -> GetxService -> Repository -> DataSource
```

The starter Users module shows the full convention with `UsersService`, `UsersRepository`, `UsersRemoteDataSource`, and a mock data source for local testing. Keep generated controllers UI-focused and put shared/business state in services.
