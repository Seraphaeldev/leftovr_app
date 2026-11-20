# leftovr

A refined, **100% offline-first** desktop app for keeping track of what's inside
your fridge and what to cook next. No account, no network calls, no telemetry —
everything runs locally and works on a plane. Designed with an Apple-inspired
philosophy: system greys, generous whitespace, hairline dividers, pill controls,
soft layered depth and subtle spring motion. The interface is strictly black and
white, with a matching arch logo on Linux and Windows. A short, quiet entrance
opens the app, and Bloc/Cubit state management keeps rebuilds fast and scoped.

## Run on Linux

The release build is already in the repo:

```bash
cd /home/sandhyaps/vibe/projects/leftovr
./run_linux.sh
```

Or directly:

```bash
./build/linux/x64/release/bundle/leftovr
```

Development mode with hot reload:

```bash
flutter run -d linux
```

To rebuild after changing Dart code:

```bash
flutter build linux
```

Optional — register the app (with its icon) in your desktop menu:

```bash
cmake --install build/linux/x64/release --prefix ~/.local
```

## Run on Windows

Flutter cannot cross-compile a Windows binary from Linux, so the `.exe` has to
be built on Windows. There are two ways to get it.

### Option A — build in the cloud (no Windows PC needed)

`.github/workflows/build-windows.yml` builds and packages the app on a Windows
GitHub Actions runner:

1. Push this project to a GitHub repository.
2. Open the **Actions** tab → **Build Windows** → **Run workflow**.
3. When it finishes, download the `leftovr-windows` artifact and unzip it.

For a permanent download link instead of an expiring artifact, push a version
tag (e.g. `git tag v1.0.0 && git push origin v1.0.0`); the workflow also creates
a GitHub Release with the zip attached.

### Option B — build on a Windows PC

On a Windows machine with Flutter installed, double-click `build_windows.bat`.
It builds the release and produces:

- `build\leftovr-windows\` — portable folder
- `build\leftovr-windows.zip` — ready to share

Extract the zip anywhere and run **Run leftovr.bat**. No admin rights needed.

Requirements: Flutter SDK, Visual Studio 2022 with the **Desktop development
with C++** workload, and Windows 10/11.

Optional: compile `windows\installer.iss` with
[Inno Setup](https://jrsoftware.org/isinfo.php) to produce a Start-menu
installer with an uninstaller.

## Logo

The source artwork is `artwork/icon.svg`. Derived assets:

- `linux/assets/leftovr.png` — window icon + desktop entry icon
- `windows/runner/resources/app_icon.ico` — embedded Windows executable icon
- `web/icons/*`, `web/favicon.png` — web preview icons

## Features

- **100% offline-first native desktop app** — no network code, no account, no
  cloud sync; all data lives on your machine
- **Keyboard-driven smart quick-entry** — type `2 milk 3d`, `eggs x6 tomorrow`
  or `spinach exp 2026-12-01` and press Enter. Quantity, unit, use-by date and
  category are parsed locally, with a live preview before you commit.
- **Three-pane workspace** — navigation & filters on the left, inventory in the
  middle, recipe matching / meal planning / shopping list on the right
- **Offline recipe matcher** — a built-in catalog of ten recipes scored against
  what you actually have; see coverage and missing ingredients instantly
- **Markdown shopping list exports** — planned meals become a checked-off
  Markdown list of only the things you are missing, previewed in-app and copied
  to the clipboard
- **Zero-bloat expiry notifications** — a lightweight in-app timer plus a tiny
  CLI/systemd-timer report; no notification daemon or heavy dependencies
- Apple-inspired black-and-white interface: system greys, hairline dividers,
  pill controls, soft shadows and subtle spring motion
- Light and dark backgrounds: a toolbar toggle repaints the **entire** app
  between two strict monochrome palettes; the choice is saved between runs
- Dot-matrix boot animation: "leftovr" lights up one LED at a time in a rhythmic
  scan — tap to skip
- Add items with name, category, quantity, unit, use-by date and notes via the
  full dialog, or use quick entry for speed
- Search, freshness and category filters, plus sorting by expiry / name /
  quantity / category
- Changed items get a brief highlight in place — updates are easy to spot
  without rows reordering or flickering
- Expiry badges (Fresh / Soon / Outdated) and quantity steppers
- State managed with `flutter_bloc` / `equatable` via a single `FridgeCubit`;
  widgets rebuild only for the state slice they use (`BlocBuilder.buildWhen`)
- Local persistence via `shared_preferences`, seeded with sample items
- Responsive layout for wide and narrow windows

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl`/`⌘` + `K` | Focus the quick-entry field |
| `/` | Focus search |
| `Ctrl`/`⌘` + `N` | Open the full Add item dialog |
| `Ctrl`/`⌘` + `D` | Toggle light / dark |
| `Ctrl`/`⌘` + `/` | Show the shortcuts help |

## Quick-entry syntax

- `2 milk 3d` — quantity 2, use within 3 days
- `eggs x6 tomorrow` — six eggs, use tomorrow
- `spinach exp 2026-12-01` — explicit use-by date
- `leftover pasta 1d` — category is inferred from the name
- `bananas` — defaults to one, use within a week

## Expiry CLI and system timer

The app mirrors the inventory to `~/.leftovr/inventory.json` (override with
`LEFTOVR_DATA_DIR`). A dependency-free CLI reads it:

```bash
cd /home/sandhyaps/vibe/projects/leftovr
dart run bin/expiry.dart          # plain-text report
dart run bin/expiry.dart --json   # machine-readable
```

For a daily notification with systemd, install the two units from `scripts/`:

```bash
mkdir -p ~/.config/systemd/user
cp scripts/leftovr-expiry.* ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now leftovr-expiry.timer
```

The timer only runs the local Dart script — nothing leaves your computer.

## Install on Arch / EndeavourOS

A prebuilt package is produced by `arch/rebuild.sh`:

```bash
cd /home/sandhyaps/vibe/projects/leftovr/arch
./rebuild.sh
sudo pacman -U ./leftovr-1.0.0-1-x86_64.pkg.tar.zst
```
