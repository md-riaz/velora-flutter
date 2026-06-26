---
hide:
  - toc
---

# Velora

**The Laravel way for Flutter.** Auth, API client, role-based permissions, notifications, and scaffolded modules — wired together the way you already think after years of Laravel.

[Get Started](getting-started.md){ .md-button .md-button--primary }
[API Reference](../api/){ .md-button }
[Live Demo](../demo/){ .md-button }

---

## Guides

<div class="grid cards" markdown>

-   :material-rocket-launch:{ .lg } **Getting Started**

    ---

    Boot config, `VeloraConfig`, and mock mode so you can build your UI without a backend.

    [→ Getting Started](getting-started.md)

-   :material-layers:{ .lg } **Architecture**

    ---

    GetX layering, the service-vs-controller split, and the repository pattern that keeps data access swappable.

    [→ Architecture](architecture.md)

-   :material-lock:{ .lg } **Auth**

    ---

    Laravel Sanctum token flow, mock login for local dev, logout safety contract.

    [→ Auth](auth.md)

-   :material-web:{ .lg } **API Client**

    ---

    `Velora.api` facade, `ApiResponse<T>` unwrapping, mock data sources.

    [→ API Client](api-client.md)

-   :material-shield-account:{ .lg } **Permissions & RBAC**

    ---

    `Can` and `RoleOnly` widgets gate UI by server-assigned permission or role.

    [→ Permissions](permissions.md)

-   :material-bell:{ .lg } **Notifications**

    ---

    FCM/APNs wiring, in-app list, unread badge, CLI platform setup commands.

    [→ Notifications](notifications.md)

-   :material-code-braces:{ .lg } **Scaffolding**

    ---

    Generate modules, auth flows, and notification setup in one command.

    [→ Scaffolding](scaffolding.md)

-   :material-console:{ .lg } **CLI Commands**

    ---

    Full reference for all Velora CLI commands and their options.

    [→ CLI Commands](commands.md)

-   :material-border-all:{ .lg } **Framework / App Boundary**

    ---

    Where code lives, decision rules, and the anti-patterns that blur the line.

    [→ Framework / App Boundary](framework-app-boundary.md)

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

pub.dev publication coming soon.
