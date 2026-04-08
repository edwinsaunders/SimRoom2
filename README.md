# SimRoom

Single-project Redot proof of concept: a first-person 3D room with movement, run, jump, mouse look, synthesized jump/landing/chiptune audio, and a bright emissive 16:9 in-world pixel screen. Linux, Windows, and Android all use the same shared `project.godot`, scenes, scripts, and assets.

## Repo Layout

```text
.
├── docs/                 Export and workflow docs
├── platform/             Platform-specific export helpers only
│   └── android/
├── scenes/               Shared scenes
├── scripts/              Shared gameplay and rendering scripts
├── project.godot         Redot project settings
├── export_presets.cfg    Shared export presets/config
└── run.sh                Linux development launcher
```

## Linux Development

```bash
cd /path/to/SimRoom
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
./run.sh
```

Headless smoke test:

```bash
./run.sh --headless --quit-after 120
```

## Controls

- `W` `A` `S` `D`: move
- `Left Shift`: run
- `Space`: jump
- Mouse: look
- Left click inside the window: recapture mouse
- `Escape`: toggle mouse capture
- `F11`: toggle fullscreen
- `Ctrl+Q`: quit

## Export Docs

- [docs/exports.md](/home/edwin/Documents/SimRoom/docs/exports.md): Linux, Windows, and Android export setup and commands

## Build Docs

- [docs/build-from-fresh-clone.md](/home/edwin/Documents/SimRoom/docs/build-from-fresh-clone.md): start here on a newly cloned machine
- [docs/build-linux.md](/home/edwin/Documents/SimRoom/docs/build-linux.md): run and export Linux builds
- [docs/build-windows.md](/home/edwin/Documents/SimRoom/docs/build-windows.md): export Windows builds from the same shared project
- [docs/build-android.md](/home/edwin/Documents/SimRoom/docs/build-android.md): build and verify a debug Android APK

## Git Workflow

- [docs/multi-machine-workflow.md](/home/edwin/Documents/SimRoom/docs/multi-machine-workflow.md): practical clone, update, commit, push, and machine-switch workflow for working from multiple computers

## Shared Code

- [scenes/main.tscn](/home/edwin/Documents/SimRoom/scenes/main.tscn): main scene with room, lighting, player, and screen
- [scripts/main.gd](/home/edwin/Documents/SimRoom/scripts/main.gd): room setup and shutdown handling
- [scripts/player.gd](/home/edwin/Documents/SimRoom/scripts/player.gd): first-person movement, jump, sprint, mouse capture, and quit controls
- [scripts/animated_screen.gd](/home/edwin/Documents/SimRoom/scripts/animated_screen.gd): seamless 16:9 neon pixel animation
- [scripts/audio_library.gd](/home/edwin/Documents/SimRoom/scripts/audio_library.gd): generated jump, landing, and background audio

## Platform-Specific Helpers

- [platform/android/build_pck.gd](/home/edwin/Documents/SimRoom/platform/android/build_pck.gd): builds the Android `data.pck`
- [platform/android/write_android_cl.py](/home/edwin/Documents/SimRoom/platform/android/write_android_cl.py): writes the Android `_cl_` launch args asset

## Notes

- Generated SDKs, export outputs, Gradle caches, and Redot import artifacts are ignored in git.
- The root project remains the only game project. Platform folders contain export support only, not duplicated scenes or scripts.
- Script `.uid` files are intentionally tracked so Redot does not regenerate them during export checks.
