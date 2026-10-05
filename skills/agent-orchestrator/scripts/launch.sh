#!/usr/bin/env bash
# usage: launch.sh <name> "<ownership list>"
# Runs ONE opencode agent in the foreground (call it from a background shell).
# Prompt = prompts/_header.md (placeholders filled) + prompts/<name>.md.
# Each agent gets its own XDG_DATA_HOME: parallel `opencode run` processes sharing
# ~/.local/share/opencode/opencode.db fail with "Failed to execute statement".
# Completion is signalled by a unique marker line, never by text an agent could print.
set -u
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
: "${WT_ROOT:?}" "${ORCH_ROOT:?}"

name=$1; own=$2
wt=$WT_ROOT/$name
[ -d "$wt" ] || { echo "no worktree $wt — run new-worktree.sh $name first"; exit 2; }
[ -f "$ORCH_ROOT/prompts/$name.md" ] || { echo "missing prompts/$name.md"; exit 2; }
branch=$(git -C "$wt" branch --show-current)
base=$(cat "$ORCH_ROOT/bases/$name" 2>/dev/null || git -C "$wt" rev-parse HEAD)

msg=$(sed -e "s|__WT__|$wt|g" -e "s|__BR__|$branch|g" -e "s|__BASE__|${base:0:7}|g" \
          -e "s|__OWN__|$own|g" "$ORCH_ROOT/prompts/_header.md"; printf '\n'; cat "$ORCH_ROOT/prompts/$name.md")
printf '%s' "$msg" > "$ORCH_ROOT/logs/$name.prompt.md"

data=$ORCH_ROOT/data/$name/opencode
mkdir -p "$data"
if [ ! -f "$data/auth.json" ] && [ -f "$HOME/.local/share/opencode/auth.json" ]; then
  install -m 600 "$HOME/.local/share/opencode/auth.json" "$data/auth.json"
fi

model_args=()
[ -n "${OPENCODE_MODEL:-}" ] && model_args=(--model "$OPENCODE_MODEL")

cd "$wt" && XDG_DATA_HOME=$ORCH_ROOT/data/$name opencode run --auto --dir "$wt" \
  --title "${RUN_LABEL:-ORCH} $name" "${model_args[@]}" "$msg" > "$ORCH_ROOT/logs/$name.log" 2>&1
code=$?
echo "__AGENT_DONE__ EXIT $code" >> "$ORCH_ROOT/logs/$name.log"
exit $code
