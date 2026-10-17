#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -d /workspace && -w /workspace ]]; then
  runtime_dir="${METRO_RUNTIME_ROOT:-/workspace/.metro1982}"
else
  runtime_dir="${METRO_RUNTIME_ROOT:-${XDG_STATE_HOME:-$HOME/.local/state}/metro1982}"
fi
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$runtime_dir/cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$runtime_dir/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$runtime_dir/config}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
godot_bin="${GODOT_BIN:-godot}"
if [[ "${1:-}" == "--test" ]]; then
  shift
  "$godot_bin" --headless --path "$repo_dir" --editor --import --quit
  for suite in run visual_contract narrative_contract resident_contract chapter_contract floor_contract campaign_contract campaign_ui refinement_contract presentation_contract exploration_contract v9_contract; do
    "$godot_bin" --headless --path "$repo_dir" --fixed-fps 60 --script "res://tests/$suite.gd" "$@"
  done
  exit 0
fi
"$godot_bin" --headless --path "$repo_dir" --editor --import --quit
exec "$godot_bin" --path "$repo_dir" "$@"
