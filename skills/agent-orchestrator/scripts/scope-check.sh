#!/usr/bin/env bash
# usage: scope-check.sh <name> '<ERE of allowed paths>'
# Lists files the agent changed since its base and fails if any is outside its ownership.
# Example: scope-check.sh p7f '^(apps/api-host/|packages/module-sdk/src/contract/|modules/employee-app/|pnpm-lock\.yaml$)'
: "${ORCH_ENV:=${ORCH_ROOT:-}/orch.env}"
# shellcheck disable=SC1090
if [ -f "$ORCH_ENV" ]; then source "$ORCH_ENV"; fi
name=$1; allowed=$2
wt=$WT_ROOT/$name
base=$(cat "$ORCH_ROOT/bases/$name")
changed=$(git -C "$wt" diff --name-only "$base"..HEAD; git -C "$wt" status --short | awk '{print $2}')
echo "$changed" | sort -u | sed '/^$/d' > "$ORCH_ROOT/logs/$name.changed"
outside=$(grep -Ev "$allowed" "$ORCH_ROOT/logs/$name.changed" || true)
echo "changed: $(wc -l < "$ORCH_ROOT/logs/$name.changed") file(s); uncommitted: $(git -C "$wt" status --short | wc -l)"
if [ -n "$outside" ]; then echo "OUT OF SCOPE:"; echo "$outside"; exit 1; fi
echo "scope OK"
