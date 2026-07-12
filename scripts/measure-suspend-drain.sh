#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./measure-suspend-drain.sh [duration] [--allow-ac]

Measure laptop battery drain across a timed suspend.

Duration defaults to 10m. Accepted examples:
  300     300 seconds
  5m      5 minutes
  0.25h   15 minutes

The script arms an RTC wake alarm, then uses systemctl suspend.
It normally needs root to program the RTC alarm.
Unplug AC power before running for a useful battery-drain measurement.
EOF
}

duration=10m
allow_ac=0

for arg in "$@"; do
  case "$arg" in
  -h | --help)
    usage
    exit 0
    ;;
  --allow-ac)
    allow_ac=1
    ;;
  *)
    duration=$arg
    ;;
  esac
done

duration_to_seconds() {
  local value=$1

  case "$value" in
  *s) awk -v v="${value%s}" 'BEGIN { printf "%d\n", v + 0 }' ;;
  *m) awk -v v="${value%m}" 'BEGIN { printf "%d\n", v * 60 }' ;;
  *h) awk -v v="${value%h}" 'BEGIN { printf "%d\n", v * 3600 }' ;;
  *) awk -v v="$value" 'BEGIN { printf "%d\n", v + 0 }' ;;
  esac
}

seconds=$(duration_to_seconds "$duration")
if [[ "$seconds" -lt 60 ]]; then
  echo "Refusing to measure less than 60 seconds; very short runs are too noisy." >&2
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "This needs root to program the RTC wake alarm. Re-run as root: sudo $0 $*" >&2
    exit 1
  fi
  echo "Re-running with sudo to program the RTC wake alarm..."
  exec sudo -- "$0" "$@"
fi

battery=""
for path in /sys/class/power_supply/BAT*; do
  [[ -d "$path" ]] || continue
  if [[ -r "$path/type" ]] && [[ "$(cat "$path/type")" == "Battery" ]]; then
    battery=$path
    break
  fi
done

if [[ -z "$battery" ]]; then
  echo "No battery found under /sys/class/power_supply." >&2
  exit 1
fi

if [[ "$allow_ac" -eq 0 ]]; then
  for ac in /sys/class/power_supply/A{C,CAD,DP,DP-*}* /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD*; do
    [[ -r "$ac/online" ]] || continue
    if [[ "$(cat "$ac/online")" == "1" ]]; then
      echo "AC power appears to be connected at $ac." >&2
      echo "Unplug power and run again, or pass --allow-ac if you really want to measure anyway." >&2
      exit 1
    fi
  done
fi

read_energy_uwh() {
  local bat=$1

  if [[ -r "$bat/energy_now" ]]; then
    cat "$bat/energy_now"
    return
  fi

  if [[ -r "$bat/charge_now" && -r "$bat/voltage_now" ]]; then
    awk -v charge_uah="$(cat "$bat/charge_now")" -v voltage_uv="$(cat "$bat/voltage_now")" \
      'BEGIN { printf "%d\n", (charge_uah * voltage_uv) / 1000000 }'
    return
  fi

  echo "Battery exposes neither energy_now nor charge_now+voltage_now." >&2
  exit 1
}

fmt_wh() {
  awk -v uwh="$1" 'BEGIN { printf "%.3f Wh", uwh / 1000000 }'
}

fmt_w() {
  awk -v uwh="$1" -v sec="$2" 'BEGIN { printf "%.3f W", (uwh / 1000000) / (sec / 3600) }'
}

read_int_file() {
  local path=$1

  if [[ -r "$path" ]]; then
    cat "$path"
  else
    echo 0
  fi
}

rtc=${RTCWAKE:-rtcwake}
if ! command -v "$rtc" >/dev/null 2>&1; then
  echo "rtcwake not found in PATH." >&2
  exit 1
fi

suspend_cmd=${SUSPEND_CMD:-systemctl}
if ! command -v "$suspend_cmd" >/dev/null 2>&1; then
  echo "systemctl not found in PATH. Set SUSPEND_CMD to another suspend command if needed." >&2
  exit 1
fi

mem_sleep="unknown"
if [[ -r /sys/power/mem_sleep ]]; then
  mem_sleep=$(cat /sys/power/mem_sleep)
fi

before=$(read_energy_uwh "$battery")
success_before=$(read_int_file /sys/power/suspend_stats/success)
start_epoch=$(date +%s)
target_epoch=$((start_epoch + seconds))
start_text=$(date --iso-8601=seconds)
target_text=$(date --date="@$target_epoch" --iso-8601=seconds)

echo "Battery: $battery"
echo "Sleep mode: $mem_sleep"
echo "Duration: ${seconds}s"
echo "Start: $start_text"
echo "Target wake: $target_text"
echo "Before: $(fmt_wh "$before")"
echo
echo "Suspending now. Wake should happen automatically."

"$rtc" -m disable >/dev/null 2>&1 || true
"$rtc" -m no -s "$seconds"
sync
"$suspend_cmd" suspend

while [[ "$(date +%s)" -lt "$target_epoch" ]]; do
  sleep 1
done

"$rtc" -m disable >/dev/null 2>&1 || true

after=$(read_energy_uwh "$battery")
success_after=$(read_int_file /sys/power/suspend_stats/success)
end_epoch=$(date +%s)
end_text=$(date --iso-8601=seconds)
elapsed=$((end_epoch - start_epoch))
used=$((before - after))
suspend_success_delta=$((success_after - success_before))

if [[ "$used" -lt 0 ]]; then
  echo "Battery energy increased during the run; AC may have been connected or the battery gauge recalibrated." >&2
  used=0
fi

echo
echo "End: $end_text"
echo "After: $(fmt_wh "$after")"
echo "Elapsed: ${elapsed}s"
echo "Suspend/resume cycles recorded: $suspend_success_delta"
echo "Drain: $(fmt_wh "$used")"
echo "Average suspend draw: $(fmt_w "$used" "$elapsed")"
echo
if [[ "$suspend_success_delta" -lt 1 ]]; then
  echo "Warning: the kernel did not record a successful suspend/resume cycle during this run." >&2
  echo "The drain number may include normal awake idle time rather than suspend." >&2
fi
echo "Tip: run this a few times or use 15-30m for a less noisy estimate."
