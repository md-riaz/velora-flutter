# Progressive Web App (PWA) & offline web

**What you'll do:** ship your Velora app as an installable, offline-capable web app — a production manifest via `velora make:pwa`, plus the integration story for offline data on web (`velora_db` + `velora_offline`) on top of what Flutter's web build already gives you for free.

---

## Flutter already gives you a PWA — almost

`flutter build web` emits **`manifest.json`**, which makes the app installable ("Add to Home Screen" / desktop install prompt). That part is automatic and free.

Offline app-shell caching is a different story. Flutter used to also register a default `flutter_service_worker.js` for you, but Flutter is **removing that default service worker** (flutter/flutter#156910) — `flutter.js` will stop installing any service worker at all. So, going forward, **offline caching of the app shell is not automatic**: without a service worker of your own, a reload with no network just fails. That's why `velora make:pwa` scaffolds one for you.

A handful of files are still always served **no-cache** by the Flutter web build so a new deploy is picked up on the next load, rather than being served stale from a browser cache: `index.html`, `flutter_bootstrap.js`, `manifest.json`, and `version.json`. Everything else (the actual app assets) is fingerprinted and safely long-cached — which is exactly what the service worker below is built to take advantage of.

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

- Your app's real name and description, derived from `pubspec.yaml` (built with `dart:convert`'s `JsonEncoder`, so special characters in either field can't produce invalid JSON).
- `"display": "standalone"` (no browser chrome once installed).
- `"orientation": "any"` — business apps run on tablets and desktop as often as portrait phones, so nothing is locked.
- Neutral background/theme colors instead of Flutter blue.
- The same four maskable/non-maskable icon entries `flutter create` already generated under `web/icons/`.

It also writes **`web/service_worker.js`** and registers it in `web/index.html` — since Flutter no longer ships a default service worker, this is what makes the app shell work offline. The caching strategy is deliberately simple:

- **Page navigations** — network-first: serve the fresh page when online (and cache it), fall back to the cached shell when offline.
- **Everything else same-origin** (`main.dart.js`, CanvasKit, fonts, and the `velora_db` WASM assets — `sqlite3.wasm` / `drift_worker.dart.js`) — stale-while-revalidate: serve instantly from cache, refresh the cache in the background.
- **Old caches** are deleted on `activate`, keyed off a `CACHE` version constant at the top of the file. Bump `CACHE` (e.g. `v1` → `v2`) whenever you want to force every client to discard the old cache on next load — useful if a deploy ever appears stale. That's a decision only you can make (Velora can't know when your deploy needs a hard refresh), so the constant is there for you to bump, not automated.

Registration in `index.html` is idempotent — running `make:pwa` again won't duplicate the `<script>` snippet or the cache-clearing logic.

It also prints a short checklist (see below) so you know what's covered and what's still a manual step. You should still swap in your own icon set and colors — the generated manifest is a solid, real-app-shaped starting point, not a finished brand asset. The service worker is a solid default too, but you still own cache-busting: bump `CACHE` yourself when you need to force a refresh, and customize the strategy if your app needs something different.

`make:pwa` must be run from the app root (it reads `pubspec.yaml` and `web/` from the current directory) and requires a `web/` directory; if you haven't enabled web yet, run `flutter create --platforms web .` first.

## Offline data, not just the shell

A cached app shell alone gets you an installable app that *loads* offline — but without local data, the UI it shows is empty. Real offline support means the data your screens render has to live on the device too, not just the compiled Dart/JS.

On web, [`velora_db`](packages/db.md) runs SQLite compiled to WebAssembly, persisted in the browser via OPFS (or IndexedDB as a fallback) — this is your reactive local store, playing the same role IndexedDB/Dexie plays in a hand-built PWA. It needs two static assets in `web/`: **`sqlite3.wasm`** and **`drift_worker.dart.js`** (see [velora_db → Cross-platform](packages/db.md#cross-platform) for exactly where they come from). Once they're in `web/`, they're just more build assets — the service worker `velora make:pwa` scaffolds (Velora's, not Flutter's — see above) caches them via its stale-while-revalidate rule like anything else, so the local database keeps working on a fully offline reload.

[`velora_offline`](packages/offline.md)'s `VeloraOfflineFirstRepository` is what turns that local store into an offline-first data layer: reads come from the local `VeloraTable` (`watchAll()` / `watchQuery(...)` / `watchFind(id)`, all reactive, so the UI stays live with zero network involved), and writes go to the local table first, then queue onto the same write-sync mechanism `velora_offline` ships, flushing to the server the next time connectivity returns.

Put together, three layers stack to make a fully offline, installable web app:

- **App shell** — the service worker `velora make:pwa` scaffolds, caching the compiled app.
- **Local reactive data** — `velora_db`'s WASM-backed SQLite, caching (and serving) the data.
- **Write sync** — `velora_offline`'s outbox queue, syncing local writes back to the server.

Pulling *fresh* server data back into the local store (polling an endpoint or opening a websocket and upserting into the same `VeloraTable`) is still your app's job, same as on native — see [velora_offline → Offline-first](packages/offline.md#offline-first-reactive-local-store--write-sync).

## Testing offline

```bash
flutter build web
```

Serve the `build/web` directory over HTTPS (`localhost` is treated as a secure origin, so plain HTTP is fine for local testing). Then, in Chrome DevTools:

1. **Application → Service Workers** — confirm `service_worker.js` is registered and activated.
2. Check **Offline**, then reload the page — the app shell should load with no network requests.
3. Exercise any `velora_db`/`velora_offline`-backed screens — reads and writes should keep working locally.
4. Check the install affordance — the browser's install icon in the address bar, or **Application → Manifest** to confirm your `manifest.json` is picked up correctly (name, icons, `display: standalone`).

---

**See also:** [velora_offline →](packages/offline.md) for `VeloraOfflineFirstRepository` and the write-sync queue, [velora_db →](packages/db.md) for the Web WASM setup and `sqlite3.wasm` / `drift_worker.dart.js`, and [CLI Commands →](commands.md) for the full `velora_cli` command list.
