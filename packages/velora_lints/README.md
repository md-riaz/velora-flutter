# velora_lints

`custom_lint` rules for Velora apps. They catch GetX reactivity mistakes that fail silently in release builds:

- `obx_missing_reactive_read` — an Rx object passed into an `Obx` child without a `.value` read.
- `obx_with_no_reads` — an `Obx` whose builder reads no observable.
- `rx_in_build_without_obx` — a `.value` read in `build()` outside `Obx`.
- `ever_in_widget_build` — `ever()` / `once()` / `debounce()` registered inside `build()`.

Setup and the reasoning behind each rule are in the repository's `AGENTS.md` (*GetX reactive patterns*). `custom_lint` still uses the legacy analyzer plugin API; see [`docs/toolchain.md`](../../docs/toolchain.md).
