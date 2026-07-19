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

    The six-layer GetX stack, why services own state instead of controllers, and how a feature flows from data source to UI.

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
