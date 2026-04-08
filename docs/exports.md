# Export Guide

This repository keeps one shared Redot project at the repo root. Linux, Windows, and Android exports all come from the same [project.godot](/home/edwin/Documents/SimRoom/project.godot), [scenes](/home/edwin/Documents/SimRoom/scenes), and [scripts](/home/edwin/Documents/SimRoom/scripts).

## Prerequisites

- Redot editor/runtime available locally
- Redot export templates installed for the target platform
- For Android only:
  - JDK 17
  - Android SDK command-line tools
  - Android platform/build-tools matching your export setup

## Linux Development Run

```bash
cd /path/to/SimRoom
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
./run.sh
```

## Linux Export

Recommended flow:

1. Open the project in Redot.
2. Open `Project -> Export`.
3. Add a Linux desktop preset if the project does not already have one.
4. Export to a path under `build/` or `dist/`, for example `build/linux/SimRoom.x86_64`.

This repository does not currently commit a Linux preset, so that preset creation is a manual editor step before CLI export automation.

## Windows Export

Recommended flow:

1. Open the project in Redot.
2. Open `Project -> Export`.
3. Add a Windows desktop preset if the project does not already have one.
4. Export to a path under `build/` or `dist/`, for example `build/windows/SimRoom.exe`.

Keep the generated `.pck` beside the Windows executable if your chosen export mode does not embed it automatically.

This repository does not currently commit a Windows preset, so that preset creation is a manual editor step before CLI export automation.

## Android Export

The Android path in this repo is intentionally isolated under [platform/android](/home/edwin/Documents/SimRoom/platform/android). Shared game content stays in the root project.

### Prepare the shared game pack

```bash
cd /path/to/SimRoom
./run.sh --headless --script platform/android/build_pck.gd
```

This writes `build/android/SimRoom.pck`.

### Build an Android source export

Use Redot's Android export/template flow to generate a Gradle project under `build/android_source/`. If your Redot CLI exporter works in your environment, use it. If not, the Gradle source-template fallback used in this repo is still compatible with the same shared project files.

Before Android export can work on a fresh machine, you must install and configure all of the following:

- Android export templates under `.xdg_data/redot/export_templates/<redot-version>/`
- Java SDK path in Redot Editor Settings
- Android SDK path in Redot Editor Settings, including valid `platform-tools` and `build-tools`

### Add the Android launch args asset

Redot's Android startup expects an `_cl_` asset that points to `res://data.pck`.

```bash
cd /path/to/SimRoom
python3 platform/android/write_android_cl.py
```

That writes `build/android_source/assets/_cl_`.

### Package the APK

Run the Gradle wrapper inside the generated Android source project:

```bash
cd /path/to/SimRoom/build/android_source
./gradlew assembleDebug
```

The resulting APK will be under the Gradle output tree for that generated project. Copy or publish the final APK from `build/` or your CI artifact step.

## CI Layout Notes

- Commit shared game code only from the repo root.
- Keep generated SDKs, Gradle outputs, APKs, PCKs, and imported Redot cache files out of git.
- Use `platform/android/` for Android-specific export helpers instead of mixing them into gameplay folders.
- Preserve [run.sh](/home/edwin/Documents/SimRoom/run.sh) for local Linux development; CI can call Redot directly against the same root project.
