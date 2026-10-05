# Running opencode agents (what worked, what broke)

## Setup once per project

```sh
export ORCH_ROOT=~/Github/<repo>-wt/_orchestration      # NOT under /tmp
mkdir -p "$ORCH_ROOT"/{prompts,logs,data,bases}
cp <skill>/scripts/orch.env.example "$ORCH_ROOT/orch.env"  # edit REPO, WT_ROOT, INSTALL_CMD, MAX_PARALLEL
cp <skill>/templates/agent-header.md "$ORCH_ROOT/prompts/_header.md"  # fill the <…> placeholders once
```

`opencode` must already be logged in (`~/.local/share/opencode/auth.json`); `launch.sh` copies that file
(mode 600) into each agent's private data dir.

## Per agent

```sh
S=<skill>/scripts
$S/new-worktree.sh p7f-host-hardening origin/main prod      # worktree + branch prod/p7f-host-hardening + install
$EDITOR "$ORCH_ROOT/prompts/p7f-host-hardening.md"          # from templates/task-prompt.md
# launch in a background shell (Bash run_in_background), then attach a Monitor:
$S/launch.sh p7f-host-hardening '`apps/api-host/**`, `packages/module-sdk/src/contract/**`, `pnpm-lock.yaml` (via pnpm only)'
$S/watch.sh p7f-host-hardening 20                            # Monitor command: commits / STALL / FINISHED
```

Placeholders filled by `launch.sh` in `_header.md`: `__WT__`, `__BR__`, `__BASE__`, `__OWN__`.
Avoid `|` and `&` in the ownership text (they are `sed` metacharacters).

## Failure modes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| `Failed to execute statement` when 2+ agents run | shared `opencode.db` (SQLite) | private `XDG_DATA_HOME` per agent (launch.sh does it) |
| Server freezes; Claude Code background shells disappear | too many agents/test runs for the RAM | lower `MAX_PARALLEL`, run agents one at a time, `--filter` tests |
| Agent never starts working (no log growth after init) | stuck provider/session init | kill the process, delete nothing, relaunch |
| Agent exits 0 with the task half done | step/context limit | `resume.sh <name>` (continues the same session) |
| Completion detected too early | a doc the agent printed contained "EXIT=0" | watch for the launcher's unique marker `__AGENT_DONE__` only |
| Prompts/logs lost after reboot | kept in `/tmp` | keep everything in `$ORCH_ROOT` |
| Agent edits the owner's checkout | prompt did not forbid it | header forbids it; scope-check before merge |
| Merge conflict "resolved" with `--theirs` silently drops a fix from main | blind conflict resolution | resolve by hand, then rerun the tests of both sides |

## Security notes

- `--auto` approves tool permissions — only ever run it inside a disposable worktree.
- `$ORCH_ROOT/data/*` holds copies of `auth.json`: delete `data/` when the run is over.
- Never paste tokens into prompts; agents inherit the environment they need.
