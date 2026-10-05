# Dispatch guide (docs/prompts/README.md)

Every task prompt = **`00-COMMON-BRIEF.md` + the task file**.

| Order | Task | Files | Parallel |
|---|---|---|---|
| 1 | W0-A SDK + dev host + tooling | `W0-contracts.md` §W0-A | 1 |
| 1 | W0-B foundation contracts + stubs | `W0-contracts.md` §W0-B | 1 |
| — | **Gate G0** | | — |
| 2 | W1-F foundation modules | `modules/<key>.md` | n |
| 2 | W1-B business modules (batches ≤ cap) | `modules/<key>.md` | cap |
| 2 | W1-A add-ons | `modules/<key>.md` | n |
| — | **Gate G1** (per-module DoD) | | — |
| 3 | W2 integration per bundle + security | `W2-integration.md` | bundles + 1 |
| — | **Gate G2** | | — |
| 4 | W3 release | `W3-release.md` | few |
| — | **Gate G3** | | — |

## Message to a W1 agent
```
You own module `<key>` in <repo>. Read, in order: docs/prompts/00-COMMON-BRIEF.md, docs/MODULE-CONTRACT.md,
docs/DESIGN.md, docs/prompts/modules/<key>.md. Follow the 11-step procedure, committing after each step.
Write only inside modules/<key>/ (and new files in docs/rfcs/). Use dependency contract stubs for anything
not built yet. Run the boundary lint and the module's tests before you finish. Report per step 11.
```

## Coordinator duties
- Merge RFCs that touch frozen contracts; notify affected owners.
- Keep host registration in sync as modules land.
- Run the gate on every merge; reject boundary violations (`git diff --name-only <base> | grep -v '^modules/<key>/'`).
