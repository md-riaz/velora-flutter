# Framework / App Layer Boundary

The authoritative reference for deciding where new code lives.
Written for developers and AI agents planning, implementing, or reviewing changes to the Velora DX layer and any app built on it.

---

## Core Principle

> The framework owns **horizontal infrastructure** — capabilities any Velora-powered app could use regardless of domain, with no brand or business assumptions baked in. The app owns everything tied to a specific domain, user story, brand, or product decision.

A useful proxy: if you removed the framework code from a chat app and dropped it unchanged into a booking app, would it still compile and make sense? If yes, it belongs in the framework. If it references conversations, messages, or a brand color palette — it does not.

The framework is a DX layer, not a product. It should feel like a well-designed tool belt, not a half-built app.

---

## What the Framework Owns

These categories live in `packages/velora/lib/src/` and are re-exported through `velora.dart`. They carry no assumptions about what kind of app consumes them.

| Category | Key exports | Rule that places it here |
|---|---|---|
| **Bootstrap & DI** | `Velora.boot()`, `VeloraApp`, `VeloraConfig` | Every app needs exactly one initialization path |
| **HTTP client** | `VeloraApiService`, `ApiResponse`, `ApiException`, `VeloraApiInterceptor` | Domain-agnostic transport; apps configure base URL and interceptors, not the client |
| **Mock utilities** | `MockApiService`, `VeloraMockApi` | Shared testing infrastructure; avoids each app re-implementing delay/error simulation |
| **Auth** | `AuthService`, `VeloraUser`, `SessionState` | `VeloraUser` is a base type apps extend; the service manages tokens/session, not profile fields |
| **Routing** | `VeloraNav`, `VeloraRouteGuard`, `VeloraAuthGuard` | Navigation primitives and guards are domain-agnostic plumbing |
| **Storage** | `VeloraStorageService` | Key-value persistence abstraction — apps choose what to store, not how |
| **Theme** | `ThemeService`, `VeloraTheme.fromScheme()` | Light/dark mode switching and persistence are shared infrastructure; brand *colors* are not |
| **Pagination** | `PaginatedData<T>`, `CursorPage<T,C>`, `VeloraPaginatedController`, `VeloraCursorController` | Generic data-loading contracts; zero knowledge of what `T` is |
| **Feature flags** | `FeatureService`, `VeloraFeature` | Infrastructure for toggling capabilities; apps register and read flags, framework does not know their names |
| **Permissions** | `PermissionService`, `VeloraPermission` | Role/permission evaluation logic is domain-agnostic enforcement |
| **Notifications** | `VeloraNotify`, `PushAdapter`, `NotificationEvent` | Infrastructure for delivery channels; payload content is app-defined |
| **Media / uploads** | `VeloraMediaService`, `VeloraAttachment`, `VeloraAttachmentsMixin`, `VeloraUploadAdapter` | File-picking and upload normalization; apps plug in their own backend adapter |
| **Generic UI primitives** | `VeloraEmptyState`, `VeloraErrorView`, `VeloraFormField`, `VeloraLoadingButton`, `VeloraAttachmentChip` | Presentational scaffolding with no domain copy or brand tokens; customized via parameters |
| **Toast / Dialog / Loader** | `VeloraToast`, `VeloraDialog`, `VeloraLoader` | UI primitives every app needs; content/text supplied by the caller |
| **Controller bases** | `VeloraController`, `VeloraFormController` | Standardize `loading`/`error`/`run()` patterns; no domain methods |
| **Responsive** | `Responsive` breakpoint helpers | Layout breakpoints are universal |

**Framework rule:** If adding a method or field to a framework class requires knowing the name of any route, model, or endpoint specific to one app, the code does not belong in the framework.

---

## What the App Owns

These live in the consuming app (`examples/claude_clone/` for the reference demo). They use framework services but carry all domain and brand knowledge.

| Category | Examples from the demo | Rule that places it here |
|---|---|---|
| **Domain models** | `ConversationModel`, `ChatMessage`, `MessageRole` | Tied to the product's entity graph — another app has completely different models |
| **Data sources** | `ConversationsDataSource`, `MessagesDataSource`, all `Mock*` implementations | Know specific endpoints, response shapes, and seeded data |
| **Controllers** | `HomeController`, `ChatController`, `SettingsController`, `AccountController` | Contain business logic tied to screens and user stories |
| **Pages / views** | `HomePage`, `ChatPage`, `SettingsPage`, `AccountPage` | Screen layout, copy, and UX are product decisions |
| **Brand theme** | `ClaudeTheme`, `ClaudeColors`, `ClaudeTokens` | Color palette, radius, and design tokens are identity, not infrastructure |
| **Route definitions** | `AppRoutes`, `AppPages` | Route names are app-specific contracts; framework only provides the navigation facade |
| **Feature flag names** | `'chat.voice'`, `'chat.canvas'`, etc. | Names are product vocabulary; the *service* that manages them is framework |
| **Domain-specific UI** | Chat bubble, audio waveform, message input bar, conversation tile | Assumes a chat domain; a booking app's UI looks nothing like this |
| **Connectivity banner** | `OfflineBanner` with chat-specific copy | Copy ("Messages will send when reconnected") is domain knowledge |
| **Audio recording integration** | `record` package wiring, waveform widget, audio bubble | Assumes a messaging product; no second Velora app needs this in its current form |
| **Mock data seeds** | 22 quantum-entanglement messages, 8 seeded conversations | Content is always app-layer; seeds represent one specific domain narrative |
| **App bootstrap config** | `Velora.boot(config: VeloraConfig(...))`, feature registration in `main()` | Configuration values are app decisions passed into framework services |

**App rule:** If the code would need to be rewritten from scratch for a task-management app vs. a chat app — even if the *pattern* is the same — it belongs in the app.

---

## Decision Rules

Apply in order. The first rule that fires determines placement. If two rules conflict, the more restrictive one wins.

1. **Cross-domain test** — Would this code be useful, unchanged, in a task-management app *and* a chat app *and* a booking app?
   - Yes → `FW`. No → `APP`.

2. **Domain model import** — Does the code import or reference any domain model (`ConversationModel`, `BookingModel`, etc.)?
   - Yes → `APP`, unconditionally.

3. **Hardcoded copy** — Does the code contain hardcoded button labels, toast messages, or placeholder text?
   - Yes → `APP`. Framework components accept copy as constructor parameters, never embed it.

4. **Platform normalization** — Is this wrapping a platform/OS capability to normalize it across platforms?
   - Yes → Framework candidate. Proceed to rule 5 before confirming.

5. **YAGNI gate** — Does a second distinct app need this capability right now?
   - No second consumer → Stay in `APP`. Build an abstract adapter in the framework only once a second consumer appears.

6. **Route reference** — Does the code reference any route name or screen by name?
   - Yes → `APP`. Routes are app contracts. Framework navigation accepts route strings as arguments; it does not know them.

7. **Brand token** — Is this a brand color, a specific radius value, or a design token?
   - Yes → `APP` theme resources. `VeloraTheme.fromScheme()` accepts a `ColorScheme`; brand palettes are not part of the framework.

8. **Widget configurability** — Does the UI component need configuration to work in any context, or does it always look the same?
   - Configurable, no domain assumptions → `FW` widget. Fixed appearance or domain copy → `APP` widget.

---

## Gray-Zone Verdicts

Explicit rulings on cases that have been debated or are likely to come up again.

| Capability | Verdict | Rationale |
|---|---|---|
| **Connectivity detection** (wrapping `connectivity_plus`, exposing `Rx<bool> isOnline`) | `FW` | Pure platform normalization with no domain knowledge. Any app might react to connectivity. Add as `ConnectivityService` in `src/connectivity/`. |
| **Offline banner widget** (visual strip saying "You're offline") | `APP` | Generic in concept but the copy ("Messages will send when reconnected") is chat-domain specific. Promote to `VeloraOfflineBanner(message: String)` only when a second app needs it. |
| **Audio recording** (`record` package, waveform, audio bubble) | `APP` | Only the chat module needs this. YAGNI applies. If a second Velora app needs audio, extract an abstract `VeloraAudioAdapter` at that point. The waveform UI and bubble are chat-domain widgets regardless. |
| **Pending message queue** (offline-first send buffer) | `APP` | Queue mechanics depend entirely on the domain's entity graph. Extract a generic `VeloraOfflineQueue<T>` only after two distinct use cases appear. |
| **Rename dialog** (`_RenameDialog` StatefulWidget) | `APP` | The prompt, field hint, and target entity are chat-specific. A `VeloraDialog.prompt()` generic would be framework-level; it doesn't exist yet. |
| **Cursor pagination primitives** (`CursorPage<T,C>`, `VeloraCursorController`) | `FW` | Fully generic. The controller calls an abstract `fetchNextPage(C? cursor)`; the framework knows nothing about what `T` or `C` are. |
| **Mock seeded data** (`MockMessagesDataSource._store`, 22 messages) | `APP` | `VeloraMockApi` (framework) provides delay/error mechanics. What you seed is domain content and lives in the app's data sources. |
| **`VeloraUser` extension fields** (adding `plan`, `avatarUrl`, etc.) | `APP` | Extend `VeloraUser` in the app via a subclass or `Velora.userAs<T>()`. Base class stays lean. |
| **Feature flag names** (`'chat.voice'`, `'chat.canvas'`) | `APP` | Names are product vocabulary. `FeatureService.register()` is framework; the flags registered via it are app config. Registration goes in `main()`, not in any controller. |
| **Push notification payload shape** | `APP` | `NotificationPayload` (framework) carries the envelope. Parsing `data` into a `MessageNotification` domain object is app work. |

---

## Historical Decisions & Rationale

### Feature registration moved from `SettingsController.onInit()` → `main()`

**Problem:** Registering flags inside a GetX controller re-registers on every navigation to the Settings screen, causing duplicate-registration warnings and non-deterministic flag state.

**Decision:** App bootstrap (`main()`) is the one place that runs exactly once per session. Feature flags are registered there, after `Velora.boot()` completes. `SettingsController` only reads and toggles flags — it never owns their lifecycle.

**Principle reinforced:** Service registration is a bootstrap concern. Controllers are consumers, not registrars.

---

### Audio recording kept out of the Velora framework

**Request:** Add audio recording and an audio message feature to Velora as a framework service (`VeloraAudioService`).

**Decision:** `APP` — implement directly in the demo app's chat module.

**Reasoning:** Only one app currently needs audio recording. The `record` package integration, waveform widget, and audio bubble all assume a messaging context. Premature extraction into the framework would add surface area to a shared layer for a capability with a single consumer. If a second Velora-powered app needs audio, the pattern can be extracted at that point as a `VeloraAudioAdapter` abstract class — with the concrete implementation still living in each app.

---

### `_RenameDialog` refactored to `StatefulWidget`

**Problem:** The original implementation created a `TextEditingController` in `ChatController.renameConversation()` and disposed it after `await Get.dialog()` returned. The dialog close animation still accessed the disposed controller, causing a use-after-dispose crash.

**Decision:** Move controller ownership into a `StatefulWidget` that creates in `initState` and disposes in `dispose`.

**Principle reinforced:** `TextEditingController` lifetime must be tied to a widget's lifecycle, not an async function's scope.

---

### Error guards added to all mutation methods

**Problem:** `run()` swallows failures into `error.value` but early implementations updated local state (`conversation.value`, `items[idx]`) and showed success toasts unconditionally after `run()`, regardless of whether it caught an exception.

**Decision:** Every mutation method checks `if (error.value.isNotEmpty) return;` immediately after `await run(...)`. Optimistic updates (e.g., `toggleStar`) roll back the local value on failure. `nav.back()` and success toasts are only emitted on confirmed success.

**Pattern to follow:**
```dart
await run(() async {
  await datasource.doSomething();
});
if (error.value.isNotEmpty) return; // ← always guard here
localState.update();
Velora.toast.success('Done');
```

---

### `loadEarlier` scroll-position anchoring

**Problem:** Prepending earlier messages at index 0 of a non-reversed `ListView` kept the same scroll offset while content grew above the viewport, snapping the user away from their reading position.

**Decision:** Capture `maxScrollExtent` before the insert, then restore reading position via `addPostFrameCallback` delta jump:
```dart
final prevMax = scrollController.position.maxScrollExtent;
messages.insertAll(0, page.data);
WidgetsBinding.instance.addPostFrameCallback((_) {
  final delta = scrollController.position.maxScrollExtent - prevMax;
  scrollController.jumpTo(scrollController.offset + delta);
});
```

---

## Anti-Patterns

| Anti-pattern | Why it's wrong |
|---|---|
| **Domain model in the framework** — adding `MessageModel` to `packages/velora/lib/` | The framework must not know what entities an app manages. Use generic type parameters instead. |
| **Endpoint path in a framework service** — adding `VeloraApiService.getConversations()` | `VeloraApiService` takes a path as a parameter; it does not know the API surface of any app. |
| **Brand color in framework theme** — hardcoding an app's primary color in `ThemeService` | `VeloraTheme.fromScheme(colorScheme)` accepts the brand's colors as input; it does not own them. |
| **Feature flag names in `Velora.boot()` config** | Feature *registration* happens in the app's `main()`; the framework provides the mechanism only. |
| **Domain logic in `VeloraController`** — adding `sendMessage()` to the base class | The base defines `run()`, `loading`, `error`. Domain behavior belongs in app controller subclasses. |
| **Premature framework extraction** — promoting single-app features before a second consumer exists | YAGNI: extraction has a real cost (surface area, versioning, test burden) and should be deferred. |
| **Service registration in a controller** — calling `Velora.feature.register()` in `onInit()` | Registration runs exactly once, in `main()`. Controllers only read and toggle. |
| **Framework widget with hardcoded copy** — `VeloraEmptyState` with fixed text | The widget accepts `title` and `description` as parameters; specific copy is an app decision. |
