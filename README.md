# apptricks

**One Windows app = one isolated Wine prefix.** Inspired by `winetricks`,
focused on per-application prefix isolation with a Windows-like
right-click GUI on Linux.

```text
<BASE>/.MyApp/      ← WINEPREFIX for MyApp
<BASE>/.OtherApp/   ← WINEPREFIX for OtherApp (never interfere)
```

No shared `~/.wine` breakage: each app gets its own `drive_c/`, registry,
and settings. Delete a prefix = fully uninstall that app.

## Features

- **CLI** — `apptricks list init install run cfg explorer uninstaller kill path`
- **Zenity GUI** — full menu, automatic prefix-name suggestions, zero extra deps
- **Dolphin right-click** — `Install to Prefix...` / `Run with Prefix...`
- **Portable import** — an exe outside any prefix is offered to be copied into
  `drive_c/Portable/` so it becomes self-contained
- **Launchers on demand** — after install/import, pick the location:
  app menu, Desktop, or both (never guessed paths, always your real exe)
- **Real exe icons** — extracted via `icoutils` when available (offered by setup)
- **No duplicate auto-entries** — after our launcher is made, Wine's own
  entries for the same app are offered for deletion via checklist
- **Portable base dir** — override via `$APPTRICKS_BASE` or
  `~/.config/apptricks/config`, sensible XDG default
- **No duplicate auto-entries** — Wine's `winemenubuilder` is disabled;
  launchers come only from apptricks (override: `WINEMENUBUILDER=1`)
- **`~/.wine` is never touched**, no `sudo` for wine operations

## Requirements

| Package | Needed for |
|---|---|
| `bash`, `wine` | prefix init/install (`list`/`help` work without wine) |
| `zenity` | GUI (CLI works without it) |
| KDE (`kbuildsycoca6/5`) | automatic menu refresh (optional) |

`setup.sh` detects your distro (`pacman`/`apt`/`dnf`/`zypper`) and offers to
install what's missing.

## Quick start

```bash
git clone git@github.com:4rmanjr/apptricks.git
cd apptricks
./setup.sh            # guided, 8 steps with progress
```

Options: `--yes` (non-interactive) · `--base DIR` (prefix location) ·
`--no-desktop` (skip Dolphin/menu integration) · `--skip-deps` · `--help`

Then either use the terminal:

```bash
apptricks init .MyApp
apptricks install .MyApp ~/Downloads/setup-myapp.exe
apptricks run .MyApp "<BASE>/.MyApp/drive_c/Program Files/MyApp/app.exe"
```

or right-click a `setup.exe` in Dolphin → **Install to Prefix...** —
pick an existing prefix or create a new one (name pre-suggested, editable),
the installer runs inside it, and you're offered a launcher afterwards.

## How the pieces fit

- `Install to Prefix...` = **put** an app into a prefix (runs the installer
  there, auto-`init` when new, offers a launcher when done).
- `Run with Prefix...` = **run** any exe under a prefix's environment
  (no install). Exes outside the prefix trigger the portable-import offer.
- Launchers are always built from an exe that is proven to exist —
  never from guessed paths.
- A nonzero installer exit code (e.g. 1) with the app working is **normal**
  under Wine — the GUI tells you so and still offers a launcher.
  Trace: `<prefix>/apptricks-install.log`.

## Configuration (`~/.config/apptricks/`)

- `config` — one line: `APPTRICKS_BASE="/path/to/prefixes"`
- `aliases` — custom GUI name suggestions, `pattern=name` per line
  (see `config/aliases.example`)

Base resolution order: `$APPTRICKS_BASE` → config file → XDG default
(`~/.local/share/apptricks/prefixes`).

## Uninstall

```bash
./uninstall.sh          # removes binaries + desktop integration (data kept)
./uninstall.sh --purge  # also removes config, aliases, and (if confirmed) prefixes
```

## Repo layout

```text
setup.sh uninstall.sh README.md LICENSE
bin/apptricks bin/apptricks-gui
share/kio/servicemenus/apptricks.desktop
share/applications/apptricks-gui.desktop
config/aliases.example
docs/AGENTS.md        # guide for AI/automation consumers
```

## License

MIT — see [LICENSE](LICENSE).
