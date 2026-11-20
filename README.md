# leftovr

A refined, **100% offline-first** desktop app for keeping track of what's inside
your fridge and what to cook next. No account, no network calls, no telemetry —
everything runs locally and works on a plane. Designed with a
philosophy: system greys, generous whitespace, hairline dividers, pill controls,
soft layered depth and subtle spring motion. The interface is strictly black and
white, with a matching monochrome tray logo on Linux and Windows. A short, quiet entrance
opens the app, and Bloc/Cubit state management keeps rebuilds fast and scoped.

## Run on Linux

The release build is already in the repo:

```bash
cd /path/to/leftovr
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

## Project architecture

leftovr is one Flutter desktop app with a deliberately small dependency surface:
no HTTP client, no database engine and no sync service. The Dart application is
shared by both platforms; `linux/` and `windows/` are thin native runner shells
that only host the Flutter engine, provide the window, and embed the icon.

### Layout

```
lib/
├── main.dart                 app entry; injects SharedPreferences, theme, screens
├── theme.dart                strict monochrome light/dark palettes and text styles
├── cubit/
│   └── fridge_cubit.dart     single source of truth: state, actions, persistence
├── models/                   pure data classes (no Flutter dependency)
│   ├── fridge_item.dart      inventory item, category, expiry status, JSON codec
│   ├── meal_plan.dart        planned meal: recipe id, servings, slot
│   └── recipe.dart           built-in catalog of ten recipes + ingredients
├── services/                 pure-Dart business logic, all local
│   ├── quick_entry.dart      natural-language quick-entry parser
│   ├── recipe_matcher.dart   scores recipes against current stock
│   ├── markdown_export.dart  aggregates demand, subtracts stock, renders Markdown
│   ├── inventory_file.dart   JSON mirror at ~/.leftovr/inventory.json
│   └── expiry.dart           expiry report shared by the app and the CLI
├── screens/
│   ├── splash_screen.dart    dot-matrix boot animation (tap to skip)
│   └── home_screen.dart      three-pane workspace + global keyboard shortcuts
└── widgets/
    ├── navigation_pane.dart  search, filters and category rail
    ├── quick_entry.dart      quick-entry bar with live preview
    ├── add_item_sheet.dart   full add/edit item dialog
    ├── planning_pane.dart    Recipes / Plan / List tabs
    └── decorations.dart      monochrome cards, badges, TrayMark artwork

bin/expiry.dart               standalone CLI entry point (dart compile exe)
scripts/leftovr-expiry.*      systemd service and daily timer units
arch/PKGBUILD, rebuild.sh     Arch package, wrapper launcher, compiled CLI
linux/, windows/              native runners, desktop entry, embedded icons
artwork/ → assets/            SVG sources → derived PNG/ICO assets
test/widget_test.dart         widget and logic regression tests
```

### Data flow

Widgets read from one `FridgeCubit` and call its methods; the cubit updates an
`Equatable` `FridgeState` and persists it. `BlocBuilder.buildWhen` keeps rebuilds
scoped to the slice of state each pane actually uses.

```
quick entry / add dialog ──► FridgeCubit ──► FridgeState ──► three panes
                                  │
                                  ├─► SharedPreferences   (canonical store)
                                  └─► ~/.leftovr/inventory.json  (mirror)
                                              │
                                              ▼
                                     bin/expiry.dart ──► CLI / systemd timer
```

Recipe matching and the shopping list are computed on demand from in-memory
state plus the built-in catalog; they are never cached to disk or fetched. The
offline boundary is visible in `pubspec.yaml`: the only runtime dependencies are
`shared_preferences`, `flutter_bloc`, `equatable` and `cupertino_icons`.

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
cd /path/to/leftovr
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

The Arch package installs a standalone `leftovr-expiry` CLI at `/opt/leftovr`;
the timer runs that local binary. From a source checkout without the package,
change `ExecStart` to `dart run <repo>/bin/expiry.dart`. Nothing leaves your
computer.

## Install on Arch / EndeavourOS

A prebuilt package is produced by `arch/rebuild.sh`:

```bash
cd /path/to/leftovr/arch
./rebuild.sh
sudo pacman -U ./leftovr-1.0.0-1-x86_64.pkg.tar.zst
```

<img width="1920" height="1080" alt="Screenshot_20261120_145134" src="https://github.com/user-attachments/assets/75b1a537-495a-4c0c-bbe3-32e6c7a710e2" />
<img width="1920" height="1080" alt="Screenshot_20261121_014312" src="https://github.com/user-attachments/assets/76b05e18-24cc-440a-ba3d-3ee93a8f9a53" />


## License

Apache License 2.0 — Copyright 2026 Seraphael. See `LICENSE`.
