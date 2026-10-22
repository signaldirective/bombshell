#!/usr/bin/env bash
# bombshell-omarchy-modules.sh — point bombshell's QML module names at the
# Omarchy shell's modules.
#
# Omarchy's plugin widgets import `qs.Ui` and `qs.Commons`. Quickshell
# resolves a qualified import against the shell root, so bombshell needs
# `Ui/` and `Commons/` next to its own shell.qml. Symlinks are used rather
# than copies so an Omarchy update is picked up without reinstalling.
#
#   usage: bombshell-omarchy-modules.sh [bombshell-dir]

set -uo pipefail

BOMBSHELL_DIR="${1:-${BOMBSHELL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"

candidates=()
[[ -n "${OMARCHY_PATH:-}" ]] && candidates+=("$OMARCHY_PATH/shell")
candidates+=("/usr/share/omarchy/shell")

source_dir=""
for dir in "${candidates[@]}"; do
  if [[ -d "$dir/Ui" && -d "$dir/Commons" ]]; then
    source_dir="$dir"
    break
  fi
done

if [[ -z "$source_dir" ]]; then
  echo "bombshell: no Omarchy shell modules found; plugin widgets will not load" >&2
  exit 0
fi

for mod in Ui Commons; do
  src="$source_dir/$mod"
  dst="$BOMBSHELL_DIR/$mod"
  [[ -d "$src" ]] || continue
  if [[ -L "$dst" ]]; then
    [[ "$(readlink "$dst")" == "$src" ]] && continue
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    # A real directory is somebody's own module — leave it alone.
    continue
  fi
  ln -sfn "$src" "$dst"
done

echo "$source_dir"
