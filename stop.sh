#!/usr/bin/env bash
# Stop the web UIs.   bash stop.sh [all|forge|kohya]
set -uo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/env.sh"

for t in $(dgs_targets "${1:-all}"); do
  pidf="$DGS_LOGS/$t.pid"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then
    # setsid made the process a group leader: stop the whole group
    kill -- -"$(cat "$pidf")" 2>/dev/null || kill "$(cat "$pidf")"
    c_ok "$t stopped"
  else
    c_warn "$t not running"
  fi
  rm -f "$pidf"
done
