#!/usr/bin/env bash
# bombshell-plugins.sh — list the Omarchy shell plugins that provide a bar
# widget, together with the metadata bombshell needs to place one.
#
#   usage: bombshell-plugins.sh <omarchy-shell-dir> <user-plugins-dir> <shell.json>
#
# Prints a JSON array on stdout. Every element looks like:
#
#   { "id": "omarchy.clock", "name": "Clock", "description": "...",
#     "category": "Time", "section": "center",
#     "url": "file:///.../BarWidget.qml", "enabled": true,
#     "firstParty": true, "settings": { "format": "HH:mm" } }
#
# `enabled` mirrors what the Omarchy shell itself considers enabled, so the
# menu can tell the user which of these are live in the stock bar.
#
# The scan mirrors the shell's own manifest walk: every plugin directory with
# a `manifest.json` (or a `*.manifest.json` inside a plugin) that declares
# the `bar-widget` kind and a bar widget entry point.

set -uo pipefail

SHELL_DIR="${1:-}"        # $OMARCHY_PATH/shell
USER_DIR="${2:-}"         # ~/.config/omarchy/plugins
SHELL_JSON="${3:-}"       # ~/.config/omarchy/shell.json

command -v jq >/dev/null 2>&1 || { echo "[]"; exit 0; }

manifests=()
if [[ -n "$SHELL_DIR" && -d "$SHELL_DIR/plugins" ]]; then
  while IFS= read -r manifest; do
    [[ -n "$manifest" ]] && manifests+=("$manifest")
  done < <(find "$SHELL_DIR/plugins" -mindepth 2 -maxdepth 3 -type f \
             \( -name manifest.json -o -name '*.manifest.json' \) 2>/dev/null | sort)
fi
if [[ -n "$USER_DIR" && -d "$USER_DIR" ]]; then
  for sub in "$USER_DIR"/*/; do
    [[ -d "$sub" ]] || continue
    [[ -f "$sub/manifest.json" ]] && manifests+=("${sub}manifest.json")
  done
fi

if [[ ${#manifests[@]} -eq 0 ]]; then
  echo "[]"
  exit 0
fi

# ── catalogue ────────────────────────────────────────────────────────────────
# `input_filename` carries the manifest's own directory, which is where the
# entry point lives. First-party manifests come from the shell tree.
catalog=$(jq -c '
  select(type == "object")
  | select(.schemaVersion == 1)
  | select((.kinds // []) | index("bar-widget"))
  | select((.entryPoints.barWidget // "") | type == "string")
  | {
      id: (.id // ""),
      name: (.barWidget.displayName // .name // .id // ""),
      description: (.barWidget.description // .description // ""),
      category: (.barWidget.category // ""),
      section: (.barWidget.defaultSection // "center"),
      entry: .entryPoints.barWidget,
      dir: (input_filename | sub("/[^/]*manifest[.]json$"; "")),
      firstParty: (input_filename | startswith("'"${SHELL_DIR}"'"))
    }
' "${manifests[@]}" 2>/dev/null | jq -s '.' 2>/dev/null)

# ── enabled state ───────────────────────────────────────────────────────────
# `omarchy plugin list --json` is the shell's own answer, so prefer it. When
# the CLI is not around, fall back to reading shell.json the way the shell
# does: a plugin is on when the bar layout or the plugins list mentions it,
# and first-party plugins are on unless they were explicitly disabled.
enabled=$(omarchy plugin list --json 2>/dev/null \
  | jq -c 'if type == "array"
           then (map({ key: .id, value: (.enabled == true) }) | from_entries)
           else {} end' 2>/dev/null)

config=$(jq -c 'if type == "object" then . else {} end' "$SHELL_JSON" 2>/dev/null)

# Note: `${var:-{}}` would append a stray brace, so the defaults are applied
# with plain assignments.
[[ -n "$catalog" ]] || catalog='[]'
[[ -n "$enabled" ]] || enabled='{}'
[[ -n "$config" ]] || config='{}'

jq -n \
  --argjson catalog "$catalog" \
  --argjson enabled "$enabled" \
  --argjson config "$config" \
  '
  def sectionOf($s):
    if $s == "left" then "left"
    elif $s == "right" then "right"
    else "center" end;

  # The bar layout lives in shell.json, so it is read from $config rather
  # than from the pipeline input.
  def layoutEntries:
    [ ($config.bar.layout // {}) | to_entries[] | .value[]? | select(type == "object") ]
    + [ ($config.bar.layout // {}) | to_entries[] | .value[]? | select(type == "string") | { id: . } ];

  def settingsFor($id):
    reduce (layoutEntries[]) as $e ({};
      if (($e.id // "") | tostring) == $id then
        reduce ($e | to_entries[]) as $kv (.;
          if $kv.key == "id" then . else .[$kv.key] = $kv.value end)
      else . end);

  def enabledIn($id; $first):
    if ($enabled | has($id)) then ($enabled[$id] == true)
    else
      ( ($config.disabledPlugins // []) | index($id) ) as $off
      | if $off != null then false
        elif $first then true
        else
          ( (layoutEntries | map(.id // "") | index($id)) != null )
          or ( ($config.plugins // []) | map(.id // "") | index($id) != null )
        end
    end;

  [ $catalog[]
    | select((.id // "") != "")
    | .url = ("file://" + (.dir | rtrimstr("/")) + "/" + .entry)
    | .section = sectionOf(.section)
    | .enabled = enabledIn(.id; (.firstParty == true))
    | .settings = settingsFor(.id)
  ]
  '
