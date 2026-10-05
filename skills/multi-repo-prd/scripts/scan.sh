#!/usr/bin/env bash
# usage: scan.sh <ALIAS> <local-repo-path> [ref]
# Read-only inventory of one source repository by an opencode agent.
# The agent works in a detached, disposable worktree pinned to <ref> (default HEAD), so it can
# never modify the source checkout, and writes its report to $ORCH_ROOT/scans/<ALIAS>.md.
# Run one scan per source repo (in parallel only if the machine allows — see agent-orchestrator).
set -u
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
: "${ORCH_ROOT:?export ORCH_ROOT first}"
here=$(cd "$(dirname "$0")" && pwd)

alias=$1; src=$2; ref=${3:-HEAD}
sha=$(git -C "$src" rev-parse "$ref")
dir=$ORCH_ROOT/scan-src/$alias
mkdir -p "$ORCH_ROOT"/{scans,logs,data,scan-src}
if [ ! -d "$dir" ]; then git -C "$src" worktree add -q --detach "$dir" "$sha"; fi

out=$ORCH_ROOT/scans/$alias.md
msg=$(sed -e "s|__ALIAS__|$alias|g" -e "s|__SRC__|$dir|g" -e "s|__SHA__|$sha|g" -e "s|__OUT__|$out|g" \
  "$here/../templates/scan-prompt.md")

data=$ORCH_ROOT/data/scan-$alias/opencode
mkdir -p "$data"
if [ ! -f "$data/auth.json" ] && [ -f "$HOME/.local/share/opencode/auth.json" ]; then
  install -m 600 "$HOME/.local/share/opencode/auth.json" "$data/auth.json"
fi
model_args=()
[ -n "${OPENCODE_MODEL:-}" ] && model_args=(--model "$OPENCODE_MODEL")

cd "$dir" && XDG_DATA_HOME=$ORCH_ROOT/data/scan-$alias opencode run --auto --dir "$dir" \
  --title "SCAN $alias" "${model_args[@]}" "$msg" > "$ORCH_ROOT/logs/scan-$alias.log" 2>&1
code=$?
echo "__AGENT_DONE__ EXIT $code" >> "$ORCH_ROOT/logs/scan-$alias.log"
echo "scan $alias @ ${sha:0:7} → $out (exit $code)"
# After review: git -C "$src" worktree remove --force "$dir"
exit $code
