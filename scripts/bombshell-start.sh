#!/usr/bin/env bash
# bombshell-start.sh — start the bombshell bar and get the stock Omarchy bar
# out of the way. Safe to run more than once.

set -uo pipefail

BOMBSHELL_DIR="${BOMBSHELL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Point the QML module names at the Omarchy shell's modules, so that plugin
# widgets can import qs.Ui and qs.Commons.
bash "$BOMBSHELL_DIR/scripts/bombshell-omarchy-modules.sh" >/dev/null 2>&1 || true

exec "$BOMBSHELL_DIR/scripts/bombshell-toggle.sh" bombshell
