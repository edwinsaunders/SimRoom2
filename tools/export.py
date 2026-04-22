#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


REDOT_VERSION = "26.1.stable"
REPO_ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = REPO_ROOT / "build"
LOGS_DIR = BUILD_DIR / "logs"

DESKTOP_EXPORTS = {
    "linux": {
        "preset": "Linux",
        "output": Path("build/linux/SimRoom.x86_64"),
        "log": Path("build/logs/linux-export.log"),
    },
    "windows": {
        "preset": "Windows",
        "output": Path("build/windows/SimRoom.exe"),
        "log": Path("build/logs/windows-export.log"),
    },
}


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()

    targets = _normalize_targets(args.targets)
    engine_path = _resolve_engine_path(args.engine)
    env = _portable_env()
    baseline_status = _git_status_lines() if args.verify_clean else None
    _configure_android_env(env, args.android_sdk)

    if args.template_dir:
        _install_templates(Path(args.template_dir), env)

    BUILD_DIR.mkdir(exist_ok=True)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    for target in targets:
        if target in DESKTOP_EXPORTS:
            _export_desktop(target, engine_path, env)
        elif target == "android":
            _export_android(engine_path, env, args)
        else:
            raise ValueError(f"Unsupported target: {target}")

    if args.verify_clean:
        _verify_clean(baseline_status)

    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Cross-platform wrapper around the repo's Redot export workflows."
    )
    parser.add_argument(
        "targets",
        nargs="+",
        choices=["linux", "windows", "android", "all"],
        help="Export targets to build.",
    )
    parser.add_argument(
        "--engine",
        help="Path to the Redot editor/runtime binary. Defaults to a repo-local binary for the current host when available.",
    )
    parser.add_argument(
        "--template-dir",
        help=(
            "Directory containing extracted Redot export templates. "
            "May point at either the version directory or its templates/ child."
        ),
    )
    parser.add_argument(
        "--android-sdk",
        default="android-sdk",
        help="Repo-relative or absolute Android SDK path for Android exports.",
    )
    parser.add_argument(
        "--verify-clean",
        action="store_true",
        help="Fail if git status is dirty after export.",
    )
    return parser


def _normalize_targets(raw_targets: list[str]) -> list[str]:
    if "all" in raw_targets:
        return ["linux", "windows", "android"]

    ordered: list[str] = []
    for target in raw_targets:
        if target not in ordered:
            ordered.append(target)
    return ordered


def _resolve_engine_path(explicit: str | None) -> Path:
    if explicit:
        path = (REPO_ROOT / explicit).resolve() if not Path(explicit).is_absolute() else Path(explicit)
        if not path.exists():
            raise FileNotFoundError(f"Redot binary not found: {path}")
        return path

    candidates = []
    if sys.platform.startswith("linux"):
        candidates.append(REPO_ROOT / "redot.linuxbsd.editor.x86_64")
    elif os.name == "nt":
        candidates.extend(
            [
                REPO_ROOT / "redot.windows.editor.x86_64.exe",
                REPO_ROOT / "Redot_v26.1-stable_win64.exe",
                REPO_ROOT / "redot.exe",
            ]
        )

    for candidate in candidates:
        if candidate.exists():
            return candidate.resolve()

    raise FileNotFoundError(
        "No Redot binary found. Pass --engine with a repo-relative or absolute path."
    )


def _portable_env() -> dict[str, str]:
    env = os.environ.copy()

    if sys.platform.startswith("linux"):
        home = REPO_ROOT
        env["HOME"] = str(home)
        env["XDG_DATA_HOME"] = str(REPO_ROOT / ".xdg_data")
        env["XDG_CONFIG_HOME"] = str(REPO_ROOT / ".xdg_config")
        env["XDG_CACHE_HOME"] = str(REPO_ROOT / ".xdg_cache")
        Path(env["XDG_DATA_HOME"]).mkdir(parents=True, exist_ok=True)
        Path(env["XDG_CONFIG_HOME"]).mkdir(parents=True, exist_ok=True)
        Path(env["XDG_CACHE_HOME"]).mkdir(parents=True, exist_ok=True)
    elif os.name == "nt":
        home = REPO_ROOT / ".windows-home"
        roaming = home / "AppData" / "Roaming"
        local = home / "AppData" / "Local"
        temp = home / "Temp"
        for path in (roaming, local, temp):
            path.mkdir(parents=True, exist_ok=True)
        env["HOME"] = str(home)
        env["USERPROFILE"] = str(home)
        env["APPDATA"] = str(roaming)
        env["LOCALAPPDATA"] = str(local)
        env["TEMP"] = str(temp)
        env["TMP"] = str(temp)

    return env


def _configure_android_env(env: dict[str, str], raw_android_sdk: str | None) -> None:
    if not raw_android_sdk:
        return

    android_sdk = _resolve_repo_path(raw_android_sdk)
    if not android_sdk.exists():
        return

    sdk_path = str(android_sdk)
    env["ANDROID_HOME"] = sdk_path
    env["ANDROID_SDK_ROOT"] = sdk_path


def _template_roots(env: dict[str, str]) -> list[Path]:
    if os.name == "nt":
        roaming = Path(env["APPDATA"])
        return [
            roaming / "Redot" / "export_templates" / REDOT_VERSION,
            roaming / "redot" / "export_templates" / REDOT_VERSION,
        ]

    return [Path(env["XDG_DATA_HOME"]) / "redot" / "export_templates" / REDOT_VERSION]


def _install_templates(source_dir: Path, env: dict[str, str]) -> None:
    resolved = (REPO_ROOT / source_dir).resolve() if not source_dir.is_absolute() else source_dir.resolve()
    if not resolved.exists():
        raise FileNotFoundError(f"Template directory not found: {resolved}")

    if (resolved / "templates").is_dir():
        resolved = resolved / "templates"

    for root in _template_roots(env):
        root.mkdir(parents=True, exist_ok=True)
        nested_root = root / "templates"
        nested_root.mkdir(parents=True, exist_ok=True)
        for item in resolved.iterdir():
            _copy_template_item(item, root / item.name)
            _copy_template_item(item, nested_root / item.name)


def _copy_template_item(source: Path, destination: Path) -> None:
    if destination.exists() and source.resolve() == destination.resolve():
        return
    if source.is_dir():
        if destination.exists():
            shutil.rmtree(destination)
        shutil.copytree(source, destination)
    else:
        shutil.copy2(source, destination)


def _run(command: list[str], env: dict[str, str], cwd: Path | None = None) -> None:
    printable = " ".join(command)
    print(f"[run] {printable}")
    subprocess.run(command, cwd=cwd or REPO_ROOT, env=env, check=True)


def _export_desktop(target: str, engine_path: Path, env: dict[str, str]) -> None:
    config = DESKTOP_EXPORTS[target]
    output_path = REPO_ROOT / config["output"]
    output_path.parent.mkdir(parents=True, exist_ok=True)
    (REPO_ROOT / config["log"]).parent.mkdir(parents=True, exist_ok=True)

    command = [
        str(engine_path),
        "--headless",
        "--path",
        ".",
        "--export-debug",
        config["preset"],
        config["output"].as_posix(),
        "--log-file",
        config["log"].as_posix(),
    ]
    _run(command, env)


def _export_android(engine_path: Path, env: dict[str, str], args: argparse.Namespace) -> None:
    android_sdk = _resolve_repo_path(args.android_sdk)
    if not android_sdk.exists():
        raise FileNotFoundError(f"Android SDK not found: {android_sdk}")

    BUILD_DIR.joinpath("android").mkdir(parents=True, exist_ok=True)
    BUILD_DIR.joinpath("android_source").mkdir(parents=True, exist_ok=True)

    _run(
        [
            str(engine_path),
            "--headless",
            "--path",
            ".",
            "--export-pack",
            "Android",
            "build/android/SimRoom.pck",
            "--log-file",
            "build/logs/android-pack.log",
        ],
        env,
    )

    source_root = REPO_ROOT / "build" / "android_source"
    if source_root.exists():
        shutil.rmtree(source_root)
    source_root.mkdir(parents=True, exist_ok=True)

    template_zip = _find_android_template(env, args.template_dir)
    with zipfile.ZipFile(template_zip) as archive:
        archive.extractall(source_root)

    local_properties = source_root / "local.properties"
    local_properties.write_text(f"sdk.dir={android_sdk.resolve()}\n", encoding="utf-8")

    assets_dir = source_root / "assets"
    assets_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(REPO_ROOT / "build" / "android" / "SimRoom.pck", assets_dir / "data.pck")

    _run(
        [sys.executable, "platform/android/write_android_cl.py", "build/android_source/assets/_cl_"],
        env,
    )

    gradle = source_root / ("gradlew.bat" if os.name == "nt" else "gradlew")
    if not gradle.exists():
        raise FileNotFoundError(f"Gradle wrapper not found: {gradle}")
    
    if os.name != "nt":
        gradle.chmod(gradle.stat().st_mode | 0o111)

    gradle_command = [
        str(gradle),
        "assembleDebug",
        "-Pexport_package_name=com.edwin.simroom",
        "-Pexport_version_code=1",
        "-Pexport_version_name=1.0",
        "-Pexport_enabled_abis=arm64-v8a|",
    ]
    _run(gradle_command, env, cwd=source_root)

    unsigned_apk = source_root / "build" / "outputs" / "apk" / "standard" / "debug" / "android_debug.apk"
    if not unsigned_apk.exists():
        raise FileNotFoundError(f"Unsigned Android APK not found: {unsigned_apk}")

    keystore = _ensure_debug_keystore(env)
    apksigner = _find_apksigner(android_sdk)
    signed_apk = REPO_ROOT / "build" / "android" / "SimRoom-debug.apk"
    _run(
        [
            str(apksigner),
            "sign",
            "--ks",
            str(keystore),
            "--ks-key-alias",
            "androiddebugkey",
            "--ks-pass",
            "pass:android",
            "--key-pass",
            "pass:android",
            "--out",
            str(signed_apk),
            str(unsigned_apk),
        ],
        env,
    )


def _resolve_repo_path(raw_path: str) -> Path:
    path = Path(raw_path)
    return (REPO_ROOT / path).resolve() if not path.is_absolute() else path.resolve()


def _find_android_template(env: dict[str, str], template_dir_arg: str | None) -> Path:
    if template_dir_arg:
        base = _resolve_repo_path(template_dir_arg)
        for candidate in (base / "android_source.zip", base / "templates" / "android_source.zip"):
            if candidate.exists():
                return candidate

    for root in _template_roots(env):
        for candidate in (root / "android_source.zip", root / "templates" / "android_source.zip"):
            if candidate.exists():
                return candidate

    raise FileNotFoundError(
        "Android source template not found. Install export templates or pass --template-dir."
    )


def _ensure_debug_keystore(env: dict[str, str]) -> Path:
    if os.name == "nt":
        keystore_dir = Path(env["APPDATA"]) / "Redot" / "keystores"
    else:
        keystore_dir = REPO_ROOT / ".xdg_data" / "redot" / "keystores"

    keystore_dir.mkdir(parents=True, exist_ok=True)
    keystore = keystore_dir / "debug.keystore"
    if keystore.exists():
        return keystore

    command = [
        "keytool",
        "-genkeypair",
        "-v",
        "-keystore",
        str(keystore),
        "-storepass",
        "android",
        "-alias",
        "androiddebugkey",
        "-keypass",
        "android",
        "-keyalg",
        "RSA",
        "-keysize",
        "2048",
        "-validity",
        "10000",
        "-dname",
        "CN=Android Debug,O=Android,C=US",
    ]
    _run(command, env)
    return keystore


def _find_apksigner(android_sdk: Path) -> Path:
    candidates = sorted(android_sdk.glob("build-tools/*/apksigner*"))
    for candidate in reversed(candidates):
        if candidate.is_file() and candidate.name.startswith("apksigner"):
            return candidate
    raise FileNotFoundError(f"apksigner not found under {android_sdk / 'build-tools'}")


def _git_status_lines() -> list[str]:
    result = subprocess.run(
        ["git", "status", "--short"],
        cwd=REPO_ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def _verify_clean(baseline_status: list[str] | None) -> None:
    before = baseline_status or []
    after = _git_status_lines()
    if after != before:
        before_set = set(before)
        after_set = set(after)
        new_lines = [line for line in after if line not in before_set]
        removed_lines = [line for line in before if line not in after_set]
        details: list[str] = []
        if new_lines:
            details.append("New status entries after export:\n" + "\n".join(new_lines))
        if removed_lines:
            details.append("Status entries changed during export:\n" + "\n".join(removed_lines))
        raise SystemExit("Export changed git status.\n" + "\n\n".join(details))
    print("[ok] export left git status unchanged")


if __name__ == "__main__":
    raise SystemExit(main())
