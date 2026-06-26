# 7 — Scaffold a Module

**What you'll do:** Use the Velora CLI to generate a complete CRUD module — service, repository, data source, controller, and pages — then understand what was generated and how to extend it.

---

## Start a new app

Create a brand new Velora-powered Flutter app:

```sh
dart run velora_cli new my_app
```

Writes a Flutter app skeleton with GetX routing, a theme file, and `.ai/` context files for AI-assisted development.

## Scaffold auth

Add the login screen and auth flow:

```sh
dart run velora_cli make:auth --sanctum
```

Generates `lib/app/modules/auth/` with a login page, auth controller, and a mock data source bound by default for dev.

## Scaffold a CRUD module

Generate a complete feature module for any resource:

```sh
dart run velora_cli make:module users --crud
```

Writes `lib/app/modules/users/` containing:

```
users/
  bindings/
    users_binding.dart
  controllers/
    users_controller.dart       ← UI-focused, delegates to service
  services/
    users_service.dart          ← GetxService, owns list state
  models/
    user_model.dart
  data/
    repositories/
      users_repository.dart     ← abstract interface
    sources/
      users_remote_data_source.dart   ← calls Velora.api
      users_mock_data_source.dart     ← seeded fixture data
  views/
    users_page.dart
    users_detail_page.dart
    users_form_page.dart
```

Routes are automatically added to `AppRoutes` and `AppPages`. The mock data source is bound by default — swap to the remote source in `users_binding.dart` when your backend is ready.

## Run a health check

```sh
dart run velora_cli doctor
```

Reports configuration issues, missing platform files, and misconfigured dependencies before they cause runtime errors.

## All CLI commands

| Command | What it does |
|---|---|
| `velora_cli new <name>` | Create a new app skeleton |
| `velora_cli make:auth --sanctum` | Scaffold login + auth flow |
| `velora_cli make:module <name> --crud` | Generate a full CRUD module |
| `velora_cli make:notifications` | Generate notification center module |
| `velora_cli install:push --fcm` | Add FCM push setup files |
| `velora_cli install:push --local` | Add local notifications setup files |
| `velora_cli doctor` | Diagnose configuration problems |

See [CLI Commands →](commands.md) for the full reference including package-level `flutter analyze` and `flutter test` commands.

---

## You're done with the core journey

Your app now has everything in place:

| Step | What you built |
|---|---|
| **1 — Boot** | `Velora.boot()` initializes all core services |
| **2 — Architecture** | Six-layer stack with services owning state |
| **3 — Auth** | Laravel Sanctum login, session state, safe logout |
| **4 — API Client** | Typed requests through repositories and data sources |
| **5 — Permissions** | UI gating by server-assigned roles |
| **6 — Notifications** | FCM push + in-app notification center |
| **7 — Scaffolding** | Generated modules following all conventions |

**Where to go next:**

- [CLI Commands →](commands.md) — full command reference
- [Framework / App Boundary →](framework-app-boundary.md) — decision rules for where code belongs
- [API Reference →](../api/) — generated Dart API docs
