# Noto Sans Mono Ligaturized

Noto Sans Mono patched with Fira Code ligatures via Ligaturizer.

![Ligaturized font in Ghostty. Theme: Dracula+](documentation/screenshot-ghostty.png)

## Setup

Install the ligaturized fonts from `fonts/` using your OS font manager.

### VS Code

In VS Code, press `Cmd` + `Shift` + `P`, search for
`Preferences: Open User Settings (JSON)`. In the opened `settings.json`,
set font family to `Liga Noto Sans Mono` and enable ligatures:

```json
"editor.fontFamily": "'Liga Noto Sans Mono', monospace",
"editor.fontLigatures": "'calt', 'liga'",
"terminal.integrated.fontFamily": "'Liga Noto Sans Mono', monospace",
"terminal.integrated.fontLigatures.enabled": true,
```

### Ghostty

Open Ghostty settings (`Cmd` + `,`) and set font family to `Liga Noto Sans Mono`:

```ini
font-family = Liga Noto Sans Mono
```

Press `Cmd` + `Shift` + `,` to reload the terminal with the new configuration.

## Build

Run `make` in the repository root on macOS with git and Homebrew.

The Makefile will:

- Download Noto Sans Mono OTFs into `noto-sans-mono/` (or reuse local copies).
- Clone Ligaturizer (plus only the `fonts/fira` submodule).
- Patch Ligaturizer options to target Noto Sans Mono and drop selected ligatures.
- Run the Ligaturizer build.
- Copy the ligaturized Noto Sans Mono font files into `fonts/`.
- Remove the cloned Ligaturizer checkout.

### Dropped ligatures

These ligatures from Fira Code are intentionally omitted:

`&&`, `~@`, `\/`, `.?`, `?:`, `?=`, `?.`, `??`, `;;`, `/\`

### Output

Ligaturized fonts land in `fonts/`:

Noto Sans Mono has no italic style; only these four weights are built:

- `LigaNotoSansMono-Light.otf`
- `LigaNotoSansMono-Regular.otf`
- `LigaNotoSansMono-Medium.otf`
- `LigaNotoSansMono-Bold.otf`
