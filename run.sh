#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export HOME="$ROOT_DIR"
export XDG_DATA_HOME="$ROOT_DIR/.xdg_data"
export XDG_CONFIG_HOME="$ROOT_DIR/.xdg_config"
export XDG_CACHE_HOME="$ROOT_DIR/.xdg_cache"

mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

exec "$ROOT_DIR/redot.linuxbsd.editor.x86_64" --path "$ROOT_DIR" "$@"
