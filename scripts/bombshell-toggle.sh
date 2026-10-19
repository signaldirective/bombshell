#!/usr/bin/env bash
# bombshell-toggle.sh — flip between the bombshell bar and the stock Omarchy bar.
#
#   bombshell-toggle.sh omarchy   show the Omarchy bar, hide bombshell
#   bombshell-toggle.sh bombshell show bombshell, hide the Omarchy bar
#
# Both bars can run at the same time; only one is visible/reserving space.
# The Omarchy shell keeps running either way so its services (notifications,
# nightlight, idle, media, lock) stay available to bombshell.

set -uo pipefail

BOMBSHELL_DIR="${BOMBSHELL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BOMBSHELL_BIN="${BOMBSHELL_BIN:-quickshell}"

have_omarchy_shell() { command -v omarchy-shell >/dev/null 2>&1 && omarchy-shell -q shell ping >/dev/null 2>&1; }

ensure_omarchy_shell() {
  have_omarchy_shell && return 0
  # An Omarchy shell may already be starting; wait for it before launching a
  # second one.
  for _ in $(seq 1 30); do
    have_omarchy_shell && return 0
    sleep 0.2
  done
  command -v omarchy-launch-shell >/dev/null 2>&1 || return 1
  omarchy-launch-shell >/dev/null 2>&1 &
  for _ in $(seq 1 60); do
    have_omarchy_shell && return 0
    sleep 0.1
  done
  return 1
}

bombshell_ipc() {
  command -v qs >/dev/null 2>&1 || return 1
  qs ipc -p "$BOMBSHELL_DIR" call -- bombshell "$@" 2>/dev/null
}

bombshell_running() { bombshell_ipc ping | grep -q '^ok$'; }

start_bombshell() {
  setsid -f "$BOMBSHELL_BIN" -n -p "$BOMBSHELL_DIR" >/dev/null 2>&1
  for _ in $(seq 1 60); do
    bombshell_running && return 0
    sleep 0.1
  done
  return 1
}

# `omarchy-toggle-bar` names the *bar-off* flag: `on` hides the stock bar,
# `off` shows it.
case "${1:-}" in
  omarchy)
    ensure_omarchy_shell || true
    omarchy-toggle-bar off >/dev/null 2>&1 || true
    bombshell_ipc hideBar >/dev/null 2>&1 || true
    ;;
  bombshell)
    if bombshell_running; then
      bombshell_ipc showBar >/dev/null 2>&1 || true
    else
      start_bombshell || true
    fi
    omarchy-toggle-bar on >/dev/null 2>&1 || true
    ;;
  *)
    echo "usage: bombshell-toggle.sh {omarchy|bombshell}" >&2
    exit 2
    ;;
esac
