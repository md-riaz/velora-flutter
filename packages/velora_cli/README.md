# velora_cli

Scaffolding CLI for Velora apps: creates apps and modules, installs official packages, and checks a project's setup.

```sh
dart run velora_cli help
```

Commands and installable packages are defined once, in `veloraCommands` and `veloraPackageCatalog` (`lib/velora_cli.dart`). `velora help` and the tables in [`docs/commands.md`](../../docs/commands.md) are both generated from them; run `tool/check_docs.sh --write` from the repository root after changing either.

Requires Dart >=3.13.0. See [`docs/scaffolding.md`](../../docs/scaffolding.md) for what each generator writes.
