# In-place modularization (strangler) — the per-module recipe

Rule zero: **the application is shippable after every merged step.** There are no long-lived refactor branches
and no big-bang rewrites. If a step cannot keep CI green, split it smaller.

## Phase A — Make change safe (once, before the first extraction)
1. **Green baseline.** CI runs lint, typecheck and tests on every PR. Fix or quarantine flaky tests (list them; do
   not delete them).
2. **Characterization tests on hotspots.** Pin the current behaviour, warts included, of the files the coupling
   report ranks highest: HTTP-level golden tests, snapshot tests of service outputs, and DB state assertions.
   They exist to detect change, not to judge correctness.
3. **Target layout skeleton.** Create `modules/<key>/` (or the stack's equivalent: packages, Gradle modules,
   Python packages, Go internal packages) with a **public API surface** per module (`contract/`, `api/`,
   `__init__.py` exports, or `public` packages) and an `internal/` area that others may not import.
4. **Boundary checker + ratchet.**
   - Configure the tool from `analysis-tools.md` with the target rules: only public surfaces may be imported, and
     each module's tables may be touched only by that module.
   - Record today's violations with `scripts/ratchet.sh --update .boundaries-baseline -- <checker>` and run
     `scripts/ratchet.sh .boundaries-baseline -- <checker>` in CI.
   - From now on, no new violations are allowed, and every extraction shrinks the baseline.

## Phase B — Extract one module (repeat per module, leaves first)
Order: modules with **few inbound dependencies and clear table ownership** first (leaves), and god modules last.
Break cycles before extracting either side.

1. **Define the contract** the rest of the code needs from this module: functions or DTOs for synchronous needs,
   events for "something happened" needs. Derive it from the actual inbound call sites, not from wishes.
2. **Create the facade** in `modules/<key>/contract` that delegates to the existing code. No behaviour change.
3. **Redirect callers** to the facade, one area at a time, in small commits. The ratchet baseline shrinks.
4. **Move the implementation** behind the facade into `modules/<key>/internal`. Keep the old paths as thin
   re-exports only if external consumers need them, and mark them deprecated with a removal date.
5. **Cut cross-module DB access.** Other modules read through the contract, a read model, or events. Reverse
   foreign keys into the module become IDs without FKs (keep integrity with application checks plus reconciliation
   jobs), following `db-decoupling.md`.
6. **Cut cycles** with events (outbox) or dependency inversion (an interface owned by the consumer, implemented by
   the provider).
7. **Prove it:**
   - the characterization tests are unchanged and green;
   - the module's own tests pass;
   - the boundary checker shows zero violations for `<key>`;
   - the module builds or tests in isolation where the stack allows it.
8. **Shrink the baseline** (`ratchet.sh --update`) in the same PR.

## Phase C — Harden the walls
- Remove the deprecated re-exports.
- Make the module's internals truly private (package visibility, `internal/`, exports maps).
- Give each module its own DB schema or table-prefix ownership, its own migrations folder, and its own CODEOWNERS
  entry.
- Optional: extract a module into its own deployable service only when there is a scaling, team or release-cadence
  reason. The contract plus events make that a deployment change rather than a rewrite.

## Parallelism inside one repo (stricter than multi-repo)
- Two extractions may run in parallel only if their **ownership sets are disjoint**, including the caller files
  they will redirect. Redirecting callers touches other areas, so plan who owns each caller file.
- Shared hot files (routers, DI containers, `app.module`, settings, i18n bundles, lockfiles) get **one owner per
  wave**. Other agents propose edits in their reports, and the coordinator applies them on main between tasks.
- Prefer more, smaller tasks: "facade + redirect area X" is a good task, and "extract billing" is too big for one
  agent.
- Rebase each worktree on main before review. In-place refactors conflict far more often than greenfield modules.
