---
name: hardening-review-loop
description: Review code produced by coding agents (or anyone) for production readiness, turn findings into tightly-scoped fix tasks for opencode agents, verify every fix yourself, merge, and repeat until CI is green and the checklist is clean. Use when the user asks to check/review an agent's work, "is it on the right track", "fix everything until production ready", or after a build wave finishes.
---

# Hardening review loop

The cycle: **assess → findings → fix tasks → agents → verify → merge → CI → reassess**. It ends when the
checklist is clean, CI is green, and the remaining items are owner decisions you have asked about. It does not
end at "the agent says done".

## 1. Assess (yourself first)
- Read the laws (`AGENTS.md`, the locked docs, PRD decisions) and the area under review.
- Run the real gates locally, sequentially on small machines: lint (zero warnings), typecheck, boundary lint, and
  tests of the area. A failing test you observed beats any report.
- Walk `references/checklist.md`. Every item there was a real defect in the reference build.
- For a large surface, you may also dispatch a **read-only review agent** with
  `templates/review-agent-prompt.md`, through `agent-orchestrator/scripts/launch.sh` in a worktree. Treat its
  findings as leads and confirm each one in the code.

## 2. Findings → tasks
Write each finding as: file:line → concrete input → wrong result → why it matters. Group the findings into tasks
by **ownership slice**, meaning disjoint paths, so tasks can run in parallel when the machine allows. For each
task, write a prompt with `agent-orchestrator/templates/task-prompt.md` that includes:
- the findings verbatim;
- the required behaviour, including names, env vars and defaults;
- the tests to add, through the real path;
- the docs to update;
- the out-of-scope list.

If a fix needs a product or security trade-off, **ask the owner** with options and a recommendation. Record
the answer as `K-xx` and write an RFC when a locked doc changes. Examples: public access without login, token
lifetime, embedding dimension, publishing.

## 3. Execute
Use `agent-orchestrator`: worktree, launch, watch, review the diff, check scope, re-run the gates, merge, push,
watch CI. While an agent runs, do the non-overlapping work yourself, such as docs, the next prompt, or small fixes
outside its ownership.

## 4. Verify the claims
For every "fixed" claim, find the test that proves it and run it. Also read the diff for:
- self-approval paths;
- fail-open defaults;
- blanket conflict resolutions;
- tests that only mirror the implementation;
- off-by-one-second timing.

If you discover your own earlier fix was wrong, say so plainly to the owner and fix it.

## 5. Close the loop
- Keep CI green after every merge. If it is red, read `--log-failed`, fix, push, watch again.
- Update the CHANGELOG, the adoption or integration docs, and the PRD decisions.
- Report to the owner in their language:
  - what was fixed, with evidence (test counts, CI run);
  - what remains, why, and which decision you need from them.
- Clean up worktrees and agent data dirs.

## Files
- `references/checklist.md`: the production-readiness checklist.
- `templates/review-agent-prompt.md`: the read-only reviewer prompt.
