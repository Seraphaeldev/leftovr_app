# leftovr — Windows setup guide

This folder contains the complete source for leftovr. Follow these steps on
your Windows laptop to build and install the app.

## What you need (one-time setup)

1. **Git for Windows** — https://git-scm.com/download/win
   (Flutter needs it, even if you never use Git directly.)
2. **Flutter SDK (stable channel)** —
   https://docs.flutter.dev/get-started/install/windows
3. **Visual Studio 2022** — https://visualstudio.microsoft.com/
   During installation, tick the workload **"Desktop development with C++"**.
   This supplies the compiler Flutter uses to produce a Windows `.exe`.
4. Windows 10 or 11, 64-bit.

## Verify the setup

Open a **new** Command Prompt or PowerShell (so PATH changes take effect) and
run:

```
flutter --version
flutter doctor -v
```

`flutter doctor` should show a checkmark for **Windows** and **Visual Studio**.
Fix any failing items before continuing.

## Build and install

1. Unzip this folder somewhere simple, for example
   `C:\Users\<you>\leftovr`.
2. Open Command Prompt and enter the folder:

```
cd /d C:\Users\<you>\leftovr
```

3. Run the build script:

```
build_windows.bat
```

4. When it finishes you will have:

```
build\leftovr-windows\        <- portable app folder
build\leftovr-windows.zip     <- ready-to-share archive
```

5. Extract `build\leftovr-windows.zip` anywhere and double-click
   **Run leftovr.bat**. That's it — no administrator rights required.

Your fridge data is stored under your Windows user profile and survives
restarts. Everything works offline: the three-pane workspace, keyboard quick
entry, recipe matcher and Markdown shopping-list export need no network.

A small CLI is included for expiry reports (same data the app uses):

```
dart run bin\expiry.dart
dart run bin\expiry.dart --json
```

## Optional: a real Start-menu installer

1. Install Inno Setup — https://jrsoftware.org/isinfo.php
2. From the project folder, run:

```
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows\installer.iss
```

3. The installer is written to `build\installer\leftovr-setup.exe`. Run it to
   install leftovr with a Start-menu entry and a proper uninstaller.

## If you'd rather not install Flutter / Visual Studio on the laptop

You can build on GitHub's Windows servers instead. See the "Run on Windows"
section of `README.md`: upload the source to a GitHub repo, run the
**Build Windows** workflow from the Actions tab, and download the finished zip.

## Troubleshooting

- **`flutter` is not recognized** — restart the terminal after installing
  Flutter and confirm `<flutter>\bin` is in your PATH.
- **Build fails mentioning MSVC or CMake** — re-run the Visual Studio installer
  and make sure **"Desktop development with C++"** is ticked, then reboot.
- **The app window is blank** — check that `data\flutter_assets` sits next to
  `leftovr.exe` in the extracted folder; if missing, re-run `build_windows.bat`.
