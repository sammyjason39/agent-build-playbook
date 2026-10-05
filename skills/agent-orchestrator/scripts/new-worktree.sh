#!/usr/bin/env bash
# usage: new-worktree.sh <name> [base-ref] [branch-prefix]
# Creates $WT_ROOT/<name> on branch <prefix>/<name> from <base-ref> (default origin/main),
# installs dependencies once, and records the base commit for scope checks.
set -euo pipefail
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
: "${REPO:?set REPO in orch.env}" "${WT_ROOT:?set WT_ROOT}" "${ORCH_ROOT:?set ORCH_ROOT}"

name=$1; base=${2:-origin/main}; prefix=${3:-fix}
wt=$WT_ROOT/$name; branch=$prefix/$name
mkdir -p "$WT_ROOT" "$ORCH_ROOT"/{prompts,logs,data,bases}

git -C "$REPO" fetch -q origin 2>/dev/null || true
if [ -d "$wt" ]; then
  echo "worktree exists: $wt (branch $(git -C "$wt" branch --show-current))"
else
  git -C "$REPO" worktree add -q -b "$branch" "$wt" "$base"
  echo "created $wt on $branch from $(git -C "$wt" rev-parse --short HEAD)"
fi
git -C "$wt" rev-parse HEAD > "$ORCH_ROOT/bases/$name"

if [ -n "${INSTALL_CMD:-}" ]; then
  (cd "$wt" && eval "$INSTALL_CMD") > "$ORCH_ROOT/logs/$name.install.log" 2>&1 \
    && echo "deps installed" || { echo "install failed — see logs/$name.install.log"; exit 1; }
fi
