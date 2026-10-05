#!/usr/bin/env bash
# usage: resume.sh <name> ["extra instruction"]
# Continues the agent's last session in its own data dir. Use when an agent exited 0
# before finishing (step limit, context) or stalled and was killed.
set -u
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
name=$1
extra=${2:-"Continue the task from where you stopped. Re-read your prompt above, check git log/status, finish the remaining items, run the verification, and end with the final report."}
wt=$WT_ROOT/$name
sed -i '/^__AGENT_DONE__/d' "$ORCH_ROOT/logs/$name.log"
cd "$wt" && XDG_DATA_HOME=$ORCH_ROOT/data/$name opencode run --auto --continue --dir "$wt" "$extra" \
  >> "$ORCH_ROOT/logs/$name.log" 2>&1
code=$?
echo "__AGENT_DONE__ EXIT $code" >> "$ORCH_ROOT/logs/$name.log"
exit $code
