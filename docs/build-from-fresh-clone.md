# Build From Fresh Clone

This guide is the starting point for building or exporting this repository on a machine that has never seen it before.

This repo uses one shared Redot project for all targets:

- Linux desktop
- Windows desktop
- Android APK

There are not separate per-platform projects.

## Fresh Clone To First Successful Export

Use this checklist in order:

1. Install `git`, `ssh`, and a compatible Redot editor/runtime.
2. Clone the repo and enter it.
3. Confirm you are on `main` and the working tree is clean.
4. If you are on Linux and want to use the provided launcher, place a local Redot binary at `./redot.linuxbsd.editor.x86_64`.
5. Install Redot export templates for the targets you need into the repo-local portable template path.
6. Run a quick headless smoke test.
7. Export Linux and/or Windows using the committed presets.
8. If building Android, install Java 17 and the Android SDK locally for that machine, then follow the Android build guide.

## Host Platform Notes

You can work from either Linux or Windows.

- Linux host:
  - use [run.sh](/home/edwin/Documents/SimRoom/run.sh)
  - `run.sh` sets repo-local `HOME` and `XDG_*` paths
  - place a Linux Redot binary at `./redot.linuxbsd.editor.x86_64`
- Windows host:
  - `run.sh` does not apply
  - open the same shared project in a local Windows Redot editor/runtime
  - Redot editor settings, templates, and Android SDK/JDK config are machine-local on Windows too, but they live in normal Windows user directories instead of the repo-local `.xdg_*` folders

## Machine Setup Matrix

| Target | Linux host | Windows host | Main output |
| --- | --- | --- | --- |
| Linux | `git`, `ssh`, Linux Redot editor/runtime, Linux export templates | Redot for Windows, Linux export templates if the Windows Redot build supports Linux export | `build/linux/SimRoom.x86_64` |
| Windows | `git`, `ssh`, Linux Redot editor/runtime, Windows export templates | Redot for Windows, Windows export templates | `build/windows/SimRoom.exe` |
| Android | Linux Redot editor/runtime, Java 17, Android SDK cmdline tools, Android platform/build-tools | Redot for Windows, Java 17, Android SDK, Android platform/build-tools | `build/android/SimRoom-debug.apk` |

## What Is Committed Vs Generated Locally

Committed source/config:

- `project.godot`
- `export_presets.cfg`
- `scenes/`
- `scripts/`
- `platform/android/`
- `docs/`
- tracked script `.uid` files

Generated or machine-local:

- `build/`
- `.godot/`
- `.xdg_data/`
- `.xdg_config/`
- `.xdg_cache/`
- `android-sdk/`
- `android-home/`
- local Redot binary and zip archives
- APKs, AABs, PCKs, temporary files

That means a fresh clone gives you the project source and presets, but not:

- the Redot executable
- export templates
- Android SDK
- Java SDK configuration
- editor cache/config

## Prerequisites

Minimum for any machine:

- `git`
- `ssh`
- a Redot editor/runtime compatible with this project

Needed only for Android:

- Java 17
- Android SDK command-line tools
- Android platform `android-35`
- Android build-tools `35.0.1`
- `keytool`

Useful verification:

```bash
git --version
ssh -V
```

## One-Time Setup On A Fresh Machine

### 1. Clone the repo

```bash
git clone git@github.com:edwinsaunders/SimRoom.git
cd SimRoom
```

### 2. Check branch and status

```bash
git branch -vv
git status --short --branch
git remote -v
```

Expected baseline:

- branch is `main`
- `origin` points to GitHub
- working tree is clean

### 3. Pull the latest changes

```bash
git fetch origin
git pull --rebase origin main
```

### 4. Check submodules

This repo currently has no submodules.

```bash
git submodule status
```

No output is expected.

### 5. Set up Redot on this machine

This repo does not commit the Redot executable.

On Linux, if you want to use the provided launcher, place a compatible Linux Redot editor/runtime binary at:

```text
./redot.linuxbsd.editor.x86_64
```

Then:

```bash
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
```

`run.sh` is Linux-specific and intentionally sets repo-local:

- `HOME`
- `XDG_DATA_HOME`
- `XDG_CONFIG_HOME`
- `XDG_CACHE_HOME`

That keeps Redot state inside the repo folder and out of your normal home directory.

On Windows, use a local Redot editor/runtime installation and open:

```text
project.godot
```

or open the repo folder in the Redot project manager.

### 6. Install export templates

The export presets are committed in [export_presets.cfg](/home/edwin/Documents/SimRoom/export_presets.cfg), but export templates are local to each machine.

On Linux, because `run.sh` uses repo-local XDG folders, the template path used by this repo is:

```text
.xdg_data/redot/export_templates/26.1.stable/
```

On Windows, install the matching Redot export templates through that machine’s normal Redot template location.

Required templates depend on the target:

- Linux: `linux_debug.x86_64`, `linux_release.x86_64`
- Windows: `windows_debug_x86_64.exe`, `windows_release_x86_64.exe`
- Android: `android_debug.apk`, `android_release.apk`, `android_source.zip`

If your Redot template installer places files under a nested `templates/` directory, the repo has previously been used with symlinks or direct files at the `26.1.stable/` level. Verify what your Redot build expects before exporting.

## Project-Specific Setup

### Run a smoke test after setup

Linux host:

```bash
./run.sh --headless --quit-after 120
```

Expected result:

- Redot starts
- `SimRoom ready` appears
- process exits cleanly

Windows host:

- open the shared project in Redot
- run the main scene from the editor
- or use that machine’s Redot executable in headless mode if you prefer CLI export/test flow

### Use the committed presets

This repo already commits presets named:

- `Linux`
- `Windows`
- `Android`

You do not need to create separate projects per platform.

## Platform Guides

- [build-linux.md](/home/edwin/Documents/SimRoom/docs/build-linux.md)
- [build-windows.md](/home/edwin/Documents/SimRoom/docs/build-windows.md)
- [build-android.md](/home/edwin/Documents/SimRoom/docs/build-android.md)

## Common Troubleshooting

### `./run.sh` fails because `redot.linuxbsd.editor.x86_64` is missing

The repo intentionally does not commit the Redot executable. Put a compatible Redot binary at the repo root and mark it executable.

If you are on Windows, ignore `run.sh` and use your Windows Redot installation directly.

### Export says templates are missing

Check the repo-local portable template directory:

```bash
find .xdg_data/redot/export_templates -maxdepth 3 -type f | sort
```

If it is empty or missing the needed template files, install the export templates on that machine.

### Android build fails on a fresh machine

That is usually one of:

- Java 17 missing
- Android SDK missing
- `platform-tools` missing
- `build-tools` version mismatch
- debug keystore missing

Follow the Android-specific guide instead of guessing.
