# Planning waves and parallelism

The goal is the largest safe batch of agents that (a) never write the same files, (b) never block on each
other's unfinished work, and (c) fit the machine.

## 1. Build the dependency DAG

From the catalog (module → `dependsOn`), compute layers with a topological sort:

```
layer 0: modules with no dependencies (foundation/system)
layer k: modules whose dependencies are all in layers < k
```

Contracts break the DAG: if every dependency publishes a **contract + stub** first (wave W0), every later module
can build against stubs, so all of W1 becomes one layer. That is the main lever for parallelism — pay for it
with one careful contract wave and a gate.

## 2. Ownership must be disjoint

Two tasks may run in parallel only if their ownership globs do not intersect. Shared files are the usual
collisions; give each exactly one owner or serialise them:

| Shared file | Rule |
|---|---|
| lockfile (`pnpm-lock.yaml`) | many may change it *via the package manager only*; merge conflicts are resolved by re-running install on main |
| host registration (`apps/*/modules.ts`, wiring) | owned by the coordinator; agents propose additions in their report |
| SDK / shared packages | frozen after W0; changes only through RFC + one owner |
| generated docs | never hand-edited; regenerated on main after merge |

## 3. Fit the machine

```
per_agent_ram  ≈ agent process (0.5–1 GB) + the heaviest command it runs (tests: 1–2 GB; embedded DB: +0.5 GB)
max_by_ram     = floor((RAM_total − reserve) / per_agent_ram)     # reserve: OS + owner's own sessions (≥ 1.5 GB)
max_by_cpu     = CPU_cores (agents idle while the model thinks, but test runs peg cores)
MAX_PARALLEL   = min(ready_disjoint_tasks, max_by_ram, max_by_cpu, api_budget_cap)
```

Reference point that actually happened: 4 CPU / 7.5 GB with the owner's own opencode session running →
parallel agents exhausted memory and background shells were reaped → **MAX_PARALLEL = 1**. On a 16 GB / 8 core
machine, 3–4 is realistic; on a dedicated 32 GB runner, 8–10 (the API budget becomes the limit).

Parallel `opencode run` processes **must** each have their own `XDG_DATA_HOME`; they otherwise share one SQLite
database and fail with `Failed to execute statement`.

## 4. Order inside a layer when concurrency is capped

1. Modules others consume most (fewer stubs to churn later).
2. Modules with the most source code to port (longest tasks start first).
3. Leaf/add-on modules last.
4. The integrator-heavy module (e.g. POS that consumes many contracts) last in its batch.

## 5. Gates between waves

A wave does not advance until its gate is green: lint (zero warnings), typecheck, boundary lint, tests of every
merged package, plus the wave-specific checks (contracts + stubs exist; per-module Definition of Done; journeys).
A worker's report is not evidence — the gate is.

## 6. Write the plan down

Record the result as a table in the repo (`docs/ORCHESTRATION-PLAN.md`):

| Iter. | Contents | Parallel | Gate exit |
|---|---|---|---|
| I0 | bootstrap + contracts/stubs | 1–2 | full gate green, example module end-to-end |
| I1 | foundation modules | n | per-module DoD |
| I2 | business modules in batches ≤ cap | cap, cap, rest | per-module DoD |
| … | integration journeys, security, release | … | … |
