#!/usr/bin/env bash
# usage: ci-watch.sh <run-id>            — emit each finished job, then "RUN DONE: <conclusion>"
#        ci-watch.sh --latest <branch>   — same, for the newest run on <branch>
# Designed as a Monitor command (one line per event, exits when the run completes).
if [ "$1" = "--latest" ]; then
  sleep 8
  R=$(gh run list --branch "$2" --limit 1 --json databaseId -q '.[0].databaseId')
else
  R=$1
fi
echo "watching run $R"
prev=""
while true; do
  s=$(gh run view "$R" --json status,conclusion,jobs 2>/dev/null) || { sleep 30; continue; }
  cur=$(echo "$s" | jq -r '.jobs[]|select(.status=="completed")|"\(.name): \(.conclusion)"' | sort)
  comm -13 <(echo "$prev") <(echo "$cur")
  prev=$cur
  if [ "$(echo "$s" | jq -r .status)" = completed ]; then
    echo "RUN DONE: $(echo "$s" | jq -r .conclusion)"
    exit 0
  fi
  sleep 45
done
