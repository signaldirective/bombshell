#!/usr/bin/env bash
# bombshell-indicators.sh — stream the state of the Omarchy status indicators
# as one JSON object per poll. Keeps all the (mildly expensive) probes in one
# long-lived process instead of spawning several timers inside the shell.

set -uo pipefail

INTERVAL="${1:-2}"
STATE_DIR="$HOME/.local/state/omarchy/indicators"

bool() { if "$@" >/dev/null 2>&1; then echo true; else echo false; fi; }

while :; do
  dnd_raw="$(omarchy-shell -q notifications dndState 2>/dev/null | tr -d '\r\n')"
  [[ "$dnd_raw" == "on" ]] && dnd=true || dnd=false

  nl_raw="$(omarchy-toggle-nightlight --status 2>/dev/null)"
  nl="$(jq -r '.enabled // false' <<<"${nl_raw:-{\}}" 2>/dev/null)"
  [[ "$nl" == "true" ]] || nl=false

  if [[ -f "$STATE_DIR/stay-awake" ]]; then awake=true; else awake=false; fi

  if pgrep --quiet -f '^gpu-screen-recorder' 2>/dev/null; then rec=true; else rec=false; fi

  rem="$(omarchy-reminder show --json 2>/dev/null | jq -r '.count // 0' 2>/dev/null)"
  [[ "$rem" =~ ^[0-9]+$ ]] || rem=0

  vox_raw="$(timeout 1 omarchy-voxtype-status 2>/dev/null | head -n1)"
  vox="$(jq -r '.class // "idle"' <<<"${vox_raw:-{\}}" 2>/dev/null)"
  [[ -n "$vox" ]] || vox=idle

  printf '{"dnd":%s,"nightlight":%s,"stayAwake":%s,"recording":%s,"reminders":%s,"vox":"%s"}\n' \
    "$dnd" "$nl" "$awake" "$rec" "$rem" "$vox"

  sleep "$INTERVAL"
done
