#!/usr/bin/env bash
# usage: launch.sh <name> "<ownership list>" [executor]
# Runs ONE worker agent in the foreground (call it from a background shell).
# Prompt = prompts/_header.md (placeholders filled) + prompts/<name>.md.
#
# Executors (EXECUTOR in orch.env, or the 3rd argument):
#   opencode  opencode run --auto            reasoning: EXEC_EFFORT → --variant
#   pi        pi -p                          reasoning: EXEC_EFFORT → --thinking
#   agy       Antigravity CLI: agy -p        reasoning: EXEC_EFFORT → --effort
#   custom    EXEC_CMD (bash), with $PROMPT_FILE, $WT, $AGENT_DATA exported
# Model: EXEC_MODEL (provider/model for opencode, model pattern for pi/agy). Empty = tool default.
#
# Each agent gets its own data/session dir under $ORCH_ROOT/data/<name>: parallel opencode
# runs sharing one SQLite db fail with "Failed to execute statement".
# Completion is signalled by a unique marker line, never by text an agent could print.
set -u
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
: "${WT_ROOT:?}" "${ORCH_ROOT:?}"

name=$1; own=$2; executor=${3:-${EXECUTOR:-opencode}}
wt=$WT_ROOT/$name
[ -d "$wt" ] || { echo "no worktree $wt — run new-worktree.sh $name first"; exit 2; }
[ -f "$ORCH_ROOT/prompts/$name.md" ] || { echo "missing prompts/$name.md"; exit 2; }
branch=$(git -C "$wt" branch --show-current)
base=$(cat "$ORCH_ROOT/bases/$name" 2>/dev/null || git -C "$wt" rev-parse HEAD)

prompt_file=$ORCH_ROOT/logs/$name.prompt.md
{ sed -e "s|__WT__|$wt|g" -e "s|__BR__|$branch|g" -e "s|__BASE__|${base:0:7}|g" \
      -e "s|__OWN__|$own|g" "$ORCH_ROOT/prompts/_header.md"; printf '\n'; cat "$ORCH_ROOT/prompts/$name.md"; } > "$prompt_file"
msg=$(cat "$prompt_file")
log=$ORCH_ROOT/logs/$name.log
data=$ORCH_ROOT/data/$name
mkdir -p "$data"
echo "$executor" > "$data/executor"

model=${EXEC_MODEL:-}; effort=${EXEC_EFFORT:-}
cd "$wt" || exit 2
case $executor in
  opencode)
    mkdir -p "$data/opencode"
    if [ ! -f "$data/opencode/auth.json" ] && [ -f "$HOME/.local/share/opencode/auth.json" ]; then
      install -m 600 "$HOME/.local/share/opencode/auth.json" "$data/opencode/auth.json"
    fi
    args=(run --auto --dir "$wt" --title "${RUN_LABEL:-ORCH} $name")
    [ -n "$model" ] && args+=(--model "$model")
    [ -n "$effort" ] && args+=(--variant "$effort")
    XDG_DATA_HOME=$data opencode "${args[@]}" "$msg" > "$log" 2>&1 ;;
  pi)
    args=(-p --session-dir "$data/pi")
    [ -n "$model" ] && args+=(--model "$model")
    [ -n "$effort" ] && args+=(--thinking "$effort")
    pi "${args[@]}" "$msg" > "$log" 2>&1 ;;
  agy|antigravity)
    args=(-p "$msg" --dangerously-skip-permissions)
    [ -n "$model" ] && args+=(--model "$model")
    [ -n "$effort" ] && args+=(--effort "$effort")
    agy "${args[@]}" > "$log" 2>&1 ;;
  custom)
    : "${EXEC_CMD:?set EXEC_CMD for the custom executor}"
    PROMPT_FILE=$prompt_file WT=$wt AGENT_DATA=$data bash -c "$EXEC_CMD" > "$log" 2>&1 ;;
  *) echo "unknown executor: $executor (opencode|pi|agy|custom)"; exit 2 ;;
esac
code=$?
echo "__AGENT_DONE__ EXIT $code" >> "$log"
exit $code
