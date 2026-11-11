# velora_env

`.env` config and dev/staging/prod flavors for Velora apps, readable in `main()` before `Velora.boot()` runs.

Wired as `Velora.boot(plugins: [VeloraEnvPlugin()])`; `velora install velora_env` does this for you.

Requires Flutter >=3.47.0 / Dart >=3.13.0. Not published to pub.dev yet; use a git or path dependency.

Full guide: [`docs/packages/env.md`](../../docs/packages/env.md).
