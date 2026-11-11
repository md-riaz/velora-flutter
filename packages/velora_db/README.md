# velora_db

Reactive local database for Velora apps, built on drift: native and web (WASM SQLite), an Eloquent-style query API, and `watch*` reactive reads.

Wired as `Velora.boot(plugins: [VeloraDbPlugin()])`; `velora install velora_db` does this for you. Web needs two static assets — see the docs page.

Requires Flutter >=3.47.0 / Dart >=3.13.0. Not published to pub.dev yet; use a git or path dependency.

Full guide: [`docs/packages/db.md`](../../docs/packages/db.md).
