# Plugins

**What you'll do:** Understand Velora's modular ecosystem model, author a `VeloraPlugin`, and register it via `Velora.boot(plugins: [...])`.

---

## The model: lean core, official packages

Velora's core (`package:velora`) stays deliberately small — auth, API client, permissions, notifications, storage, routing. Everything else is meant to ship as its own package: `velora_offline`, `velora_analytics`, `velora_chat`, or whatever your app needs — installed from `pub.dev` and wired in at boot, the same way a Laravel app pulls in a Composer package and publishes its service provider.

You've already seen this philosophy in a few places:

- **`PushAdapter`** — swap in `FcmPushAdapter` or your own provider without touching `NotificationService`.
- **`VeloraUploadAdapter`** — plug in S3, Cloudinary, or a local disk adapter for media uploads.
- **`VeloraApiInterceptor`** — add logging, retries, or auth refresh to the shared Dio client.

`VeloraPlugin` generalizes this: instead of one extension point per subsystem, a plugin gets a single hook — `register(VeloraContext)` — that runs after all core services are wired, and from there can register its own services, add interceptors, and hook into logout, all through one typed surface.

## Authoring a plugin

Implement `VeloraPlugin`:

```dart
import 'package:velora/velora.dart';

class OfflinePlugin extends VeloraPlugin {
  const OfflinePlugin();

  @override
  String get name => 'velora_offline';

  @override
  Future<void> register(VeloraContext context) async {
    final queue = OfflineQueueService();
    context.put<OfflineQueueService>(queue);

    // Intercept requests to enqueue them when offline.
    context.addInterceptor(OfflineQueueInterceptor(queue));

    // Flush any pending user-scoped state on logout.
    context.onBeforeLogout(() async {
      await queue.clearUserScope();
    });
  }
}
```

## `VeloraContext` API

`register` receives a `VeloraContext`, the only surface a plugin needs — it never touches GetX or `Velora.*` directly:

| Method | Purpose |
|---|---|
| `context.config` | The `VeloraConfig` passed to `boot()`. |
| `context.put<T>(dependency)` | Register a permanent singleton, resolvable elsewhere via `Get.find<T>()` or your own facade getter. |
| `context.find<T>()` / `context.isRegistered<T>()` | Resolve or probe for a dependency (yours or core's). |
| `context.addInterceptor(interceptor)` | Add a `VeloraApiInterceptor` to the shared API client, after the built-in auth injector and any interceptors passed to `boot()`. |
| `context.onLogout(participant)` | Register a `VeloraLogoutAware` participant with the logout lifecycle registry. |
| `context.onBeforeLogout(hook)` | Shorthand for a `beforeLogout`-only hook — the common case (clear caches, cancel timers). |
| `context.configExtension<T>()` | Retrieve a typed `VeloraConfigExtension` the app registered on `VeloraConfig.extensions`, so your plugin can read its own config without a bespoke parameter on `boot()`. |

## Registering plugins

Pass instances to `Velora.boot`:

```dart
await Velora.boot(
  config: myConfig,
  plugins: [
    const OfflinePlugin(),
    const AnalyticsPlugin(apiKey: 'xyz'),
  ],
);
```

Plugins register in list order, after every core service (auth, API, storage, notifications, media, etc.) is already available — so a plugin's `register` can safely call `context.find<VeloraApiService>()` or any other core service.

## Introspection

```dart
Velora.plugins;                    // List<VeloraPlugin> — all registered, in order
Velora.plugin<OfflinePlugin>();    // OfflinePlugin? — typed lookup, or null if absent
```

This lets shared UI (e.g. a settings screen) conditionally show plugin-specific sections without a hard dependency on the plugin package.

## The first official package

[`velora_offline`](packages/offline.md) is the reference implementation of this contract — connectivity awareness plus an offline write queue, installed as `plugins: [VeloraOfflinePlugin()]`. Read it alongside this page as a worked example of everything above.

---

**See also:** [API Client →](api-client.md) for `VeloraApiInterceptor`, [Framework / App Boundary →](framework-app-boundary.md) for how core and app-owned code stay decoupled, and [velora_offline →](packages/offline.md) for a real plugin built on this contract.
