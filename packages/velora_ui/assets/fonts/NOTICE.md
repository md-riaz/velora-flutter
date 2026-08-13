# Bundled fonts

velora_ui bundles two open-source variable fonts as its default brand faces.
Both are licensed under the **SIL Open Font License 1.1**; the full license
text for each accompanies the font here.

| Family | File | Role | Copyright | License |
|---|---|---|---|---|
| Space Grotesk | `SpaceGrotesk-Variable.ttf` | Display voice (display / headline / titleLarge) | © 2020 The Space Grotesk Project Authors (https://github.com/floriankarsten/space-grotesk) | `SpaceGrotesk-OFL.txt` |
| Inter | `Inter-Variable.ttf` | Body & label workhorse | © 2020 The Inter Project Authors (https://github.com/rsms/inter) | `Inter-OFL.txt` |

Both are **variable** fonts, so a single file covers every weight the Velora
type scale requests. They are referenced from `buildVeloraTheme` with the
`packages/velora_ui/` prefix Flutter requires for package-provided fonts, and
apps can override them via the `fontFamily` / `displayFontFamily` parameters.
