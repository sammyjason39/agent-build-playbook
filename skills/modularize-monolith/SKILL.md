---
name: modularize-monolith
description: Split one large, overly complex repository into a modular monolith IN PLACE (strangler pattern) — measure real coupling (import graph, table ownership, git co-change), design the module map with the owner, add characterization tests and a boundary-violation ratchet, then extract modules leaf-first through small always-shippable steps executed by worker agents (opencode, pi, Antigravity, …), and decouple the database without downtime. Use when the user has a single big/legacy/tangled repo ("terlalu kompleks", "spaghetti", "god service") and wants it modular, wants boundaries, or wants it ready to split into services later.
---

# Modularize a monolith in place

This is the single-repo counterpart of `multi-repo-prd`. The difference that drives every rule: **the system is
live**. You cannot stop the world and rewrite. Every merged step must leave the app shippable and CI green, and
the boundary-violation count may only go down.

## Phase 1 — Measure (evidence, not opinions)
1. Pin the base commit. Set up `ORCH_ROOT` as described in `agent-orchestrator/references/opencode.md`.
2. Run `scripts/scan-monolith.sh <ALIAS> <repo> [ref] [depth] [roots]`. It does two things:
   - writes the git **coupling report** (hotspots, area churn, co-change pairs) to `scans/<ALIAS>.coupling.md`;
   - runs a read-only opencode analyst with `templates/scan-monolith-prompt.md`, which maps areas, the dependency
     graph and cycles, the table × area matrix, shared hot files, and candidate modules.
   Without opencode, produce the same report yourself.
   Tip: `depth` counts path segments down to where module candidates live (`src/modules/x` = 3).
3. Add the stack's **dependency-graph tool** from `references/analysis-tools.md`. Verify the scan's key claims
   yourself: cycles, multi-writer tables, cross-area joins. Then fill in the **boundary decision table**.
   A boundary is credible only when at least two signals agree (imports, data, change).

## Phase 2 — Decide with the owner
Present: the current-state map, the proposed module list with owned tables and contracts, the cycles to break,
the risky hotspots, and a wave plan. Ask only what changes the plan, with a recommended default for each:
- module mechanism (folders plus a boundary tool, or real packages/modules);
- DB strategy (schema per module vs prefix ownership; cross-module FKs → IDs);
- freeze or no freeze;
- parallelism appetite;
- whether any module is meant to become a separate service later.

Record the answers as `K-xx` in `docs/MODULARIZATION-PLAN.md` (`templates/MODULARIZATION-PLAN.md`). If the repo
also needs product-level docs (a PRD, a locked contract, a design system), reuse the templates from
`multi-repo-prd`. Their locking and RFC rules apply unchanged.

## Phase 3 — Safety net (wave M0, before any code moves)
Follow `references/strangler-playbook.md` Phase A:
- a green CI baseline, with flaky tests quarantined and listed;
- **characterization tests** for every hotspot that will move;
- the module skeleton with public surfaces;
- the boundary checker, plus **`scripts/ratchet.sh`** in CI: today's violations are the baseline, new ones fail the
  build, and fixed ones must be removed from the baseline.

## Phase 4 — Extract, leaf-first, in small tasks
For each module, run the per-module recipe in `references/strangler-playbook.md` Phase B: contract from real call
sites → facade → redirect callers per area → move internals → cut DB access (`references/db-decoupling.md`) →
break cycles → prove → shrink the baseline.

Turn each step into an agent task with `templates/extraction-task.md` and run it with `agent-orchestrator`:
worktree, launch, watch, review, merge, CI. Single-repo specifics:
- **Smaller tasks than greenfield.** "Facade" and "redirect area X" are separate tasks.
- **Caller files have owners too.** Two tasks run in parallel only if their module folders *and* the caller files
  they redirect are disjoint.
- **Shared hot files** (router, DI/app module, settings, i18n, lockfile) get one owner per wave, or the
  coordinator edits them on main between tasks.
- **Characterization tests must pass unedited.** An agent that needs to change one stops and reports.
- **Rebase before review.** In-place refactors conflict often. Resolve by hand and never with a blanket
  `--theirs`/`--ours`.

## Phase 5 — Harden and keep it modular
- Run `hardening-review-loop`, with these extra checks on top of its checklist:
  - the baseline is zero (or explicitly accepted), there are no cycles, and every table has one writer;
  - deprecated re-exports are removed, internals are private, and CODEOWNERS lists each module.
- Keep the checker and ratchet in CI permanently. That is what stops the monolith from re-tangling.
- Splitting a module into its own service later is now a deployment decision: contract and events already
  separate it. Use `monorepo-release` if modules become packages.

## Reporting to the owner
Report per wave in the owner's language:
- modules extracted;
- baseline count before → after;
- cycles removed;
- tables re-owned;
- CI status;
- anything that changed behaviour (it should be nothing; say so explicitly).

## Files
- `scripts/coupling-report.sh`: git-based hotspots, area churn and co-change (any language).
- `scripts/scan-monolith.sh`: coupling report plus a read-only opencode architecture scan.
- `scripts/ratchet.sh`: a baseline for boundary violations that can only shrink, for use with any checker.
- `references/`: `analysis-tools.md` (per-stack tools, decision table), `strangler-playbook.md` (phases A–C,
  parallelism) and `db-decoupling.md`.
- `templates/`: `scan-monolith-prompt.md`, `MODULARIZATION-PLAN.md` and `extraction-task.md`.
