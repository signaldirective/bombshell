#!/usr/bin/env bash
# bombshell-stats.sh — emit one JSON object per poll with lightweight system
# telemetry the bar cannot get from a Quickshell service: CPU load and RAM.
# One line per sample, flushed so QML sees it immediately.

set -uo pipefail

INTERVAL="${1:-2}"

read_cpu() {
  # /proc/stat first line: cpu user nice system idle iowait irq softirq steal ...
  awk '/^cpu /{ idle=$5+$6; total=$2+$3+$4+$5+$6+$7+$8+$9; print total, idle }' /proc/stat
}

read_mem() {
  awk '
    /^MemTotal:/     { total=$2 }
    /^MemAvailable:/ { avail=$2 }
    END { print total, avail }
  ' /proc/meminfo
}

read_clock() {
  awk '/^cpu MHz/{ if ($4+0 > max) max=$4+0 } END { printf "%.0f", max }' /proc/cpuinfo 2>/dev/null
}

prev="$(read_cpu)"
prev_total="${prev% *}"
prev_idle="${prev#* }"

while :; do
  sleep "$INTERVAL"

  cur="$(read_cpu)"
  cur_total="${cur% *}"
  cur_idle="${cur#* }"

  d_total=$(( cur_total - prev_total ))
  d_idle=$(( cur_idle - prev_idle ))
  prev_total="$cur_total"
  prev_idle="$cur_idle"

  if (( d_total > 0 )); then
    cpu=$(awk -v t="$d_total" -v i="$d_idle" 'BEGIN { printf "%.0f", (t - i) * 100 / t }')
  else
    cpu=0
  fi

  mem="$(read_mem)"
  mem_total="${mem% *}"
  mem_avail="${mem#* }"
  if (( mem_total > 0 )); then
    mem_pct=$(awk -v t="$mem_total" -v a="$mem_avail" 'BEGIN { printf "%.0f", (t - a) * 100 / t }')
    mem_used_mib=$(( (mem_total - mem_avail) / 1024 ))
    mem_total_mib=$(( mem_total / 1024 ))
  else
    mem_pct=0
    mem_used_mib=0
    mem_total_mib=0
  fi

  load="$(awk '{ print $1, $2, $3 }' /proc/loadavg)"
  clock="$(read_clock)"

  printf '{"cpu":%s,"mem":%s,"memUsedMiB":%s,"memTotalMiB":%s,"load":"%s","clockMHz":%s}\n' \
    "$cpu" "$mem_pct" "$mem_used_mib" "$mem_total_mib" "$load" "${clock:-0}"
done
