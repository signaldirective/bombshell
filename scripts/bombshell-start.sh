#!/usr/bin/env bash
# bombshell-start.sh — start the bombshell bar and get the stock Omarchy bar
# out of the way. Safe to run more than once.

set -uo pipefail

BOMBSHELL_DIR="${BOMBSHELL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

exec "$BOMBSHELL_DIR/scripts/bombshell-toggle.sh" bombshell
