#!/usr/bin/env bash
# usage: ratchet.sh <baseline-file> -- <command that prints one violation per line>
#        ratchet.sh --update <baseline-file> -- <command>
#
# A boundary "ratchet": existing violations are allowed (recorded in the baseline), NEW ones
# fail the build, and fixed ones must be removed from the baseline (so it only shrinks).
# Works with any checker that prints violations as stable lines, e.g.:
#   dependency-cruiser:  npx depcruise src --output-type err-long | grep -E '^\s*(error|warn)'
#   import-linter:       lint-imports --no-cache 2>&1 | grep -E '^- '
#   grep-based:          grep -rnoE "from '(\.\./)+modules/[a-z-]+/(internal|repo)" src | cut -d: -f1,3
# Keep line numbers OUT of violation lines (they change on every edit) — use file + target.
set -uo pipefail
update=0
if [ "${1:-}" = "--update" ]; then update=1; shift; fi
baseline=${1:?baseline file}; shift
[ "${1:-}" = "--" ] && shift
[ $# -gt 0 ] || { echo "usage: ratchet.sh [--update] <baseline> -- <command>"; exit 2; }

current=$(mktemp); trap 'rm -f "$current"' EXIT
"$@" 2>/dev/null | sed 's/[[:space:]]*$//' | sed '/^$/d' | sort -u > "$current" || true

if [ $update = 1 ] || [ ! -f "$baseline" ]; then
  cp "$current" "$baseline"
  echo "ratchet: baseline written ($(wc -l < "$baseline") violation(s)) → $baseline"
  exit 0
fi

sort -u "$baseline" -o "$baseline"
new=$(comm -13 "$baseline" "$current")
fixed=$(comm -23 "$baseline" "$current")
echo "ratchet: baseline $(wc -l < "$baseline"), current $(wc -l < "$current")"
if [ -n "$fixed" ]; then
  echo "fixed (remove from baseline with --update):"; echo "$fixed" | sed 's/^/  - /'
fi
if [ -n "$new" ]; then
  echo "NEW boundary violations (not allowed):"; echo "$new" | sed 's/^/  + /'
  exit 1
fi
if [ -n "$fixed" ]; then
  echo "baseline is stale — run with --update and commit it (the ratchet only shrinks)"; exit 1
fi
echo "ratchet: OK"
