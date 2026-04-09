# Build Linux

This guide explains how to run the project and export a Linux desktop build from a fresh clone.

Preferred export path:

```bash
python3 tools/export.py linux \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

This document keeps the platform-specific details and troubleshooting for what that wrapper is doing underneath.

Note: this repo commits an Android export preset, and this Redot build validates that preset during desktop export startup. That is why the wrapper examples include `--android-sdk android-sdk` even for Linux export.

You can do this from either:

- a Linux host machine
- a Windows host machine running a Redot build that supports Linux export templates

## Prerequisites

Shared requirements:

- compatible Redot editor/runtime
- Linux export templates installed for Redot

Linux-host-specific:

- local Linux Redot binary if you want to use `run.sh`

Windows-host-specific:

- local Windows Redot editor/runtime
- use the Redot editor or Windows CLI directly instead of `run.sh`

## One-Time Setup

### 1. Enter the repo

```bash
cd /path/to/SimRoom
```

### 2. Linux host only: place the Redot binary expected by `run.sh`

This repo’s Linux launcher expects:

```text
./redot.linuxbsd.editor.x86_64
```

Mark both scripts executable:

```bash
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
```

### 3. Linux host only: verify the launcher works

```bash
./run.sh --version
./run.sh --headless --quit-after 120
```

Expected result:

- Redot version prints
- `SimRoom ready` appears during the smoke test

## Project-Specific Setup

On Linux, this repo uses [run.sh](/home/edwin/Documents/SimRoom/run.sh) to force repo-local `HOME` and `XDG_*` paths. Use it for Linux development and exports unless you have a specific reason not to.

On Windows, use the same shared project and the same committed `Linux` export preset, but launch Redot directly from your Windows installation.

The committed Linux preset is in [export_presets.cfg](/home/edwin/Documents/SimRoom/export_presets.cfg) and is named `Linux`.

## Open And Run The Project

Linux host:

Interactive run:

```bash
./run.sh
```

Headless run:

```bash
./run.sh --headless --quit-after 120
```

Windows host:

- open the repo folder or `project.godot` in Redot
- run the main scene from the editor before exporting if you want a quick sanity check

## Export Command

Create output folders:

```bash
mkdir -p build/linux build/logs
```

Linux host export:

```bash
./run.sh --headless --export-debug Linux build/linux/SimRoom.x86_64 --log-file build/logs/linux-export.log
```

Windows host export:

- open the project in Redot on Windows
- use the committed `Linux` export preset
- export to `build/linux/SimRoom.x86_64`

If your Windows Redot build supports CLI export, use the same `Linux` preset against the same shared project.

## Output Location

Expected Linux export files:

- `build/linux/SimRoom.x86_64`
- `build/linux/SimRoom.pck`
- `build/linux/SimRoom.sh`

## Verification

### Confirm the executable exists

```bash
ls -la build/linux
```

### Confirm it is an ELF binary

```bash
file build/linux/SimRoom.x86_64
```

Expected result includes `ELF 64-bit`.

### Smoke-test the exported build

For a portable in-repo smoke test that mirrors `run.sh` behavior:

```bash
HOME="$(pwd)" \
XDG_DATA_HOME="$(pwd)/.xdg_data" \
XDG_CONFIG_HOME="$(pwd)/.xdg_config" \
XDG_CACHE_HOME="$(pwd)/.xdg_cache" \
./build/linux/SimRoom.x86_64 --headless --quit-after 120 --path build/linux
```

Expected result:

- exported binary starts
- `SimRoom ready` appears
- process exits cleanly

## What To Ship

For Linux distribution, keep these together:

- `SimRoom.x86_64`
- `SimRoom.pck`

`SimRoom.sh` is a small helper script produced by export. It is useful locally but not the core executable payload.

## Troubleshooting

### Export says Linux templates are missing

Check:

```bash
find .xdg_data/redot/export_templates -maxdepth 3 -type f | sort
```

You need the Linux x86_64 export templates installed for the Redot version used by this repo.

On Windows, check the Windows machine’s Redot export template installation instead of the repo-local `.xdg_*` path.

### `./run.sh` cannot find Redot

The repo does not commit the Redot binary. Put the correct binary at:

```text
./redot.linuxbsd.editor.x86_64
```

This applies only on Linux hosts. On Windows, use the local Windows Redot installation.

### Exported binary crashes trying to write to your home directory

Use the portable smoke-test command above so the exported binary writes into repo-local `.xdg_*` directories instead.
