---
name: multi-repo-prd
description: Turn several existing repositories into one modular product plan — scan each source repo deeply (optionally with read-only opencode agents), brainstorm with the owner, then write a PRD with locked owner decisions, a locked module contract and design system, a module catalog with a coverage map, and a one-shot prompt pack (common brief, wave briefs, one spec per module) that coding agents can execute in parallel. Use when the user wants to merge/consolidate/modularise repos, "make a PRD from these repos", plan a modular monolith or marketplace of modules, or prepare oneshot prompts for agents.
---

# Multi-repo → modular product plan + prompt pack

Output: a planning set that lets many agents build in parallel **without inventing decisions**. Every ambiguity is
either answered by the owner (recorded as `K-xx`) or written down as an open question. This skill plans only;
execution is `agent-orchestrator`.

## Phase 1 — Scan (evidence first)
1. Clone or pull every source repo side by side, and **pin a SHA per source**. All later documents cite it.
2. Scan each repo with `scripts/scan.sh <ALIAS> <path> [ref]`. It runs a read-only opencode analyst in a
   disposable detached worktree, using `templates/scan-prompt.md`, and writes `$ORCH_ROOT/scans/<ALIAS>.md`.
   Run the scans sequentially on small machines, or in parallel if `agent-orchestrator/references/parallelism.md`
   allows. Without opencode, do the same scan yourself with the same report structure.
3. **Verify the scans yourself.** Open the cited files for the important claims (tenancy, money types, auth,
   integrations, AI tools). Scans are leads, not truth.

## Phase 2 — Brainstorm with the owner
Present one synthesis: what each repo is best at, the overlaps, the debt not to carry, and a first module list by
layer. Then ask only the questions that change the plan, at most 4 at a time, each with a recommended default:
- stack (follow one of the sources?);
- packaging (modular monolith with service-grade boundaries vs services now);
- target repo and who consumes the modules;
- ownership of system pieces (AI core, approvals/audit/notifications);
- parallelism appetite;
- design reference (which existing UI to match);
- missing modules the owner needs (e.g. projects + timesheet).

Record every answer immediately as a `K-xx` row in the PRD §0. Never re-ask a recorded decision.

## Phase 3 — Write the planning set (in the target repo, `docs/`)
Write them in this order. Each one cites the previous:

| File | Template | Rules |
|---|---|---|
| `PRD.md` | `templates/PRD.md` | Owner's language. §0 locked decisions, source analysis with SHAs, waves, DoD |
| `MODULE-CONTRACT.md` | `templates/MODULE-CONTRACT.md` | English. §0 ADRs `A-xx`, **LOCKED**; changes only by RFC |
| `DESIGN.md` | `templates/DESIGN.md` | Tokens copied verbatim from the reference UI; archetypes; **LOCKED** |
| `CATALOG.md` | `templates/CATALOG.md` | Index, dependency table (the source for waves), **coverage map for every source feature** |
| `prompts/00-COMMON-BRIEF.md` | `templates/COMMON-BRIEF.md` | Sources at pinned SHAs, hard rules, 11-step procedure |
| `prompts/W0-*.md`, `W2-*.md`, `W3-*.md` | free form | Per wave: tasks, ownership, gate |
| `prompts/modules/<key>.md` | `templates/module-spec.md` | One per module. Keep/Generalise/Drop with source paths; contract; events; tools; acceptance |
| `prompts/README.md` | `templates/wave-dispatch.md` | Dispatch order, parallel counts, agent message template |
| `ORCHESTRATION-PLAN.md` | see `agent-orchestrator/references/parallelism.md` | Iterations, batches, gates, risks |
| `rfcs/README.md` | `templates/rfc.md` | The only path to change locked docs |
| `AGENTS.md` | short | Binding rules for any agent: laws, ownership, commands, conventions |

### Quality bar for the prompt pack
- **One-shot:** an agent with the repo plus the common brief plus its spec can finish without asking. If it would
  need to ask, the answer belongs in the spec.
- **Exclusive ownership:** every task names the paths it may write. Shared files have one owner (see
  orchestrator parallelism §2).
- **Stubs break the DAG:** W0 publishes contracts and stubs for foundation modules, so W1 can fan out.
- **Acceptance is testable:** invariants, concurrency, money/time correctness, isolation through the real
  runtime path, and evals for every tool.
- **Coverage is complete:** every source feature appears in the coverage map with a home or a reasoned drop.
- **Consistency:** module counts and keys must match across PRD, CATALOG, the prompts and the dispatch table.
  Grep for them before you commit.

## Phase 4 — Hand over
Commit and push (ask first if the repo is shared). Then summarise for the owner:
- what was written;
- the open questions;
- the recommended first wave and its concurrency for their machine.

Continue with `agent-orchestrator` to execute it.

## Lessons from the reference run
- Locking architecture and design early let 39 modules be built by different agents and still look and behave
  the same.
- Late owner decisions (an embedding dimension, the token lifetime, public endpoints) still came up. Keep the
  `K-xx` table alive and add RFCs with the next number.
- Agents copied real bugs from sources (for example a wrong payment-signature algorithm). The spec should name
  "verify against the provider docs" for anything security-sensitive.
