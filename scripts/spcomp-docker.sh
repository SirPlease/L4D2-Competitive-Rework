#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scripting_dir="addons/sourcemod/scripting"
compiler="/work/$scripting_dir/sourcemod/spcomp64"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/spcomp-docker.sh <plugin.sp> [output.smx]" >&2
  echo "When output is omitted, the plugin is written under addons/sourcemod/plugins." >&2
  exit 2
fi

source_file="$1"
if [[ "$source_file" = "$repo_root/"* ]]; then
  source_rel="${source_file#"$repo_root"/}"
else
  source_rel="$source_file"
fi

if [[ "$source_rel" != "$scripting_dir/"*.sp ]]; then
  echo "Source file must be under $scripting_dir: $source_file" >&2
  exit 2
fi

source_in_scripting="${source_rel#"$scripting_dir"/}"
source_dir_in_scripting="$(dirname "$source_in_scripting")"
source_file="$(basename "$source_in_scripting")"
plugin_name="$(basename "$source_in_scripting" .sp)"

default_plugin_rel_for_source() {
  local source_path="$1"
  local name="$2"

  # Project sources mirror addons/sourcemod/plugins/. Upstream SourceMod stock
  # sources are kept under scripting/sourcemod/ and map back to root/disabled.
  if [[ "$source_path" == sourcemod/* ]]; then
    if [[ -f "$repo_root/addons/sourcemod/plugins/$name.smx" ]]; then
      printf '%s.smx\n' "$name"
      return
    fi
    if [[ -f "$repo_root/addons/sourcemod/plugins/disabled/$name.smx" ]]; then
      printf 'disabled/%s.smx\n' "$name"
      return
    fi
    printf '%s.smx\n' "$name"
    return
  fi

  printf '%s.smx\n' "${source_path%.sp}"
}

container_output_for_arg() {
  local output_path="$1"

  if [[ "$output_path" == /work/* ]]; then
    printf '%s\n' "$output_path"
  elif [[ "$output_path" == "$repo_root/"* ]]; then
    printf '/work/%s\n' "${output_path#"$repo_root"/}"
  elif [[ "$output_path" = /* ]]; then
    echo "Output path must be inside the repository when using Docker: $output_path" >&2
    return 2
  elif [[ "$output_path" == ./* ]]; then
    printf '/work/%s\n' "${output_path#./}"
  elif [[ "$output_path" == addons/* || "$output_path" == cfg/* || "$output_path" == scripts/* ]]; then
    printf '/work/%s\n' "$output_path"
  else
    printf '/work/%s/%s\n' "$scripting_dir" "$output_path"
  fi
}

if [[ $# -ge 2 ]]; then
  output="$(container_output_for_arg "$2")"
else
  output="/work/addons/sourcemod/plugins/$(default_plugin_rel_for_source "$source_in_scripting" "$plugin_name")"
fi

source_dir="/work/$scripting_dir"
if [[ "$source_dir_in_scripting" != "." ]]; then
  source_dir="$source_dir/$source_dir_in_scripting"
fi

include_args=(
  -i/work/$scripting_dir/include
  -i/work/$scripting_dir/sourcemod/include
  -i/work/$scripting_dir/confoglcompmod/include
  -i/work/$scripting_dir/confoglcompmod/includes
  -i/work/$scripting_dir/archive/include
  -i/work/$scripting_dir/archive/includes
  -i/work/$scripting_dir/optional
  -i/work/$scripting_dir/optional/AnneHappy
  -i/work/$scripting_dir/extend
  -i/work/$scripting_dir/include/multicolors
  -i/work/$scripting_dir/include/ripext
)

docker run --rm --platform linux/amd64 \
  -v "$repo_root:/work" \
  -w "/work/$scripting_dir" \
  ubuntu:22.04 \
  bash -lc '
    set -euo pipefail
    compiler="$0"
    output="$1"
    source_dir="$2"
    source_file="$3"
    shift 3

    mkdir -p "$(dirname "$output")"
    chmod +x "$compiler"
    cd "$source_dir"
    "$compiler" "$source_file" "$@" -o"$output"
  ' "$compiler" "$output" "$source_dir" "$source_file" "${include_args[@]}"
