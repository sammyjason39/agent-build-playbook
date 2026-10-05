#!/usr/bin/env bash
# usage: scan-monolith.sh <ALIAS> <local-repo-path> [ref] [depth] [roots]
# 1. writes $ORCH_ROOT/scans/<ALIAS>.coupling.md with coupling-report.sh
# 2. runs a read-only opencode analyst (templates/scan-monolith-prompt.md + that evidence) in a
#    disposable detached worktree pinned to <ref>; report → $ORCH_ROOT/scans/<ALIAS>.md
set -u
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
: "${ORCH_ROOT:?export ORCH_ROOT first}"
here=$(cd "$(dirname "$0")" && pwd)

alias=$1; src=$2; ref=${3:-HEAD}; depth=${4:-3}; roots=${5:-}
sha=$(git -C "$src" rev-parse "$ref")
dir=$ORCH_ROOT/scan-src/$alias
mkdir -p "$ORCH_ROOT"/{scans,logs,data,scan-src}
if [ ! -d "$dir" ]; then git -C "$src" worktree add -q --detach "$dir" "$sha"; fi

coupling=$ORCH_ROOT/scans/$alias.coupling.md
"$here/coupling-report.sh" "$dir" "$depth" "12 months ago" 30 "$roots" > "$coupling"
echo "coupling evidence → $coupling"

out=$ORCH_ROOT/scans/$alias.md
msg=$(SRC="$dir" SHA="$sha" OUT="$out" COUPLING_FILE="$coupling" python3 - "$here/../templates/scan-monolith-prompt.md" <<'PY'
import os, sys
t = open(sys.argv[1]).read()
for k in ("SRC", "SHA", "OUT"):
    t = t.replace(f"__{k}__", os.environ[k])
t = t.replace("__COUPLING__", open(os.environ["COUPLING_FILE"]).read())
print(t)
PY
)

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
