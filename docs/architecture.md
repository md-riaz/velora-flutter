# Architecture

Velora is GetX-first. `velora.part2.md` is authoritative where it corrects the original blueprint: services own application/business state, repositories stay data-access focused.

## Layering

```text
View
  ↓
Controller
  ↓
Service / GetxService
  ↓
Repository Interface
  ↓
Repository Implementation
  ↓
RemoteDataSource / LocalDataSource
  ↓
Velora.api / Velora.storage
```

## State ownership

GetxService owns shared and business state:

- Auth session state.
- Current user state.
- Permission and entitlement state.
- Theme and settings state.
- Long-lived feature state.
- Business workflow logic.

Controllers own screen state and user actions. `GetxService` classes own shared state, feature workflows, and session/business logic. Repositories define data-access contracts; repository implementations delegate to remote/local data sources. Data sources are the only layer that should know whether data comes from `Velora.api`, local storage, or a mock.

## Repository/data-source convention

Use one repository interface per feature and bind an implementation in the feature binding. Remote data sources call Laravel REST endpoints through `Velora.api`; local data sources use `Velora.storage`; mock data sources can be bound for starter/demo testing without changing controllers or services.

## Notifications

NotificationService is the single source of truth for remote push, local notifications, and in-app notification center state.

```text
Notification UI
  ↓
NotificationController
  ↓
NotificationService / GetxService
  ↓
NotificationRepository
  ↓
NotificationRemoteDataSource
  ↓
Velora.api
  ↓
Laravel API
```

Laravel remains source of truth for notification records. FCM is only transport for Android, iOS, and Web push. Local notifications handle foreground/local display. Generated adapters include mock/noop mode so apps can develop notification UI without Firebase credentials.

Do not store unread counts, notification lists, push tokens, permission state, or routing state in controllers. Use `Velora.notify` when runtime support is bound, or inject generated `NotificationService` in app modules.
## MVP boundary

MVP keeps runtime features in `packages/velora`, CLI scaffolding in `packages/velora_cli`, and starter usage in `examples/velora_starter`. Do not split extra packages until the core flow is stable.
