# Docs

Guides for Velora. The published site navigation is defined in `mkdocs.yml`.

**Core journey**

- [Getting Started](getting-started.md): add the dependency, boot config, mock mode.
- [Architecture](architecture.md): the canonical layering guide — constructor injection, where shared state lives, Velora and GetX.
- [Auth](auth.md): bearer-token flow, demo/mock login, and the logout safety contract.
- [API Client](api-client.md): `Velora.api`, responses, errors, and mock data sources.
- [Permissions](permissions.md): frontend helpers with backend enforcement.
- [Notifications](notifications.md): notification architecture, adapters, and mock/noop mode.
- [Scaffolding](scaffolding.md): generated app, module, auth, and notification files.

**Reference**

- [Commands](commands.md): CLI commands and installable packages (generated from the CLI registries).
- [Framework / App Boundary](framework-app-boundary.md): what belongs in the framework and what belongs in an app.
- [Plugins](plugins.md): the `VeloraPlugin` contract and how packages wire in.
- [Web & PWA](pwa.md): `make:pwa`, the service worker, and offline web.
- [Toolchain baseline](toolchain.md): required Flutter/Dart versions and dependency status.
- [AI Ready](ai-ready.md): the `.ai/` context files generated apps ship with.

**Official packages**

- [velora_offline](packages/offline.md), [velora_db](packages/db.md), [velora_env](packages/env.md), [velora_fcm](packages/fcm.md), [velora_local_notifications](packages/local-notifications.md), [velora_ui](packages/ui.md).

**Project**

- [Example apps](examples.md), [Contributing](contributing.md), [Roadmap](roadmap.md), [MVP Scope](mvp.md).

Root `velora.md` and `velora.part2.md` are historical planning documents. They conflict with the shipped framework in places and are not a source of truth.
