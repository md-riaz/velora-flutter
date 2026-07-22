# Progressive Web App (PWA) & offline web

**What you'll do:** ship your Velora app as an installable, offline-capable web app — a production manifest via `velora make:pwa`, plus the integration story for offline data on web (`velora_db` + `velora_offline`) on top of what Flutter's web build already gives you for free.

---

## Flutter already gives you a PWA

`flutter build web` already emits the two files a PWA needs:

- **`manifest.json`** — makes the app installable ("Add to Home Screen" / desktop install prompt).
- **`flutter_service_worker.js`** — registered automatically by the Flutter bootstrap. It caches your app's build assets (JS, Dart-compiled wasm/JS, fonts, images) so a reload works with no network at all.

Any file you drop into `web/` before building is bundled into that build and cached by the same service worker — that includes a custom `manifest.json`, icons, or the `velora_db` WASM assets described below. You don't write or register a service worker yourself; Flutter's is already doing that job.

A handful of files are always served **no-cache** so a new deploy is picked up on the next load, rather than being served stale from a browser cache: `index.html`, `flutter_service_worker.js`, `flutter_bootstrap.js`, `manifest.json`, and `version.json`. Everything else (the actual app assets) is fingerprinted and safely long-cached.

## A production manifest with `velora make:pwa`

`flutter create`'s default `web/manifest.json` says `"name": "A new Flutter project"`, uses Flutter-blue colors, and locks `"orientation": "portrait-primary"` — fine for a demo, wrong for a real app (especially one that might run on a tablet or desktop browser).

From your app root (where `pubspec.yaml` lives), with a `web/` directory already present:

```bash
dart run velora_cli make:pwa
```

or, if `velora_cli` is activated globally:

```bash
velora make:pwa
```

This writes `web/manifest.json` with:

- Your app's real name and description, derived from `pubspec.yaml`.
- `"display": "standalone"` (no browser chrome once installed).
- `"orientation": "any"` — business apps run on tablets and desktop as often as portrait phones, so nothing is locked.
- Neutral background/theme colors instead of Flutter blue.
- The same four maskable/non-maskable icon entries `flutter create` already generated under `web/icons/`.

It also prints a short checklist (see below) so you know what's covered and what's still a manual step. You should still swap in your own icon set and colors — the generated manifest is a solid, real-app-shaped starting point, not a finished brand asset.

`make:pwa` must be run from the app root and requires a `web/` directory; if you haven't enabled web yet, run `flutter create --platforms web .` first.

## Offline data, not just the shell

A cached app shell alone gets you an installable app that *loads* offline — but without local data, the UI it shows is empty. Real offline support means the data your screens render has to live on the device too, not just the compiled Dart/JS.

On web, [`velora_db`](packages/db.md) runs SQLite compiled to WebAssembly, persisted in the browser via OPFS (or IndexedDB as a fallback) — this is your reactive local store, playing the same role IndexedDB/Dexie plays in a hand-built PWA. It needs two static assets in `web/`: **`sqlite3.wasm`** and **`drift_worker.dart.js`** (see [velora_db → Cross-platform](packages/db.md#cross-platform) for exactly where they come from). Once they're in `web/`, they're just more build assets — Flutter's service worker caches them like anything else, so the local database keeps working on a fully offline reload.

[`velora_offline`](packages/offline.md)'s `VeloraOfflineFirstRepository` is what turns that local store into an offline-first data layer: reads come from the local `VeloraTable` (`watchAll()` / `watchQuery(...)` / `watchFind(id)`, all reactive, so the UI stays live with zero network involved), and writes go to the local table first, then queue onto the same write-sync mechanism `velora_offline` ships, flushing to the server the next time connectivity returns.

Put together, three layers stack to make a fully offline, installable web app:

- **App shell** — Flutter's built-in service worker, caching the compiled app.
- **Local reactive data** — `velora_db`'s WASM-backed SQLite, caching (and serving) the data.
- **Write sync** — `velora_offline`'s outbox queue, syncing local writes back to the server.

Pulling *fresh* server data back into the local store (polling an endpoint or opening a websocket and upserting into the same `VeloraTable`) is still your app's job, same as on native — see [velora_offline → Offline-first](packages/offline.md#offline-first-reactive-local-store--write-sync).

## Testing offline

```bash
flutter build web
```

Serve the `build/web` directory over HTTPS (`localhost` is treated as a secure origin, so plain HTTP is fine for local testing). Then, in Chrome DevTools:

1. **Application → Service Workers** — confirm `flutter_service_worker.js` is registered and activated.
2. Check **Offline**, then reload the page — the app shell should load with no network requests.
3. Exercise any `velora_db`/`velora_offline`-backed screens — reads and writes should keep working locally.
4. Check the install affordance — the browser's install icon in the address bar, or **Application → Manifest** to confirm your `manifest.json` is picked up correctly (name, icons, `display: standalone`).

---

**See also:** [velora_offline →](packages/offline.md) for `VeloraOfflineFirstRepository` and the write-sync queue, [velora_db →](packages/db.md) for the Web WASM setup and `sqlite3.wasm` / `drift_worker.dart.js`, and [CLI Commands →](commands.md) for the full `velora_cli` command list.
