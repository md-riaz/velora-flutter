# velora_ui

Velora's token-first design system: theme and tokens plus components for display, form inputs, layout, navigation, and feedback/overlays. Depends only on `flutter`.

Not a plugin. Apply it through your app's theme: `MaterialApp(theme: VeloraTheme.light(), darkTheme: VeloraTheme.dark())`. The public surface is registered in `components.json`, which `tool/check_docs.sh` checks against the exports and the docs.

Requires Flutter >=3.47.0 / Dart >=3.13.0. Not published to pub.dev yet; use a git or path dependency.

Full guide: [`docs/packages/ui.md`](../../docs/packages/ui.md).
