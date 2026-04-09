# Export Guide

This repo now uses one cross-platform wrapper around the real Redot export workflow:

- local command: `python tools/export.py ...`
- CI automation: [`.github/workflows/exports.yml`](/home/edwin/Documents/SimRoom2/.github/workflows/exports.yml)

The wrapper does not invent a new build system. It shells out to Redot's real CLI export commands for desktop targets and uses the repo's existing Android source-template path where that is the practical workflow.

## Local Usage

From the repo root:

```bash
python3 tools/export.py linux \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

Multiple targets:

```bash
python3 tools/export.py linux windows \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

Android:

```bash
python3 tools/export.py android \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

On Windows, use the same wrapper and point `--engine` at the local Windows Redot executable:

```powershell
py tools/export.py windows --engine .\path\to\redot.exe --android-sdk .\android-sdk --verify-clean
```

## Source Of Truth

Desktop exports use Redot's actual CLI export commands:

```text
redot --headless --path . --export-debug <Preset> <OutputPath> --log-file <LogPath>
```

The wrapper uses that directly for:

- `Linux`
- `Windows`

Android remains "as far as practical" because this repo already relies on the committed source-template helpers under [platform/android](/home/edwin/Documents/SimRoom2/platform/android):

1. Redot CLI runs [platform/android/build_pck.gd](/home/edwin/Documents/SimRoom2/platform/android/build_pck.gd)
2. the wrapper unpacks `android_source.zip`
3. the wrapper injects `data.pck` and `_cl_`
4. Gradle builds the debug APK
5. `apksigner` signs the debug APK

That preserves the real project workflow instead of replacing it.

## Template Handling

The wrapper can install extracted Redot export templates into a portable repo-local location:

```bash
python3 tools/export.py linux \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --template-dir .ci/export-templates
```

Notes:

- On Linux, portable state lives under `.xdg_*`
- On Windows, portable Redot state created by the wrapper lives under `.windows-home/`
- both locations are ignored by git

If templates are already installed where the wrapper expects them, `--template-dir` is optional.

## Android SDK Note For Desktop Exports

In this repo, passing `--android-sdk` is recommended even for Linux and Windows desktop exports.

Reason:

- [export_presets.cfg](/home/edwin/Documents/SimRoom2/export_presets.cfg) commits an Android export preset alongside the desktop presets
- this Redot build validates Android export setup during desktop export startup
- if Android SDK metadata is missing, desktop export can warn or fail before the requested target finishes exporting

The desktop builds do not need Android tools as output dependencies. This is just a project-level Redot validation requirement caused by the committed Android preset.

## Outputs

Desktop outputs:

- `build/linux/SimRoom.x86_64`
- `build/windows/SimRoom.exe`
- `build/logs/*.log`

Android outputs:

- `build/android/SimRoom.pck`
- `build/android/SimRoom-debug.apk`
- `build/logs/android-pack.log`

All generated build outputs stay under `build/`, which is ignored by git.

## Clean Working Tree Verification

The wrapper supports:

```bash
python3 tools/export.py linux \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

That runs the export and fails if export steps add or change git status entries relative to the pre-export baseline. This lets you verify that exports do not create tracked noise even when you already have source edits in progress.

## CI Usage

GitHub Actions workflow:

- [`.github/workflows/exports.yml`](/home/edwin/Documents/SimRoom2/.github/workflows/exports.yml)

Current CI coverage:

- Ubuntu job exporting Linux
- Windows job exporting Windows
- Ubuntu job exporting Android debug APK

Each job downloads the matching Redot binary and templates, runs the same Python wrapper, and uploads the generated artifacts.

## Platform-Specific Notes

Deep-dive setup docs remain here:

- [docs/build-linux.md](/home/edwin/Documents/SimRoom2/docs/build-linux.md)
- [docs/build-windows.md](/home/edwin/Documents/SimRoom2/docs/build-windows.md)
- [docs/build-android.md](/home/edwin/Documents/SimRoom2/docs/build-android.md)

Use those when you need platform-specific prerequisites or troubleshooting details. For normal exports, prefer `tools/export.py`.
