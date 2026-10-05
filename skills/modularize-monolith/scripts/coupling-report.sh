#!/usr/bin/env bash
# usage: coupling-report.sh [repo=.] [depth=2] [since="12 months ago"] [top=25] [roots="src app lib packages"]
#
# Language-agnostic coupling evidence from git history (no build needed):
#   1. hotspots  — most-changed files (churn) with current line count; refactor risk lives here
#   2. area churn — commits per directory at <depth> (candidate module areas)
#   3. co-change — pairs of areas that change in the same commit (hidden coupling the import
#                  graph may not show: shared tables, config, copy-pasted logic)
# Commits touching more than 40 files are ignored (formatting/renames/mass edits).
# Combine with an import graph (references/analysis-tools.md) before drawing boundaries.
set -eu  # no pipefail: `head` closing pipes early is intended
repo=${1:-.}; depth=${2:-2}; since=${3:-12 months ago}; top=${4:-25}
roots=${5:-}
cd "$repo"
git rev-parse --is-inside-work-tree >/dev/null

log=$(mktemp); trap 'rm -f "$log"' EXIT
# One block per commit: "@@" separator, then changed paths.
git log --since="$since" --no-merges --name-only --pretty=tformat:@@ -- . > "$log"

filter_roots() {
  if [ -z "$roots" ]; then cat; return; fi
  local re
  re="^($(echo "$roots" | tr ' ' '|'))/"
  grep -E "$re" || true
}

echo "# Coupling report — $(basename "$(pwd)") (since $since, depth $depth)"
echo
echo "Commits analysed: $(grep -c '^@@' "$log")"
echo

echo "## 1. Hotspots (top $top files by commits)"
echo
echo "| commits | lines | file |"
echo "|---:|---:|---|"
grep -v '^@@' "$log" | sed '/^$/d' | filter_roots | sort | uniq -c | sort -rn | head -n "$top" |
  while read -r n f; do
    l=$( [ -f "$f" ] && wc -l < "$f" | tr -d ' ' || echo "deleted")
    echo "| $n | $l | \`$f\` |"
  done
echo

echo "## 2. Area churn (commits touching each area, depth $depth)"
echo
echo "| commits | area |"
echo "|---:|---|"
awk -v RS='@@' -v d="$depth" '
  NF>0 && NF<=40 {
    split("", seen)
    n=split($0, lines, "\n")
    for (i=1;i<=n;i++) { f=lines[i]; if (f=="") continue
      m=split(f, p, "/"); a=p[1]; for (j=2;j<=d && j<m;j++) a=a"/"p[j]
      if (!(a in seen)) { seen[a]=1; print a } }
  }' "$log" | filter_roots | sort | uniq -c | sort -rn | head -n "$top" |
  while read -r n a; do echo "| $n | \`$a\` |"; done
echo

echo "## 3. Co-change between areas (top $top pairs)"
echo
echo "| shared commits | area A | area B |"
echo "|---:|---|---|"
awk -v RS='@@' -v d="$depth" -v roots="$roots" '
  BEGIN { nr=split(roots, R, " ") }
  function keep(f,   k) { if (nr==0) return 1; for (k=1;k<=nr;k++) if (index(f, R[k]"/")==1) return 1; return 0 }
  NF>0 && NF<=40 {
    split("", seen); k=0
    n=split($0, lines, "\n")
    for (i=1;i<=n;i++) { f=lines[i]; if (f=="" || !keep(f)) continue
      m=split(f, p, "/"); a=p[1]; for (j=2;j<=d && j<m;j++) a=a"/"p[j]
      if (!(a in seen)) { seen[a]=1; list[++k]=a } }
    for (x=1;x<=k;x++) for (y=x+1;y<=k;y++) {
      if (list[x] < list[y]) print list[x] "\t" list[y]; else print list[y] "\t" list[x] }
  }' "$log" | sort | uniq -c | sort -rn | head -n "$top" |
  while read -r n a b; do echo "| $n | \`$a\` | \`$b\` |"; done
echo
echo "Read it as: high churn + high line count = split carefully (characterization tests first);"
echo "high co-change between two areas = either one module, or a missing contract between them."
