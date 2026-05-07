#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scripting_dir="addons/sourcemod/scripting"
compiler="sourcemod/spcomp64"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/spcomp-docker.sh <plugin.sp> [output.smx]" >&2
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
plugin_name="$(basename "$source_in_scripting" .sp)"

if [[ $# -ge 2 ]]; then
  output="$2"
else
  output="compiled/${plugin_name}.smx"
fi

include_args=(
  -iinclude
  -isourcemod/include
  -iconfoglcompmod/include
  -iarchive/include
  -iarchive/includes
  -iAnneHappy
  -ireadyup
  -iinclude/multicolors
  -iinclude/ripext
)

docker run --rm --platform linux/amd64 \
  -v "$repo_root:/work" \
  -w "/work/$scripting_dir" \
  ubuntu:22.04 \
  bash -lc '
    set -euo pipefail
    mkdir -p "$(dirname "$1")"
    chmod +x "$0"
    "$0" "$2" "${@:4}" -o"$1"
  ' "$compiler" "$output" "$source_in_scripting" _ "${include_args[@]}"
