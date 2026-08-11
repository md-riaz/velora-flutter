# velora_ui_gallery

A single-screen, scrollable gallery/showcase app for the `velora_ui` design
system. It renders every component from Layers 2-4 — buttons, cards, badges,
chips, alerts, empty states, skeletons, text fields, selects, checkboxes,
switches, radio groups, avatars, list tiles, section headers, dividers, and
progress indicators — with realistic, interactive examples.

**▶ Live demo:** <https://md-riaz.github.io/velora-flutter/gallery/>

The app bar has two toggles:

- **Light / dark** — a sun/moon `IconButton` that flips `ThemeMode`.
- **Aurora / Meadow** — an `IconButton` that cycles between `velora_ui`'s two
  built-in `VeloraThemePreset`s.

Both toggles rebuild the whole gallery through `buildVeloraTheme(...)`, so
every component's colors update live and you can compare all four
combinations (light/dark × aurora/meadow) without leaving the screen.

Interactive components — text fields, the select, the checkbox, the switch,
the radio group, and the tag chips — are wired to local widget state via
`setState`, so typing, selecting, checking, and toggling all actually work.

## Running

From this directory:

```sh
# This is a lib-only example — no platform folders are checked in.
# On a fresh checkout, generate them first:
flutter create .

flutter pub get
flutter run
```

It runs anywhere Flutter targets — web, desktop, or mobile. If your checkout
already has platform folders, skip the `flutter create .` step.

## Structure

- `lib/main.dart` — `GalleryApp` (theme/brightness/preset state) and
  `GalleryHomePage` (the app bar and scrollable body).
- `lib/sections/display_section.dart` — Layer 2: buttons, cards, badges,
  chips, alerts, empty state, skeletons.
- `lib/sections/inputs_section.dart` — Layer 3: text fields, select,
  checkbox, switch, radio group.
- `lib/sections/layout_section.dart` — Layer 4: avatars, list tiles, section
  header, dividers, progress.
- `test/gallery_smoke_test.dart` — a widget-test smoke suite covering
  rendering, the brightness toggle, the preset toggle, and one deep
  interactive control.
