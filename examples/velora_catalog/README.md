# velora_catalog

A network-first catalog/reader demo built on the Velora framework: a list of articles and a per-article reading view backed by `velora_db`'s `VeloraCachedRepository`.

## How it behaves

- **Network-first reads.** `CatalogController.load()` and `ArticleController.load()` each call the repository's `index()`/`show(id)` once per load; the (mock) remote API is always tried first.
- **Offline cache fallback.** `VeloraCachedRepository` refreshes a local `velora_db` table on every successful remote read. If the remote call fails with something that looks like "offline" (a connection error/timeout), the cached rows are served instead. A well-formed error that *did* reach the server (e.g. a 404) is rethrown as-is, never masked by stale cache data.
- **In-app connectivity toggle.** The `Switch` in the catalog page's app bar flips a `ToggleConnectivitySource` between online/offline so you can watch the fallback happen on demand, without touching real networking or airplane mode. Pull to refresh re-tries the network from either state.

See [`docs/examples.md`](../../docs/examples.md) for the full write-up of the pattern, including how it contrasts with `velora_chat`'s offline-first/reactive approach.

## Run it

```bash
cd examples/velora_catalog
flutter pub get
flutter run -d chrome   # or any connected device
```

## Test it

```bash
flutter test
```
