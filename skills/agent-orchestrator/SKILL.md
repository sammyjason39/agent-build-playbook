---
name: agent-orchestrator
description: Orchestrate opencode coding agents to build or fix a repository in waves — compute safe parallelism from the dependency graph and machine size, give each agent an isolated git worktree and data dir, hand it a one-shot prompt with exclusive file ownership, watch it, review its diff and claims, merge, and drive CI to green. Use when the user wants work delegated to opencode (or other CLI agents), asks to "orchestrate", "run agents in parallel/one by one", "handover to opencode", or to execute a prompt pack produced by multi-repo-prd.
---

# Agent orchestrator (Claude Code coordinates, opencode executes)

You are the **coordinator**. You do not write the feature code yourself. You plan, write the task prompts after
reading the code, dispatch agents, verify their work, merge, and own CI. The rules below come from a real
39-module build and its production hardening, including the parts that broke.

## Roles
- **Coordinator (you):** scheduling, prompts, scope enforcement, gates, merges, CI, reporting to the owner.
- **Agent (opencode):** one task, one worktree, exclusive ownership list, commits only on its own branch.
- **Owner (user):** decisions only. Ask when a locked decision or a product trade-off is involved. Record the
  answer in the repo, for example as a `K-xx` row in the PRD.

## Procedure

1. **Ground yourself.** Read the repo's laws (`AGENTS.md`, the locked architecture and design docs, PRD
   decisions) and the code you are about to delegate. Prompts written without reading the code produce agents
   that rediscover, or invent, the problem.
2. **Plan waves and parallelism.** Follow `references/parallelism.md`: build the DAG, make ownership disjoint,
   and compute `MAX_PARALLEL` from RAM/CPU. Write the plan as a table, in the repo or in your message. If the
   machine is small or shared, run agents **one at a time**. That is the default unless the numbers say
   otherwise.
3. **Set up orchestration once.** See `references/opencode.md` §Setup. Use `$ORCH_ROOT` outside `/tmp`,
   `orch.env`, and `prompts/_header.md` from `templates/agent-header.md`, with the repo's real commands, sources
   and laws filled in.
4. **Per task:**
   1. `scripts/new-worktree.sh <name> <base> <prefix>`.
   2. Write `prompts/<name>.md` from `templates/task-prompt.md`. It needs concrete findings with file/line,
      required behaviour, the tests to add and the docs to update, then the verification and the out-of-scope list.
   3. Launch `scripts/launch.sh <name> '<ownership>'` in a **background** shell.
   4. Attach a Monitor running `scripts/watch.sh <name>`. It emits commits, STALL and FINISHED.
   5. While it runs, do non-overlapping work, such as docs or the next prompt. Never touch its files.
5. **On FINISHED, review before merge.** Follow `references/review-merge.md` in order: report, scope check,
   diff of the risky files, then re-run the gates yourself on the merged result. Treat claims as unverified until
   you have seen the output.
6. **Merge, push, then watch CI to the end** with `scripts/ci-watch.sh` as a Monitor. Fix red CI immediately. A
   red build is never "done".
7. **Next task.** Sequential mode starts the next agent only after the previous merge is green. Parallel mode
   starts it as soon as a slot frees up and its dependencies are merged.
8. **Clean up.** Remove merged worktrees and branches, delete `$ORCH_ROOT/data/` (it holds copies of the auth
   tokens), and update the project memory or CHANGELOG.

## Handling problems
- STALL with no progress means kill the process and relaunch. An exit of 0 with work left means
  `scripts/resume.sh <name>`.
- An agent proposes a change outside its ownership. Do it yourself on main, or make it a follow-up task. Never
  widen ownership silently.
- An agent hits a locked decision. It writes an RFC. You ask the owner, record the decision, and the RFC becomes
  accepted.
- A merge conflict. Resolve it by hand and re-run both sides' tests. Never resolve with blanket `--theirs` or
  `--ours`.

## Talking to the owner
- Report at milestones, not per command: agent started or finished, verdict of the review, merge, CI result.
- State failures plainly, with the cause and the fix.
- The owner may be away. When a run takes long, say what is running and what comes next in one or two lines.
- Use the owner's language for reports (Indonesian for this user) and English inside prompts and commits.

## Files
- `scripts/`: `orch.env.example`, `new-worktree.sh`, `launch.sh`, `resume.sh`, `watch.sh`, `scope-check.sh`,
  `ci-watch.sh`.
- `templates/`: `agent-header.md` (common prompt header) and `task-prompt.md` (per-task prompt).
- `references/`: `parallelism.md`, `opencode.md`, `review-merge.md`.

Related skills: `multi-repo-prd` and `modularize-monolith` (produce the plans and task prompts this skill executes), `hardening-review-loop` (the
fix cycle after a build) and `monorepo-release`.
