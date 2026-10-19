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
  for suite in run visual_contract narrative_contract resident_contract chapter_contract floor_contract campaign_contract campaign_ui refinement_contract presentation_contract exploration_contract v9_contract v10_contract v11_contract v11_combat occlusion_v11 visual_fixes_v11_1 commune_v12 factory_v12 equipment_v12 platform_v12 actors_v13 publications_v13 public_radio_v16 ivan_gait_v16 furnishings_v16 first_meetings_v17 starcity_v17 ivan_gait_v17 motion_v18 expedition_v19 narrative_v19 crowds_v19; do
    "$godot_bin" --headless --path "$repo_dir" --fixed-fps 60 --script "res://tests/$suite.gd" "$@"
  done
  exit 0
fi
"$godot_bin" --headless --path "$repo_dir" --editor --import --quit
exec "$godot_bin" --path "$repo_dir" "$@"
