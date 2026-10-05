---
name: agent-orchestrator
description: Orchestrate CLI coding agents (opencode, pi, Antigravity agy, or any CLI) from a high-reasoning main AI. Split work into tasks with clear goals and exclusive file ownership, compute safe parallelism for the machine, run each worker in its own git worktree and data dir, watch it, review its diff and claims, merge, and drive CI to green. Works standalone on any repo and any language (no PRD needed). Use when the user wants work delegated to other agents, asks to "orchestrate", "dispatch", "run agents in parallel/one by one", "handover to opencode/pi/antigravity", or to execute a plan or prompt pack.
---

# Agent orchestrator — the main AI coordinates, CLI agents execute

You are the **coordinator**. Run on the strongest high-reasoning model available (e.g. Claude Opus 5.5 or GPT 6
Astra, with effort high). You do not write the feature code yourself. Instead you:
- read the code;
- split the work;
- write precise prompts;
- dispatch them to **worker** agents (opencode, pi, Antigravity `agy`, or a custom CLI);
- verify the results, merge, and own CI.

Workers can run at low or medium reasoning because your prompts carry the thinking: the goal, the scope, the
required behaviour, the tests and the out-of-scope list. See `references/executors.md`.

This skill is **standalone**. It works on any git repo and any stack. A plan from `multi-repo-prd` or
`modularize-monolith` is optional input, not a prerequisite.

## Quick start (any repo)
```sh
export ORCH_ROOT=~/code/<repo>-wt/_orchestration            # keep it outside /tmp
mkdir -p "$ORCH_ROOT"/{prompts,logs,data,bases}
cp <skill>/scripts/orch.env.example "$ORCH_ROOT/orch.env"   # set REPO, WT_ROOT, INSTALL_CMD, EXECUTOR, EXEC_EFFORT
cp <skill>/templates/agent-header.md "$ORCH_ROOT/prompts/_header.md"   # fill the <…> once (commands, laws)
```
Then, for each task:
1. `new-worktree.sh <name>` creates a worktree and branch.
2. Write `prompts/<name>.md` from `templates/task-prompt.md`.
3. Run `launch.sh <name> '<ownership>'` in the background.
4. Watch it with `watch.sh <name>`.
5. Review the result, then merge.

## Roles
- **Coordinator (you):** scheduling, prompts, scope enforcement, gates, merges, CI, reporting to the owner.
- **Worker:** one task, one worktree, an exclusive ownership list, and commits only on its own branch.
- **Owner (user):** decisions only. Ask when a product, security or architecture trade-off is involved, and
  record the answer in the repo (a decisions table or an ADR).

## Procedure

1. **Ground yourself.** Read the repo's rules (`AGENTS.md`/`CLAUDE.md`, contributing docs, architecture decisions)
   and the code you are about to delegate. Prompts written without reading the code produce workers that
   rediscover, or invent, the problem.
2. **Split and plan parallelism** (`references/parallelism.md`). Use one coherent ownership slice per task, and
   keep ownership disjoint between parallel tasks. Compute `MAX_PARALLEL` from RAM/CPU. On a small or shared
   machine, run workers **one at a time**. Write the plan as a short table.
3. **Set up once.** Follow the quick start above, filling `_header.md` with the repo's real commands and rules.
   Choose the `EXECUTOR` and `EXEC_EFFORT`.
4. **Per task:**
   1. `scripts/new-worktree.sh <name> [base] [prefix]`.
   2. Write `prompts/<name>.md` from `templates/task-prompt.md`. Satisfy the checklist in
      `references/executors.md`: a goal, ownership, requirements with file:line, tests, verification and
      out-of-scope.
   3. Run `scripts/launch.sh <name> '<ownership>' [executor]` in a **background** shell.
   4. Attach a watcher, `scripts/watch.sh <name>`. It emits commits, STALL and FINISHED.
   5. While it runs, do non-overlapping work, such as the next prompt or docs. Never touch the worker's files.
5. **On FINISHED, review before merge** (`references/review-merge.md`): read the report, check the scope
   (`scripts/scope-check.sh`), read the diff of the risky files, and re-run the gates yourself on the merged
   result. Claims are unverified until you have seen the output.
6. **Merge, push, and watch CI to the end** with `scripts/ci-watch.sh`. Fix red CI immediately. Red is never
   "done".
7. **Next task.** Sequential mode starts it after the previous merge is green. Parallel mode starts it when a slot
   frees up and its dependencies are merged.
8. **Clean up.** Remove merged worktrees and branches, delete `$ORCH_ROOT/data/` (it holds session data and may
   hold copies of credentials), and update the CHANGELOG or notes.

## Handling problems
- STALL with no progress means kill the process and relaunch. An exit of 0 with work left means
  `scripts/resume.sh <name>`.
- A worker failed twice on the same task. Raise `EXEC_EFFORT` or switch to a stronger worker model for that task.
  Better still, split the task smaller or make the prompt more specific.
- A worker proposes a change outside its ownership. Do it yourself on main, or make it a follow-up task. Never
  widen ownership silently.
- A worker hits an architectural or product decision. It stops and reports. You ask the owner and record the
  decision.
- A merge conflict. Resolve it by hand and re-run both sides' tests. Never use a blanket `--theirs`/`--ours`.

## Talking to the owner
- Report at milestones: task started or finished, the review verdict, the merge, the CI result.
- State failures plainly, with the cause and the fix.
- When a run takes long, say in one line what is running and what comes next.
- Use the owner's language for reports. Prompts and commits may stay in English.

## Files
- `scripts/`: `orch.env.example`, `new-worktree.sh`, `launch.sh` (opencode | pi | agy | custom), `resume.sh`,
  `watch.sh`, `scope-check.sh`, `ci-watch.sh`.
- `templates/`: `agent-header.md` (common worker header) and `task-prompt.md` (per-task prompt).
- `references/`: `executors.md` (models, executors, effort), `parallelism.md`, `opencode.md` (failure modes),
  `review-merge.md`.

Related skills, all optional:
- `multi-repo-prd` and `modularize-monolith` produce the plans this skill executes;
- `hardening-review-loop` runs the fix cycle;
- `monorepo-release` handles the release.
