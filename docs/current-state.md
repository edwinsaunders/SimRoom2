# Current State

This file is a durable handoff for future Codex sessions and for moving work between machines.

## Project Snapshot

- Engine/project type: Redot 3D starter project
- Main gameplay scene: [scenes/main.tscn](/home/edwin/Documents/SimRoom2/scenes/main.tscn)
- Main world orchestration script: [scripts/main.gd](/home/edwin/Documents/SimRoom2/scripts/main.gd)
- Player controller: [scripts/player.gd](/home/edwin/Documents/SimRoom2/scripts/player.gd)
- Interactive door logic: [scripts/door.gd](/home/edwin/Documents/SimRoom2/scripts/door.gd)
- Second-room video screen logic: [scripts/video_screen.gd](/home/edwin/Documents/SimRoom2/scripts/video_screen.gd)
- Mobile touch controls: [scripts/mobile_controls.gd](/home/edwin/Documents/SimRoom2/scripts/mobile_controls.gd)

## Current Architecture

- The root scene is [scenes/main.tscn](/home/edwin/Documents/SimRoom2/scenes/main.tscn), which owns:
  - world environment
  - lighting
  - player
  - mobile controls overlay
  - the original first-room animated screen
- [scripts/main.gd](/home/edwin/Documents/SimRoom2/scripts/main.gd) procedurally builds:
  - room A shell
  - room B shell
  - shared doorway opening
  - interactive door leaf
  - second-room video screen and frame
- The first room keeps its original animated screen from [scripts/animated_screen.gd](/home/edwin/Documents/SimRoom2/scripts/animated_screen.gd).
- The second room uses `res://output.ogv` on a screen surface via [scripts/video_screen.gd](/home/edwin/Documents/SimRoom2/scripts/video_screen.gd).

## Current Gameplay Features

- Two connected rooms
- One animated screen in room one
- One video screen in room two
- One interactive door between rooms
- Desktop keyboard/mouse controls
- Mobile touch controls for Android/iOS-style builds
- Android APK export path
- Cross-platform export wrapper and GitHub Actions export workflow

## Media And Interaction Notes

- The first-room screen is intentionally unchanged from the original starter setup.
- The second-room screen uses the video file already in the repo: `res://output.ogv`
- The video currently uses embedded audio from the `.ogv` because that path works on both editor-run desktop and Android.
- Earlier attempts to split video and audio were abandoned because they broke working playback behavior.
- The door toggles with `E` when the player is close enough.

## Lighting State

- Both rooms were brightened and balanced to feel similar.
- Global ambient and fill lighting are configured in [scenes/main.tscn](/home/edwin/Documents/SimRoom2/scenes/main.tscn).
- There is a dedicated `SecondRoomFillLight` to keep room two from feeling darker than room one.

## Export Automation

Preferred local export entry point:

- [tools/export.py](/home/edwin/Documents/SimRoom2/tools/export.py)

CI workflow:

- [`.github/workflows/exports.yml`](/home/edwin/Documents/SimRoom2/.github/workflows/exports.yml)

Primary export docs:

- [docs/exports.md](/home/edwin/Documents/SimRoom2/docs/exports.md)
- [docs/build-linux.md](/home/edwin/Documents/SimRoom2/docs/build-linux.md)
- [docs/build-windows.md](/home/edwin/Documents/SimRoom2/docs/build-windows.md)
- [docs/build-android.md](/home/edwin/Documents/SimRoom2/docs/build-android.md)

## Platform Quirks

- Important: this repo commits an Android export preset in [export_presets.cfg](/home/edwin/Documents/SimRoom2/export_presets.cfg).
- This Redot build validates Android export setup even during Linux and Windows desktop export startup.
- Because of that, desktop export commands should include `--android-sdk ...` in this repo.
- This is a project/export-validation quirk, not a true dependency of the desktop artifacts themselves.

## Latest Working Export Commands

Linux target from Linux host:

```bash
python3 tools/export.py linux \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

Windows target from Linux host:

```bash
python3 tools/export.py windows \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

Windows target from Windows host:

```powershell
py tools/export.py windows --engine .\path\to\redot.exe --android-sdk .\android-sdk --verify-clean
```

Android target:

```bash
python3 tools/export.py android \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

## Verified State

- Local Linux export wrapper was verified successfully.
- The wrapper confirmed export left git status unchanged after export.
- Android APK flow worked earlier in this repo history using the committed Android helpers and current media path.
- The CI workflow was added but not executed from this session.

## Recent Relevant Commits

- `4ef7d7d` `Ignore Python cache files`
- `db3e1eb` `Add cross-platform export automation`
- `1551dba` `Fix Android media packing and mobile controls`
- `3115840` `Add mobile touch controls and Android ignore rules`
- `d89604a` `Add second room video screen and interactive door`

## Next Likely Tasks

- add more rooms beyond the current two-room layout
- replace the current single door transition with a cleaner room/transition abstraction if the map grows
- improve Android/desktop parity for future controls and media features
- optionally extract screen/frame creation helpers if more in-world displays are added
- optionally replace procedural room generation with reusable room scenes once there are enough rooms to justify it
