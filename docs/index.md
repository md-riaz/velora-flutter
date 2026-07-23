---
hide:
  - toc
---

# Velora

**The Laravel way for Flutter.** Drop auth, API, permissions, notifications, and scaffolding into your Flutter app — structured the way you already think after years of Laravel.

[Get Started](getting-started.md){ .md-button .md-button--primary }
[API Reference](../api/){ .md-button }
[Live Demo](../demo/){ .md-button }

---

## Your Path to Production

Follow these guides in order. Each one builds on the last — from zero to a fully wired Flutter + Laravel app.

<div class="grid cards" markdown>

-   :material-numeric-1-circle:{ .lg } **Install & Boot**

    ---

    Add Velora to your `pubspec.yaml`, call `Velora.boot()`, and swap in a mock data source so you can build without a running backend.

    [→ Get Started](getting-started.md)

-   :material-numeric-2-circle:{ .lg } **Architecture**

    ---

    How a feature is actually wired — plain constructor injection via a per-module factory, controllers owning their own screen-local state, and why there's no service locator or `Bindings` subclass in sight.

    [→ Architecture](architecture.md)

-   :material-numeric-3-circle:{ .lg } **Auth**

    ---

    Wire Laravel Sanctum login, read session state, and implement the safe logout contract so teardown never leaves a half-cleared session.

    [→ Auth](auth.md)

-   :material-numeric-4-circle:{ .lg } **API Client**

    ---

    Call your Laravel endpoints via `Velora.api`, unwrap `ApiResponse<T>`, and swap in mock data sources without touching controllers.

    [→ API Client](api-client.md)

-   :material-numeric-5-circle:{ .lg } **Permissions**

    ---

    Gate widgets by server-assigned roles and permissions using `Can` and `RoleOnly` — reactive, no boilerplate.

    [→ Permissions](permissions.md)

-   :material-numeric-6-circle:{ .lg } **Notifications**

    ---

    Scaffold FCM/APNs push, an in-app notification center, and unread badges with a single CLI command.

    [→ Notifications](notifications.md)

-   :material-numeric-7-circle:{ .lg } **Scaffold a Module**

    ---

    Generate a complete CRUD module — service, repository, data source, controller, pages — following all conventions automatically.

    [→ Scaffold a Module](scaffolding.md)

</div>

---

## Official packages

The core (`package:velora`) stays deliberately small — auth, API client, permissions, notifications, storage, routing. Everything else ships as its own installable package, wired in at boot the same way a Laravel app pulls in a Composer package:

<div class="grid cards" markdown>

-   :material-cloud-off-outline:{ .lg } **velora_offline**

    ---

    Connectivity awareness, an offline write queue that replays on reconnect, and an offline-first repository — reactive local reads plus optimistic writes — layered over velora_db.

    [→ velora_offline](packages/offline.md)

-   :material-database-outline:{ .lg } **velora_db**

    ---

    A cross-platform, reactive local database (native + Web) with an Eloquent-style query API, built on drift.

    [→ velora_db](packages/db.md)

-   :material-cog-outline:{ .lg } **velora_env**

    ---

    Laravel-style `.env` config and dev/staging/prod flavors, readable in `main()` before `Velora.boot()` even runs.

    [→ velora_env](packages/env.md)

-   :material-bell-ring-outline:{ .lg } **velora_fcm**

    ---

    A Firebase Cloud Messaging `PushAdapter` — wired via `Velora.boot(pushAdapter: VeloraFcmAdapter())`.

    [→ velora_fcm](packages/fcm.md)

-   :material-bell-outline:{ .lg } **velora_local_notifications**

    ---

    An on-device local-notification adapter over `flutter_local_notifications` — wired via `Velora.boot(localAdapter: VeloraLocalNotificationsAdapter())`.

    [→ velora_local_notifications](packages/local-notifications.md)

</div>

`velora_offline`, `velora_db`, and `velora_env` are `VeloraPlugin`s, spliced automatically into `Velora.boot(plugins: [...])`; `velora_fcm` and `velora_local_notifications` wire via named `pushAdapter:`/`localAdapter:` boot arguments instead — see [Plugins →](plugins.md) for why. Either way, adding one to your app starts the same way:

```bash
velora install <package>
```

which adds the pub dependency, wires it into `Velora.boot()` when that's possible to do automatically, and prints any remaining manual setup steps.

---

## Install

Velora is currently in developer preview. Add it as a git dependency:

```yaml title="pubspec.yaml"
dependencies:
  velora:
    git:
      url: https://github.com/md-riaz/velora-flutter
      path: packages/velora
```

pub.dev publication coming soon. Continue to [Install & Boot →](getting-started.md) to finish setup.
