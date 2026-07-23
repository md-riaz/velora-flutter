# Vendored SQLite amalgamation

This directory vendors the official **SQLite amalgamation, version 3.53.3**,
downloaded from sqlite.org:

- Source: `https://sqlite.org/2026/sqlite-amalgamation-3530300.zip`
- SHA3-256: `d45c688a8cb23f68611a894a756a12d7eb6ab6e9e2468ca70adbeab3808b5ab9`
- License: public domain (see the header comments in `sqlite3.c` / `sqlite3.h`)

Files present:

- `sqlite3.c` — the single-file amalgamated SQLite implementation
- `sqlite3.h` — the public C API header
- `sqlite3ext.h` — the loadable-extension header

`shell.c` (the `sqlite3` CLI shell) was intentionally **not** vendored — it's
a standalone command-line program, not part of the library, and isn't needed
to build SQLite into a Dart/Flutter app.

## Why this is here

`package:sqlite3`'s Dart/Flutter build hook normally downloads a prebuilt
native SQLite binary from GitHub releases the first time a package is built.
That download is blocked in this repo's sandbox/CI environments, so instead
every package/example in this repo points the hook at this vendored source
file via its `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: source
      path: <relative path to>/third_party/sqlite3/sqlite3.c
```

With `source: source`, the hook compiles this exact, known copy of SQLite
from source on every build (sandbox, CI, and real device/desktop builds
alike), so builds are reproducible and work fully offline.

## How to update

1. Download the newer amalgamation zip from `https://sqlite.org/download.html`
   (e.g. `https://sqlite.org/<year>/sqlite-amalgamation-<version>.zip`).
2. Verify its SHA3-256 checksum against the value published on the SQLite
   download page.
3. Unzip it and replace `sqlite3.c`, `sqlite3.h`, and `sqlite3ext.h` in this
   directory (do not vendor `shell.c`).
4. Update the version number and SHA3-256 checksum recorded at the top of
   this README.
