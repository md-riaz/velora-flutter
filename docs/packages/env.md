# velora_env

**What you'll do:** Install `velora_env`, load `.env` assets before `Velora.boot()`, build per-flavor config (dev/staging/prod) from it, and read typed values anywhere in your app.

---

## What it does

`velora_env` is a Laravel-style environment/config facade for Velora apps: `.env`-style asset files, parsed into typed values, with a base + flavor merge convention. Unlike most official packages, its primary API — the static **`VeloraEnv`** class — doesn't need `Velora.boot()` to have run at all:

- **`VeloraEnv`** — a plain static holder. `VeloraEnv.load()` can run directly in `main()`, *before* `Velora.boot()`, so its values are available to build `VeloraConfig` itself (e.g. `apiBaseUrl: VeloraEnv.require('API_BASE_URL')`).
- **`VeloraEnvironment`** — the `dev` / `staging` / `prod` enum, resolved from the `VELORA_ENV` compile-time define (`--dart-define=VELORA_ENV=staging`), defaulting to `dev`.
- **`VeloraEnvPlugin`** — an optional [Velora plugin](../plugins.md) that registers a `VeloraEnvService` for DI/introspection (e.g. `Get.find<VeloraEnvService>()` in a widget test). Most apps don't need it — see [Boot](#boot) below.

It also ships a small, dependency-free `.env` parser supporting comments, `export KEY=VALUE`, and single/double-quoted values (with backslash escapes inside double quotes).

## Install

```yaml
dependencies:
  velora_env:
    path: packages/velora_env # or the pub.dev version once published
```

Or let the CLI do it:

```bash
velora install velora_env
```

This adds the dependency, adds the import, and wires `VeloraEnvPlugin()` into your `Velora.boot(plugins: [...])` call. But because `VeloraEnv` is a static facade, wiring the plugin is only half the setup — you still need to:

1. Create your env files under `assets/env/`: a shared base `assets/env/.env`, plus optional per-flavor overrides `assets/env/.env.staging` / `assets/env/.env.production` (missing files are tolerated — nothing throws if one flavor has no override).
2. Declare that directory as a Flutter asset in `pubspec.yaml`:

   ```yaml
   flutter:
     assets:
       - assets/env/
   ```
3. Call `VeloraEnv.load()` yourself, early in `main()` — the plugin does not replace this if you need env values to build `VeloraConfig` (see [Boot](#boot)).
4. Select the active flavor at build/run time:

   ```bash
   flutter run --dart-define=VELORA_ENV=staging
   ```

   Accepted values are `dev` (the default), `staging`, and `prod` — see `VeloraEnvironment.parse` for aliases like `development`/`production`.

## Boot

The important detail: **`VeloraEnv.load()` runs *before* `Velora.boot()`**, so its values are available while building `VeloraConfig` itself:

```dart
import 'package:flutter/material.dart';
import 'package:velora/velora.dart';
import 'package:velora_env/velora_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VeloraEnv.load();

  await Velora.boot(
    config: VeloraConfig(
      appName: 'My App',
      apiBaseUrl: VeloraEnv.require('API_BASE_URL'),
    ),
    plugins: [
      // Optional: only needed for DI/introspection (Get.find<VeloraEnvService>()).
      VeloraEnvPlugin(),
    ],
  );
}
```

`VeloraEnvPlugin()` (what `velora install velora_env` wires in) defaults `loadIfNeeded: true`, so if nothing called `VeloraEnv.load()` earlier it loads during `register()` as a safety net — but for config that has to shape `VeloraConfig` itself, call `VeloraEnv.load()` explicitly before `Velora.boot(...)` as shown above, since the plugin only registers *after* `VeloraConfig` is already built.

## Usage

Read values anywhere via the static facade — no injection required:

```dart
import 'package:velora_env/velora_env.dart';

final apiKey = VeloraEnv.get('ANALYTICS_KEY');            // String?, null if absent
final region = VeloraEnv.get('REGION', fallback: 'us');   // String, with a default
final secret = VeloraEnv.require('API_BASE_URL');         // throws StateError if missing/empty

final debugMode = VeloraEnv.getBool('DEBUG_MODE');        // true/1/yes/on (case-insensitive)
final retries = VeloraEnv.getInt('MAX_RETRIES', fallback: 3);
final threshold = VeloraEnv.getDouble('SYNC_THRESHOLD');

if (VeloraEnv.has('SENTRY_DSN')) { /* ... */ }
```

Pick a value per flavor without a manual `switch` on `VeloraEnv.current`:

```dart
final apiBaseUrl = VeloraEnv.pick(
  dev: 'http://localhost:8000/api',
  staging: 'https://staging.example.com/api',
  prod: 'https://api.example.com/api',
);
```

`pick` (and `pickFor`) fall back to `dev` when `staging`/`prod` isn't supplied — so you only need to override the flavors that actually differ.

## Flavors

`VeloraEnv.current` resolves `VeloraEnvironment` from `--dart-define=VELORA_ENV=...`, defaulting to `dev`. `VeloraEnv.isDev` / `isStaging` / `isProd` are shorthand checks. `VeloraEnv.load()` merges two files, in order:

1. `assets/env/.env` — the shared base, loaded first (if present).
2. `assets/env/.env.<flavor>` — an override for the current flavor (`dev`, `staging`, or `prod`), whose keys win over the base file's.

```dotenv title="assets/env/.env"
APP_NAME=My App
API_BASE_URL=http://localhost:8000/api
```

```dotenv title="assets/env/.env.production"
API_BASE_URL=https://api.example.com/api
```

Running with `--dart-define=VELORA_ENV=prod` yields `APP_NAME=My App` (from the base) and `API_BASE_URL=https://api.example.com/api` (overridden by the flavor file).

## Security note

`.env` files loaded through `velora_env` are bundled into the app as Flutter assets — they ship inside the APK/IPA and can be extracted by anyone with the installed binary. Use `.env` for **configuration and flavor switching** (API base URLs, feature flags, environment labels), **never for secrets** (API keys with real privileges, private credentials). Ship real secrets from your backend, a secrets manager, or platform-level secure storage instead.

## Testing without assets

`VeloraEnv` never requires a running Flutter asset bundle in tests — load values directly:

```dart
setUp(() {
  VeloraEnv.reset(); // clear state left over from a previous test
});

test('reads a required key', () {
  VeloraEnv.loadFromString('''
API_BASE_URL=https://api.example.com/api
DEBUG_MODE=true
''');

  expect(VeloraEnv.require('API_BASE_URL'), 'https://api.example.com/api');
  expect(VeloraEnv.getBool('DEBUG_MODE'), isTrue);
});

test('reads from a pre-built map', () {
  VeloraEnv.loadFromMap({'REGION': 'eu'});
  expect(VeloraEnv.get('REGION'), 'eu');
});
```

If you need to exercise the real asset-loading path (`VeloraEnv.load()`), inject a fake `AssetBundle` — `VeloraEnv.load(bundle: myFakeBundle)` and `VeloraEnvPlugin(bundle: myFakeBundle)` both accept one for exactly this.

---

**See also:** [Plugins →](../plugins.md) for the `VeloraPlugin` / `VeloraContext` contract `VeloraEnvPlugin` implements, and [velora_db →](db.md) for another official package built on the same contract.
