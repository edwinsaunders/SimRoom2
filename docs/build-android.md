# Build Android

This guide explains how to build a debug Android APK from a fresh clone.

Preferred export path:

```bash
python3 tools/export.py android \
  --engine ./redot.linuxbsd.editor.x86_64 \
  --android-sdk android-sdk \
  --verify-clean
```

This document keeps the platform-specific details and troubleshooting for what that wrapper is doing underneath.

This repository keeps one shared Redot project and uses Android-specific helpers only in [platform/android](/home/edwin/Documents/SimRoom/platform/android). There is no separate Android game project.

You can build Android from either:

- a Linux host machine
- a Windows host machine

## Important Reality Check

The Android path in this repo is only partly automated through Redot itself.

What is fully committed:

- shared project source
- Android export preset in [export_presets.cfg](/home/edwin/Documents/SimRoom/export_presets.cfg)
- helper scripts:
  - [platform/android/build_pck.gd](/home/edwin/Documents/SimRoom/platform/android/build_pck.gd)
  - [platform/android/write_android_cl.py](/home/edwin/Documents/SimRoom/platform/android/write_android_cl.py)

What is still machine-local:

- Java SDK
- Android SDK
- Android export templates
- Gradle cache
- debug keystore

What is currently the reliable path on a fresh machine:

- build the shared `data.pck`
- unpack the Android source template
- inject `data.pck` and `_cl_`
- run the Gradle debug build
- sign the resulting debug APK with a debug keystore

Use Redot’s direct Android export only if it works on your machine. The Gradle source-template path is the practical fallback documented here.

## Prerequisites

Shared requirements:

- compatible Redot editor/runtime
- Java 17
- `unzip`
- Python 3
- Android SDK command-line tools
- Android platform-tools
- Android platform `android-35`
- Android build-tools `35.0.1`

Linux-host-specific:

- `curl`
- `keytool`
- local Linux Redot binary if you want to use `run.sh`

Windows-host-specific:

- Windows equivalents for Java 17, Android SDK, and Redot
- use the Windows Redot app directly instead of `run.sh`

Optional for install/run verification:

- `adb`
- connected Android device or emulator

## One-Time Setup

### 1. Enter the repo

```bash
cd /path/to/SimRoom
```

### 2. Set up Redot for this host

Linux host:

```bash
chmod +x ./run.sh ./redot.linuxbsd.editor.x86_64
```

Windows host:

- install or unpack a compatible Windows Redot editor/runtime
- open the same shared project in that Windows Redot build when needed

### 3. Install Android export templates

On Linux, because `run.sh` uses repo-local XDG folders, this repo expects the Redot template path under:

```text
.xdg_data/redot/export_templates/26.1.stable/
```

On Windows, install the matching Android export templates into that machine’s normal Redot template location.

For Android you need at least:

- `android_debug.apk`
- `android_release.apk`
- `android_source.zip`

### 4. Install Java 17

Verify:

```bash
java -version
javac -version
keytool -help >/dev/null
```

### 5. Create a machine-local Android SDK

The repo ignores `android-sdk/`, so it is safe to create locally per machine.

Linux host example using a repo-local SDK:

```bash
mkdir -p android-sdk
cd android-sdk
curl -L -o commandlinetools-linux.zip https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
rm -rf cmdline-tools
mkdir -p cmdline-tools
unzip -q commandlinetools-linux.zip -d cmdline-tools
mv cmdline-tools/cmdline-tools cmdline-tools/latest
cd ..
```

Install the required SDK packages:

```bash
yes | android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root="$(pwd)/android-sdk" \
  "platform-tools" \
  "platforms;android-35" \
  "build-tools;35.0.1"
```

Verify:

```bash
find android-sdk -maxdepth 3 \( -name adb -o -name apksigner -o -name source.properties \) | sort
```

Windows host note:

- you can also use a Windows-local Android SDK installation
- the repo does not require the SDK to live inside the repo on Windows
- if you follow a Windows-local SDK path, adjust the Gradle `local.properties` step later to point at that Windows path

## Project-Specific Setup

### 1. Create the debug keystore if it does not exist

```bash
mkdir -p .xdg_data/redot/keystores
keytool -genkeypair -v \
  -keystore .xdg_data/redot/keystores/debug.keystore \
  -storepass android \
  -alias androiddebugkey \
  -keypass android \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
```

This is for debug builds only. Do not reuse this approach for release signing.

### 2. Optional editor settings if you want to try direct Redot Android export

If you use Redot’s own Android export UI/CLI, you must set machine-local editor settings for:

- Java SDK path
- Android SDK path
- debug keystore path

On Linux, those settings live under `.xdg_config/` because of `run.sh` and are ignored in git.

On Windows, the equivalent Redot editor settings are also machine-local and should not be committed.

The reliable path below does not require you to rely on Redot’s direct Android exporter succeeding.

## Build Commands

### 1. Create output folders

```bash
mkdir -p build/android build/android_source build/logs
```

### 2. Build the shared game pack

Linux host:

```bash
./run.sh --headless --script platform/android/build_pck.gd --log-file build/logs/android-pack.log
```

Expected output:

- `build/android/SimRoom.pck`

Windows host:

- open the project in Redot on Windows
- run the helper script or use that Redot build’s equivalent headless script invocation against `platform/android/build_pck.gd`
- the expected output is still `build/android/SimRoom.pck`

### 3. Unpack the Android source template

```bash
unzip -oq .xdg_data/redot/export_templates/26.1.stable/android_source.zip -d build/android_source
```

### 4. Point Gradle at the Android SDK

Linux host example:

```bash
printf 'sdk.dir=%s\n' "$(pwd)/android-sdk" > build/android_source/local.properties
```

Windows host:

- write `build/android_source/local.properties` with the Windows SDK path for that machine
- example format:

```text
sdk.dir=C:\\path\\to\\Android\\Sdk
```

### 5. Copy the game pack and generate the `_cl_` launch args asset

```bash
cp build/android/SimRoom.pck build/android_source/assets/data.pck
python3 platform/android/write_android_cl.py build/android_source/assets/_cl_
```

### 6. Build the debug APK with Gradle

Linux host:

```bash
cd build/android_source
./gradlew assembleDebug \
  -Pexport_package_name=com.edwin.simroom \
  -Pexport_version_code=1 \
  -Pexport_version_name=1.0 \
  '-Pexport_enabled_abis=arm64-v8a|'
cd ../..
```

Windows host:

- open a terminal in `build/android_source`
- use the Windows Gradle wrapper:

```powershell
.\gradlew.bat assembleDebug `
  -Pexport_package_name=com.edwin.simroom `
  -Pexport_version_code=1 `
  -Pexport_version_name=1.0 `
  "-Pexport_enabled_abis=arm64-v8a|"
```

Expected Gradle output:

- `build/android_source/build/outputs/apk/standard/debug/android_debug.apk`

### 7. Sign the debug APK

Linux host:

```bash
android-sdk/build-tools/35.0.1/apksigner sign \
  --ks .xdg_data/redot/keystores/debug.keystore \
  --ks-key-alias androiddebugkey \
  --ks-pass pass:android \
  --key-pass pass:android \
  --out build/android/SimRoom-debug.apk \
  build/android_source/build/outputs/apk/standard/debug/android_debug.apk
```

Windows host:

- use the Windows `apksigner` from that machine’s Android SDK build-tools directory
- keep using the same debug keystore concept, but with Windows paths

## Output Location

Expected Android outputs:

- `build/android/SimRoom.pck`
- `build/android/SimRoom-debug.apk`
- `build/android_source/` temporary Gradle/source-template project

## Verification

### Confirm the APK exists

```bash
ls -la build/android
```

### Confirm it is an APK

```bash
file build/android/SimRoom-debug.apk
```

### Verify the signature

```bash
android-sdk/build-tools/35.0.1/apksigner verify --print-certs build/android/SimRoom-debug.apk
```

### Confirm the packaged game data is present

```bash
unzip -l build/android/SimRoom-debug.apk | rg 'assets/_cl_|assets/data.pck|lib/arm64-v8a/libgodot_android.so'
```

### Optional install/run with `adb`

If `adb` is available and a device or emulator is connected:

```bash
android-sdk/platform-tools/adb devices
android-sdk/platform-tools/adb install -r build/android/SimRoom-debug.apk
```

If `adb devices` cannot see a device, packaging is still valid but device runtime verification is pending on that machine.

## Debug Vs Release

Documented here:

- debug APK only
- debug keystore only

Not covered here:

- release keystore generation
- release signing
- Play Store upload setup

Release signing requires your own real keystore and release-signing process.

## Troubleshooting

### Redot says Android templates are missing

Check:

```bash
find .xdg_data/redot/export_templates -maxdepth 3 -type f | sort
```

If the Android template files are missing, install them on that machine first.

On Windows, check the Windows machine’s Redot template installation instead of the repo-local `.xdg_*` path.

### `sdkmanager` or `gradlew` fails because Java is missing

Verify Java 17:

```bash
java -version
javac -version
```

### Gradle complains about Android build-tools version

This repo’s working Gradle source template has been used with build-tools `35.0.1`.

Install it explicitly:

```bash
yes | android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root="$(pwd)/android-sdk" "build-tools;35.0.1"
```

### APK does not launch and complains about missing project data

Check that both assets were packaged:

```bash
unzip -l build/android/SimRoom-debug.apk | rg 'assets/_cl_|assets/data.pck'
```

You need both:

- `assets/data.pck`
- `assets/_cl_`

### `adb` cannot connect to a device

That is outside the project itself. Typical causes:

- no connected device/emulator
- USB debugging not enabled
- local sandbox or permission restrictions

The APK can still be considered built successfully even if device installation is not possible on that machine.
