# Agent Tooling

The CLI answers questions about Velora from the packages a project has installed, so a developer, a coding agent, and a CI job all read the same facts. Nothing here calls a model or edits application code.

| Command | Answers from |
|---|---|
| `velora search <query>` | The installed `velora_ui`, plus the CLI's command, package, and docs registries. |
| `velora component [<name>]` | The installed `velora_ui`: `components.json` and the declaring source file. |
| `velora docs [<topic>]` | The `docs/` directory of the checkout the project's Velora packages come from. |
| `velora manifest` | The CLI's own registries. |
| `velora make:agents` | Writes the managed section below into `AGENTS.md`. |

Run them from the app directory (or any directory below it), after `flutter pub get`. `velora new` adds `velora_cli` to the app's `dev_dependencies`, so `dart run velora_cli <command>` works from the app root and resolves the same checkout as the app's other Velora packages. An app created before this needs that dev dependency added by hand.

## Version authority

The project's `.dart_tool/package_config.json` decides which package directories are read. `velora component VeloraButton` in an app pinned to an older `velora_ui` prints that version's constructor, because it parses that version's source file.

- Outside a project, `component` fails with `ERR_PROJECT_REQUIRED`. `search` still covers commands, packages, and docs topics and reports that components were left out. `manifest` reports a `null` component count.
- A project without `velora_ui` gets `ERR_PACKAGE_NOT_INSTALLED` from `component`.
- `docs <topic>` prints the page only when the installed packages carry `docs/`, which path and git dependencies do. For a package without it, the command prints the online URL and says that the online page describes the latest version.

## `velora search`

```bash
velora search data-table
velora search offline --type package,docs --limit 5
velora search buton --json
```

`--type` takes one or more of `component`, `docs`, `package`, `command`, comma-separated. `--limit` defaults to 10. Matching ignores case, punctuation, and a leading `Velora`; a name match outranks a description match, and a near miss is returned with `reason: "similar name"`.

## `velora component`

```bash
velora component                      # list every export by layer
velora component VeloraDataTable      # full description
velora component datatable --detail brief
velora component VeloraButton --source
velora component VeloraButton --json
```

The description is read from the Dart source: the doc comment, each public constructor with its parameters (type, required, default, and the field's doc comment), static methods such as `VeloraDialog.show`, enum values, and extension members. `--detail brief` leaves out the long description and per-parameter docs. `--source` prints the path of the declaring file.

The scanner covers the declaration shapes `velora_ui` uses. A parameter type it cannot read is reported as `null` rather than guessed; a test fails if that happens for any registered component.

Not included yet: theme tokens used, accessibility and keyboard notes as structured fields, stability levels, and runnable examples. Those facts are in the doc comments and in [velora_ui](packages/ui.md).

## `velora docs`

`velora docs` lists the topics; `velora docs <topic>` prints the page.

<!-- generated:docs-topics source=packages/velora_cli/lib/src/discovery.dart — do not edit; run tool/check_docs.sh --write -->
| Topic | Page |
|---|---|
| `getting-started` | [Install and boot](getting-started.md) |
| `architecture` | [Architecture, state ownership, and GetX](architecture.md) |
| `boundary` | [Framework / app boundary](framework-app-boundary.md) |
| `auth` | [Auth and logout safety](auth.md) |
| `api-client` | [API client](api-client.md) |
| `permissions` | [Permissions](permissions.md) |
| `notifications` | [Notifications](notifications.md) |
| `scaffolding` | [Generated modules](scaffolding.md) |
| `plugins` | [Plugins and package authoring](plugins.md) |
| `pwa` | [Web and PWA](pwa.md) |
| `offline` | [Offline data](packages/offline.md) |
| `db` | [Local database](packages/db.md) |
| `env` | [Environment config](packages/env.md) |
| `ui` | [Theming, components, accessibility, and responsive layout](packages/ui.md) |
| `commands` | [CLI commands](commands.md) |
| `agents` | [Agent tooling and JSON contracts](agent-tooling.md) |
| `desktop` | [Desktop lifecycle: close-to-tray, single instance, auto-start](packages/desktop.md) |
| `toolchain` | [Toolchain baseline](toolchain.md) |
<!-- /generated:docs-topics -->

## `velora manifest`

`velora manifest --json` lists the commands (and which accept `--json`), installable packages, docs topics, output types, error codes, the JSON `apiVersion`, and the minimum Flutter and Dart versions.

## JSON output

`search`, `component`, `docs`, and `manifest` accept `--json` and print one envelope on stdout:

```json
{
  "apiVersion": 1,
  "type": "component.detail",
  "data": {},
  "meta": {
    "answeredBy": {
      "cli": "0.0.1",
      "project": true,
      "packages": {"velora_ui": "0.0.1"}
    }
  }
}
```

- `type` is one of `manifest`, `search.results`, `component.list`, `component.detail`, `docs.list`, `docs.page`.
- `meta.answeredBy.packages` holds the resolved version of each Velora package in the project. `project` is `false` when the command ran outside one.
- `apiVersion` changes only for a breaking change to the envelope or a `data` shape. Fields may be added without a bump.

A failure exits with code 64 and, under `--json`, prints:

```json
{
  "apiVersion": 1,
  "error": "No component named VeloraDatTable in velora_ui 0.0.1",
  "code": "ERR_UNKNOWN_COMPONENT",
  "suggestions": [{"name": "VeloraDataTable", "reason": "similar name"}]
}
```

Branch on `code`. The `error` text can change between releases.

<!-- generated:error-codes source=packages/velora_cli/lib/src/discovery.dart — do not edit; run tool/check_docs.sh --write -->
| Code | Reported when |
|---|---|
| `ERR_UNKNOWN_COMMAND` | The first argument is not a Velora command. |
| `ERR_UNKNOWN_COMPONENT` | No `velora_ui` export has that name in the installed version. |
| `ERR_UNKNOWN_DOCS_TOPIC` | No documentation topic has that id. |
| `ERR_INVALID_ARGUMENT` | A required argument is missing, or an option or its value is not accepted. |
| `ERR_PROJECT_REQUIRED` | The command needs a resolved Dart project: a `pubspec.yaml` and `.dart_tool/package_config.json` in the current directory or a parent. |
| `ERR_PACKAGE_NOT_INSTALLED` | The project does not resolve the package the answer comes from. |
| `ERR_INVALID_REGISTRY` | The installed package's registry or a registered source file is missing or malformed. |
<!-- /generated:error-codes -->

The scaffolding commands (`new`, `make:*`, `install`, `doctor`) do not take `--json` and report failures as plain text.

## The managed `AGENTS.md` section

`velora new` writes an `AGENTS.md` with this section, and `velora make:agents` adds it to an existing file or refreshes it. Only the text between the two markers is replaced; everything else in the file is left as it is. `velora doctor` warns when the section differs from what the installed CLI writes.

The section points at the lookup commands instead of listing components, so it stays correct across upgrades.

<!-- generated:agents-section source=packages/velora_cli/lib/src/discovery.dart — do not edit; run tool/check_docs.sh --write -->
````markdown
<!-- velora:agents:start -->
## Velora

This app uses Velora. Look things up from the installed version instead of guessing:

- `dart run velora_cli search <query>` finds components, docs, packages, and commands. Search before writing a new widget.
- `dart run velora_cli component <Name>` prints a component's constructor parameters and docs. Read it before using an unfamiliar API; do not guess parameters.
- `dart run velora_cli docs <topic>` prints a guide. Read `architecture` and `boundary` before moving code between layers.
- `dart run velora_cli doctor` checks wiring and the SDK baseline.
- Add `--json` to `search`, `component`, `docs`, or `manifest` for a versioned envelope. Branch on the error `code`, not the message.

Rules:

- Domain models, routes, endpoints, permissions, copy, and brand stay in the app.
- `velora_ui` components are controlled: the caller owns values and callbacks.
- UI permission checks are not backend authorization.
- No secrets in this file or in `.ai/`.
- After a change run `dart format .`, `flutter analyze`, and the tests for what you touched.
<!-- velora:agents:end -->
````
<!-- /generated:agents-section -->

`make:agents` writes `AGENTS.md` only. Other agent instruction files are not managed.
