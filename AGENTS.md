# AGENTS.md

## Velora rules

- Follow `velora.md` and `velora.part2.md` for historical planning context.
- If they conflict, `velora.part2.md` wins for architecture. For logout safety, the current source of truth is the shipped implementation in `packages/velora/lib/src/auth/logout_coordinator.dart` (participant-based teardown via `VeloraLifecycleRegistry`), not either planning doc.
- Blessed architecture is **plain constructor dependency injection**: app controllers extend `VeloraController` / `VeloraFormController` / `VeloraPaginatedController` and own their own screen-local Rx state. Services are plain classes (not `GetxService`) wired by constructor injection in each module's factory (`{name}_module.dart`), exactly as `velora new` / `make:module` generate. Framework-internal services (e.g. `LogoutCoordinator`) happen to extend `GetxService` for lifecycle reasons, but app code does not need `GetxService` and should not introduce app-level ones or Bindings-based DI.
- Controllers contain local UI state and screen actions only.
- Repositories/data sources handle data access only.
- Keep MVP focused: no Supabase, GraphQL, payments, chat, or visual builders. But several capabilities beyond the original MVP ARE shipped and must not be treated as out of scope: offline support via the installable `packages/velora_offline` plugin (`velora install velora_offline`) — now an offline-first data layer (reactive local reads + optimistic writes + write outbox) over `packages/velora_db`; the reactive local database `velora_db` itself (drift; native and web WASM SQLite, with `watch*` reactive reads); push/on-device notifications via `make:notifications` / `install:push --fcm|--local` (see `docs/notifications.md`; FCM push ships as the optional `velora_fcm` adapter, so Firebase is out of scope only as a general backend, not for push); and installable, offline-capable web (PWA) via `velora make:pwa` (see `docs/pwa.md`).
- Public API should remain facade-like and simple.

## Framework / App layer boundary

Before adding or moving any code, read [`docs/framework-app-boundary.md`](docs/framework-app-boundary.md).

The short version:
- **Framework** (`packages/velora/`) owns horizontal infrastructure: HTTP, auth, routing, storage, theme, pagination, feature flags, permissions, notifications, generic UI primitives, controller bases. Zero domain or brand knowledge.
- **App** owns domain models, data sources, controllers, pages, brand theme, route definitions, and any capability needed by only one app (YAGNI).

**Decision shortcut** — if the code would need to be rewritten for a different-domain app, it's app-layer. If it references a domain model, route name, or brand token, it's app-layer. When unsure, consult the gray-zone verdicts table in the doc.

Key patterns enforced in the demo (`examples/claude_clone/`):
- Feature flags registered once in `main()`, not in controllers.
- All mutation methods guard local-state updates with `if (error.value.isNotEmpty) return;` after `await run(...)`.
- Optimistic updates roll back on failure.
- `loadEarlier` preserves scroll position via `maxScrollExtent` delta jump.

## GetX reactive patterns — anti-pattern suite

Velora uses GetX reactivity. The mistakes below produce **silent runtime
breakage in release mode**: no red error widget, just blank grey areas, stale
values, or memory leaks. Understand the model before writing any reactive UI.

### Mental model

`Obx(() => ...)` records every `Rx<T>.value` read that occurs **synchronously
inside the builder on its first execution** and subscribes to those observables.
If zero reads occur, GetX throws "improper use" (silently swallowed in release
mode), the `Obx` becomes an `ErrorWidget` that claims infinite height, and any
sibling `Expanded` child collapses to zero — producing a blank grey body.

---

### Anti-pattern 1 — Rx object passed to child without `.value` read *(the silent killer)*

Flagged by the `obx_missing_reactive_read` lint rule.

```dart
// WRONG: RxList object passed; no .value read → no subscription registered
Obx(() => VeloraAttachmentStrip(attachments: controller.attachments))

// CORRECT: .isEmpty reads the reactive value; subscription is registered
Obx(() {
  if (controller.attachments.isEmpty) return const SizedBox.shrink();
  return VeloraAttachmentStrip(attachments: controller.attachments);
})
```

**Why it's dangerous**: `RxList<T>` extends `List<T>`, so Dart's type checker
accepts it where `List<T>` is expected — the error is invisible until release.

---

### Anti-pattern 2 — `.value` read in `build()` without `Obx`

```dart
// WRONG: value read once at build time; widget never updates
Widget build(BuildContext context) {
  return Text(controller.title.value);
}

// CORRECT
Widget build(BuildContext context) {
  return Obx(() => Text(controller.title.value));
}
```

---

### Anti-pattern 3 — `ever()` / `once()` / `debounce()` registered inside `build()`

Flagged by the `ever_in_widget_build` lint rule.

```dart
// WRONG: new listener added on every rebuild → memory leak + duplicate callbacks
Widget build(BuildContext context) {
  ever(controller.error, (v) => showSnackbar(v)); // BUG
  return ...;
}

// CORRECT: register in onInit, dispose happens automatically via onClose
@override
void onInit() {
  super.onInit();
  ever(error, (v) { if ((v as String).isNotEmpty) Velora.toast.error(v); });
}
```

---

### Anti-pattern 4 — `Obx` wrapping subtree with zero reactive reads

```dart
// WRONG: Obx with no observable reads → "improper use" warning in debug
Obx(() => const Text('Static text'))

// CORRECT: remove Obx entirely
const Text('Static text')
```

---

### Anti-pattern 5 — optimistic update not rolled back on error

Every mutation that does a local-state optimistic update must restore it if
`error.value.isNotEmpty` after `await run(...)`:

```dart
Future<void> toggleStar() async {
  final prev = conversation.value.isStarred;
  conversation.value = conversation.value.copyWith(isStarred: !prev); // optimistic
  await run(() async { /* API call */ });
  if (error.value.isNotEmpty) {
    conversation.value = conversation.value.copyWith(isStarred: prev); // rollback
  }
}
```

---

### `velora_lints` enforcement

Anti-patterns 1 and 3 above are enforced by `packages/velora_lints`.
Add to any app that uses Velora:

```yaml
# pubspec.yaml dev_dependencies
custom_lint: ^0.6.0
velora_lints:
  path: ../../packages/velora_lints   # adjust path as needed
```

```yaml
# analysis_options.yaml
analyzer:
  plugins:
    - custom_lint
```

Run `flutter analyze` — violations surface as warnings/errors at the call site.

## Verification

Run focused checks for touched packages when code changes. Docs-only changes do not require analyze/test commands unless specifically requested.

```sh
flutter analyze packages/velora
flutter analyze examples/claude_clone
dart analyze packages/velora_cli
```
