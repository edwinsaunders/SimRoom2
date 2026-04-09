# Build Windows

This guide explains how to export a Windows build from the same shared Redot project.

Preferred export path:

```text
py tools/export.py windows --engine .\path\to\redot.exe --android-sdk .\android-sdk --verify-clean
```

This document keeps the platform-specific details and troubleshooting for what that wrapper is doing underneath.

Note: this repo commits an Android export preset, and this Redot build validates that preset during desktop export startup. That is why the wrapper examples include an Android SDK path even for Windows export.

You do not need a separate Windows project. This repo already commits a `Windows` export preset in [export_presets.cfg](/home/edwin/Documents/SimRoom/export_presets.cfg).

You can do this from either:

- a Linux host machine
- a Windows host machine

## Prerequisites

Shared requirements:

- compatible Redot editor/runtime
- Windows export templates installed for Redot

Linux-host-specific:

- local Linux Redot binary if you want to use [run.sh](/home/edwin/Documents/SimRoom/run.sh)

Windows-host-specific:

- local Windows Redot editor/runtime

## One-Time Setup

### 1. Enter the repo

```bash
cd /path/to/SimRoom
```

### 2. Linux host only: set up the local Redot binary

```bash
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
./run.sh --version
```

### 3. Confirm the project loads

Linux host:

```bash
./run.sh --headless --quit-after 120
```

Windows host:

- open the repo in Redot
- run the main scene from the editor if you want a quick sanity check

## Export Command

Create output folders:

```bash
mkdir -p build/windows build/logs
```

Linux host export:

```bash
./run.sh --headless --export-debug Windows build/windows/SimRoom.exe --log-file build/logs/windows-export.log
```

Windows host export:

- open the same shared project in Redot on Windows
- use the committed `Windows` export preset
- export to `build/windows/SimRoom.exe`

If your Windows Redot build supports CLI export, use the same `Windows` preset against this shared project.

## Output Location

Expected Windows export files:

- `build/windows/SimRoom.exe`
- `build/windows/SimRoom.console.exe`
- `build/windows/SimRoom.pck`

## Verification

### Confirm the main `.exe` exists

```bash
ls -la build/windows
```

### Confirm it is a PE executable

```bash
file build/windows/SimRoom.exe
```

Expected result includes `PE32+ executable`.

### Optional verification on Linux with Wine

If `wine` is installed on the machine, you can try launching:

```bash
wine build/windows/SimRoom.exe
```

If `wine` is not installed, export success plus file type verification is the practical check on Linux.

## What To Ship

Needed for normal distribution:

- `SimRoom.exe`
- `SimRoom.pck`

Optional:

- `SimRoom.console.exe`

The console executable is useful for debugging stdout/stderr but is not usually the one you hand to end users.

## Troubleshooting

### Export says Windows templates are missing

Check:

```bash
find .xdg_data/redot/export_templates -maxdepth 3 -type f | sort
```

You need Windows x86_64 export templates installed for the Redot version used by this repo.

On Windows hosts, check the Windows machine’s Redot template installation instead of the Linux repo-local `.xdg_*` path.

### Export completes but `.pck` is missing

This repo’s working export flow expects `SimRoom.pck` beside the `.exe`. If it is missing, re-run export and inspect:

```bash
sed -n '1,260p' build/logs/windows-export.log
```

### You are on Linux and want to verify more deeply

If `wine` is unavailable, stop at:

- successful export
- correct PE file type
- expected output files present
