# ADR 0001 — Package graph for splitting `packages/velora`

- **Status:** Proposed. Needs maintainer approval before any source moves.
- **Scope:** Phase 1 of the package split: inventory and target graph. No code moves in this change.

## Context

`packages/velora` is one package that every app and every official package depends on. Depending on it pulls in four pub packages with native code (`flutter_secure_storage`, `shared_preferences`, `file_picker`, `image_picker`), whether or not the app stores tokens or picks files. `velora_fcm` only needs the `PushAdapter` interface, yet it inherits all of it.

The tables below are generated from the source tree by `tool/check_docs.sh --write`, so they cannot drift from the code. CI fails if they are stale.

## Inventory

### Capability folders in `packages/velora/lib/src`

<!-- generated:core-inventory source=packages/velora/lib — do not edit; run tool/check_docs.sh --write -->
| Folder | Files | Exported files | Pub packages | Imports from other folders |
|---|---|---|---|---|
| `auth` | 4 | 4 | get | config, core, http, routing, storage |
| `config` | 1 | 1 | — | auth, notifications |
| `core` | 4 | 4 | flutter, get | auth, config, features, http, media, notifications, permissions, routing, storage, theme, ui, validation |
| `data` | 2 | 2 | get | support, validation |
| `features` | 1 | 1 | get | core |
| `http` | 5 | 5 | dio, get, logger | config, storage |
| `media` | 4 | 4 | **file_picker**, **image_picker**, dio, flutter, get | http, ui |
| `notifications` | 11 | 11 | flutter, get | auth, features, http, permissions, routing |
| `permissions` | 2 | 2 | flutter, get | auth, core |
| `responsive` | 1 | 1 | flutter | — |
| `routing` | 2 | 2 | flutter, get | auth, config |
| `storage` | 1 | 1 | **flutter_secure_storage**, **shared_preferences**, flutter, get | — |
| `support` | 1 | 1 | — | — |
| `theme` | 1 | 1 | flutter, get | storage |
| `ui` | 12 | 10 | **image_picker**, flutter, get | media |
| `validation` | 3 | 3 | get | core |

Bold pub packages ship native code. Folder pairs that import each other (7): auth ↔ config; auth ↔ core; auth ↔ routing; core ↔ features; core ↔ permissions; core ↔ validation; media ↔ ui.
<!-- /generated:core-inventory -->

`velora.dart` also re-exports `package:get/get.dart`, so every app that imports Velora gets the whole GetX API.

### Local packages

<!-- generated:package-graph source=packages/*/pubspec.yaml — do not edit; run tool/check_docs.sh --write -->
| Package | Depends on (local) | Depends on (pub) |
|---|---|---|
| `velora` | — | `dio`, `file_picker`, `flutter_secure_storage`, `get`, `image_picker`, `logger`, `shared_preferences` |
| `velora_cli` | — | `path` |
| `velora_db` | `velora` | `dio`, `drift`, `get`, `path`, `path_provider`, `sqlite3` |
| `velora_desktop` | — | `app_links`, `nativeapi`, `nativeapi_flutter`, `power_state_monitor`, `tray_manager`, `window_manager`, `windows_single_instance` |
| `velora_env` | `velora` | `get` |
| `velora_fcm` | `velora` | `firebase_core`, `firebase_messaging` |
| `velora_lints` | — | `analyzer`, `custom_lint_builder` |
| `velora_local_notifications` | `velora` | `flutter_local_notifications`, `flutter_timezone`, `timezone` |
| `velora_offline` | `velora`, `velora_db` | `connectivity_plus`, `dio`, `get` |
| `velora_ui` | — | — |
<!-- /generated:package-graph -->

### What downstream packages use from `velora`

Read from each package's imports and usages:

| Package | Uses from `velora` | Could depend on instead |
|---|---|---|
| `velora_fcm` | `PushAdapter`, `VeloraNotificationConfig`, `VeloraConfig` | `velora_notifications` |
| `velora_local_notifications` | `LocalNotificationAdapter` | `velora_notifications` |
| `velora_env` | `VeloraPlugin`, `VeloraContext`, `VeloraConfig` | `velora_core` |
| `velora_db` | `VeloraPlugin`, `VeloraContext`, `VeloraRepository`, `VeloraRemoteDataSource`, `ApiException`, `VeloraApiService`, `VeloraStorageService` | `velora_core`, `velora_http`, `velora_storage` |
| `velora_offline` | the above plus `VeloraAuthConfig`, `VeloraApiInterceptor` | `velora_core`, `velora_http`, `velora_storage`, `velora_db` |
| `velora_ui` | nothing | unchanged |

## What blocks a split today

**1. The facade is a hub.** `core/` imports 12 of the other 15 folders, almost all through `velora_facade.dart`, and two folders import the facade back (`permissions/permission_widgets.dart` for `Velora.permission`, `validation/velora_controller.dart` for `Velora.loader` and `Velora.toast`). Three of the seven folder cycles (`core ↔ features`, `core ↔ permissions`, `core ↔ validation`) and half of a fourth (`auth ↔ core`) exist only because of it. The facade cannot live in `velora_core`.

**2. `VeloraConfig` aggregates capability config.** `config/velora_config.dart` imports `auth/auth_user.dart` and `notifications/notification_config.dart`, and `auth_service.dart` reads `VeloraConfig` back. `VeloraPlugin` also imports `VeloraConfig`, `VeloraApiService`, and `VeloraApiInterceptor`, so the plugin contract currently drags HTTP and config into anything that implements it.

**3. Concrete cross-capability calls.**

| Edge | Where | Contract that would break it |
|---|---|---|
| `http → storage` | `velora_api_service.dart` reads the bearer token from `VeloraStorageService` | `VeloraTokenStore` |
| `auth → storage`, `auth → http` | `auth_service.dart` | `VeloraTokenStore`; `velora_auth` depends on `velora_http` (one direction) |
| `auth ↔ routing` | `logout_coordinator.dart` calls `VeloraNav`; `velora_route_guard.dart` calls `Get.find<AuthService>()` | a session-state reader in core; logout redirect as a callback or navigator interface |
| `theme → storage` | `theme_service.dart` | the key-value storage contract |
| `media ↔ ui` | `velora_attachments_mixin.dart` opens `VeloraAttachmentPickerSheet`; five UI files import attachment models | move the three attachment widgets with media |
| `media → http` | `velora_upload_adapter.dart` | `velora_media` depends on `velora_http` (one direction) |
| `notifications → auth, http, features, permissions, routing` | `notification_service.dart`, `notification_remote_datasource.dart` | split contracts from the service (below) |

**4. GetX is everywhere.** 13 of 16 folders import `get`; only `config`, `support`, and `responsive` do not.

## Decision

### Target graph

```text
velora_core            plugin contract, lifecycle/logout registry, base config,
                       transport-independent result and error types
  ← velora_storage     key-value contract + secure-storage/shared-prefs implementation
  ← velora_http        Dio API service, interceptors, mock HTTP   (needs a token-store contract from core)
  ← velora_auth        auth service, session state, logout coordinator   (→ velora_http)
  ← velora_notifications   provider-neutral models, adapters, config
  ← velora_media       pickers, attachment models, upload adapter, attachment widgets   (→ velora_http)
  ← velora_db, velora_offline, velora_env, velora_fcm, velora_local_notifications

velora                 umbrella: the `Velora` facade, `VeloraConfig` composition,
                       `Velora.boot`, GetX-based controllers, guards, permissions,
                       features, theme, generic UI; re-exports the packages above
velora_ui              depends on flutter only
```

Rules:

1. No package below the umbrella depends on `velora`.
2. Local package dependencies are acyclic.
3. `velora_ui` depends only on `flutter`.
4. The `Velora` facade, `Velora.boot`, and `VeloraConfig` stay in the umbrella, because they compose every capability.

Rules 2 and 3 already hold and are enforced by `tool/check_docs.sh` from this change on, along with "`velora` depends on no local package" and "every pub dependency `velora` declares is imported". Rule 1 does not hold yet (five packages depend on `velora`); it becomes enforceable per package as each one is repointed.

### GetX stays in the umbrella and in core for now

Extracting GetX is not part of this plan. Controllers, routing, guards, and service registration are built on it, and `docs/architecture.md` documents that as deliberate. `velora_core` will depend on `get` and `flutter`.

Consequence: `velora_realtime`, which must be pure Dart, cannot depend on `velora_core` as drawn. Either it stands alone with its own lifecycle signal type, or `velora_core` is split into a pure-Dart contracts library and a Flutter/GetX binding. That choice is deferred to the realtime work and should be made with a spike, not here.

### Extraction order

1. **`velora_notifications` contracts.** `push_adapter.dart`, `local_notification_adapter.dart`, `noop_push_adapter.dart`, `fcm_push_adapter.dart`, `notification_payload.dart`, `notification_config.dart`, and `notification_event.dart` import nothing outside `notifications/`. They can move first with no new contract. `notification_service.dart`, the repository, the remote data source, and `velora_notify.dart` depend on auth, HTTP, features, permissions, and routing; they stay in the umbrella until those are extracted. `velora_fcm` and `velora_local_notifications` are then repointed and stop depending on `velora`.
2. **`velora_storage`.** `storage/` imports no other folder. Extracting it removes `flutter_secure_storage` and `shared_preferences` from core. Requires the `VeloraTokenStore` contract first, so HTTP and auth stop importing the concrete service.
3. **`velora_media`.** Move `media/` with `velora_attachment_chip.dart`, `velora_attachment_strip.dart`, `velora_attachment_picker_sheet.dart`, and the two `_file_image_*` files. Removes `file_picker` and `image_picker` from core. Depends on HTTP for `MultipartUploadAdapter`, so it either follows step 4 or the upload adapter stays behind until then.
4. **`velora_http`, then `velora_auth`.** Requires splitting `VeloraConfig` so each capability owns its config class, and narrowing `VeloraPlugin` so it no longer imports HTTP types.
5. **Repoint `velora_db`, `velora_offline`, `velora_env`**, update CLI installers and `velora doctor`, add deprecations for moved umbrella exports.

Each step keeps a compatibility re-export in `velora`, so app imports do not change.

### Contracts to define before moving code

Only where a verified import edge needs breaking:

- `VeloraTokenStore` — read/write/clear the bearer token. Breaks `http → storage` and `auth → storage`.
- A session reader (is the user authenticated, where to redirect) — breaks `routing → auth`.
- A logout redirect hook — breaks `auth → routing`.
- Per-capability config classes — break `config ↔ auth` and `config → notifications`.
- A `VeloraPlugin` context that exposes interceptor registration without importing `VeloraApiService`.

Not proposed: a `VeloraHttpClient` abstraction. Nothing in the inventory needs it; Dio is used by `http`, `media`, `velora_db`, and `velora_offline` directly, and one implementation does not justify an interface.

## Done in this change

- Inventory and graph tables, generated and checked in CI.
- Graph rules 2 and 3, plus the two umbrella checks, enforced by `tool/check_docs.sh`.
- Removed `equatable` and `intl` from `packages/velora/pubspec.yaml`. Neither was imported anywhere in the repository.

## Open questions for approval

1. Is `velora_core` allowed to depend on `get` and `flutter`, with realtime handled separately as described?
2. Should the attachment widgets move into `velora_media`, or should media be split into a logic package and widgets that stay in the umbrella?
3. Synchronized versions across all packages are assumed. Confirm before the first extraction, since it decides how `velora doctor` checks compatibility.
4. No size or build-time claim is made. Measuring one needs a baseline build of an example before step 2.
