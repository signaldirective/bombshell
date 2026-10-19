#!/usr/bin/env bash
# bombshell-install-plugin.sh — install the bombshell launcher and the stock
# Omarchy bar's "switch to bombshell" widget.
#
#   * writes ~/.local/bin/bombshell               (launcher)
#   * installs omarchy-plugin/bombshell.switch    into ~/.config/omarchy/plugins/
#   * places the widget on the Omarchy bar when the Omarchy shell is running
#
# Re-run it any time; it is idempotent.

set -uo pipefail

BOMBSHELL_DIR="${BOMBSHELL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_ID="bombshell.switch"
PLUGIN_SRC="$BOMBSHELL_DIR/omarchy-plugin/$PLUGIN_ID"
PLUGIN_DST="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
BIN_DIR="$HOME/.local/bin"

info() { printf '  %s\n' "$*"; }

echo "Installing bombshell launcher -> $BIN_DIR/bombshell"
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/bombshell" <<EOF
#!/usr/bin/env bash
exec "$BOMBSHELL_DIR/scripts/bombshell-toggle.sh" bombshell
EOF
chmod +x "$BIN_DIR/bombshell"
info "done"

echo "Installing Omarchy bar widget -> $PLUGIN_DST"
mkdir -p "$PLUGIN_DST"
cp "$PLUGIN_SRC/manifest.json" "$PLUGIN_SRC/Widget.qml" "$PLUGIN_DST/"
info "done"

shell_running() { command -v omarchy-shell >/dev/null 2>&1 && omarchy-shell -q shell ping >/dev/null 2>&1; }

if shell_running; then
  echo "Registering widget with the running Omarchy shell"
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  count=$(omarchy-shell shell listPlugins 2>/dev/null | grep -c "$PLUGIN_ID" || true)
  if omarchy bar put "$PLUGIN_ID" --section left --index 0 >/dev/null 2>&1; then
    info "placed on the bar (left, index 0)"
  else
    info "could not place automatically; add it with:"
    info "  omarchy bar put $PLUGIN_ID --section left --index 0"
  fi
else
  echo "The Omarchy shell is not running. Once it is, run:"
  info "omarchy-shell shell rescanPlugins"
  info "omarchy bar put $PLUGIN_ID --section left --index 0"
fi

echo
echo "Done. Use 'bombshell' to show the bombshell bar, and the menu's"
echo "'Omarchy bar' entry to hand control back to the stock bar."
