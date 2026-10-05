#!/usr/bin/env bash
# usage: resume.sh <name> ["extra instruction"]
# Continues the agent's last session with the same executor and data dir. Use when an agent
# exited 0 before finishing (step limit, context) or stalled and was killed.
set -u
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
name=$1
extra=${2:-"Continue the task from where you stopped. Re-read your original prompt, check git log/status, finish the remaining items, run the verification, and end with the final report."}
wt=$WT_ROOT/$name; data=$ORCH_ROOT/data/$name; log=$ORCH_ROOT/logs/$name.log
executor=$(cat "$data/executor" 2>/dev/null || echo "${EXECUTOR:-opencode}")
model=${EXEC_MODEL:-}; effort=${EXEC_EFFORT:-}
sed -i '/^__AGENT_DONE__/d' "$log"
cd "$wt" || exit 2
case $executor in
  opencode)
    args=(run --auto --continue --dir "$wt")
    [ -n "$model" ] && args+=(--model "$model")
    [ -n "$effort" ] && args+=(--variant "$effort")
    XDG_DATA_HOME=$data opencode "${args[@]}" "$extra" >> "$log" 2>&1 ;;
  pi)
    args=(-p -c --session-dir "$data/pi")
    [ -n "$model" ] && args+=(--model "$model")
    [ -n "$effort" ] && args+=(--thinking "$effort")
    pi "${args[@]}" "$extra" >> "$log" 2>&1 ;;
  agy|antigravity)
    args=(-c -p "$extra" --dangerously-skip-permissions)
    [ -n "$model" ] && args+=(--model "$model")
    [ -n "$effort" ] && args+=(--effort "$effort")
    agy "${args[@]}" >> "$log" 2>&1 ;;
  custom)
    : "${EXEC_RESUME_CMD:?set EXEC_RESUME_CMD to resume a custom executor}"
    PROMPT="$extra" WT=$wt AGENT_DATA=$data bash -c "$EXEC_RESUME_CMD" >> "$log" 2>&1 ;;
esac
code=$?
echo "__AGENT_DONE__ EXIT $code" >> "$log"
exit $code
