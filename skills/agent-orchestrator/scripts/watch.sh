#!/usr/bin/env bash
# usage: watch.sh <name> [stall-minutes]
# Event stream for a Monitor: one line per new commit, a STALL line when the log has
# not grown for N minutes (default 20), and a FINISHED line on the launcher marker.
# Exits after FINISHED.
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
name=$1; stall=${2:-20}
wt=$WT_ROOT/$name; log=$ORCH_ROOT/logs/$name.log
base=$(cat "$ORCH_ROOT/bases/$name" 2>/dev/null || git -C "$wt" rev-parse HEAD)
last=0; size=0; idle=0; stalled=0
while true; do
  c=$(git -C "$wt" rev-list --count "$base"..HEAD 2>/dev/null || echo 0)
  if [ "$c" != "$last" ]; then echo "$name commits=$c: $(git -C "$wt" log -1 --format=%s)"; last=$c; fi
  if grep -aq '^__AGENT_DONE__' "$log" 2>/dev/null; then
    err=$(grep -a 'Error:' "$log" | tail -1 | sed 's/\x1b\[[0-9;]*m//g' | cut -c1-160)
    echo "$name FINISHED $(grep -a '^__AGENT_DONE__' "$log" | tail -1) ${err:+| last error: $err}"
    exit 0
  fi
  now=$(stat -c %s "$log" 2>/dev/null || echo 0)
  if [ "$now" = "$size" ]; then idle=$((idle + 1)); else idle=0; stalled=0; size=$now; fi
  if [ $((idle * 30)) -ge $((stall * 60)) ] && [ $stalled = 0 ]; then
    echo "$name STALL: no log output for ${stall}m (consider kill + resume.sh)"; stalled=1
  fi
  sleep 30
done
