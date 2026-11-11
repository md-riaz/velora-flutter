# AI Ready

`velora new` writes an `.ai/` directory into the generated app. The files give an AI assistant the app's contract in a few short files:

| File | Written by | Contents |
|---|---|---|
| `.ai/project-context.md` | `velora new` | Entry points: `lib/main.dart`, `lib/app/routes`, `lib/app/modules`. |
| `.ai/architecture.md` | `velora new` | The `Page -> Controller -> Service -> Repository -> RemoteDataSource -> Velora.api` flow and what each layer may do. |
| `.ai/conventions.md` | `velora new` | Module directory layout and file naming. |
| `.ai/api-contract.md` | `velora new` | Default auth and RESTful CRUD endpoint shapes. |
| `.ai/module-map.json` | `velora new` | Modules and their routes. |
| `.ai/agent-rules.md` | `velora new` | Rules an assistant must follow when editing the app. |
| `.ai/tasks.md` | `velora new` | Suggested next tasks. |
| `.ai/notifications.md` | `velora new`, rewritten by `make:notifications` | Notification architecture, mock/noop mode, and the rule that Firebase/local-notification plugins stay out of views and controllers. |

The templates live in `packages/velora_cli/bin/velora_cli.dart`. They describe the generated app, not the framework: the architecture they summarize is the one in [Architecture](architecture.md), with plain constructor-injected services.

`velora new` also writes an `AGENTS.md` with a short managed section that tells an assistant to look components, docs, and commands up with the CLI instead of guessing. `velora make:agents` adds or refreshes that section in an existing app. See [Agent Tooling](agent-tooling.md).

Keep the files short, and update them when you add modules, API endpoints, permissions, or notification adapters. For framework-level context aimed at assistants, see `docs/llms.txt`.
