# Finding the real boundaries

Three independent signals. A boundary is credible only when at least two of them agree.

## 1. Static dependency graph (who imports whom)

| Stack | Tool | Useful output |
|---|---|---|
| TypeScript/JS | `npx dependency-cruiser --init` then `npx depcruise src --output-type dot \| dot -Tsvg > deps.svg`; `npx madge --circular --extensions ts src` | cycles, cross-folder edges, orphans |
| Python | `import-linter` (contracts: layers, independence, forbidden), `pydeps pkg --max-bacon 2` | forbidden imports as lines (ratchet-friendly) |
| Java/Kotlin | `jdeps -verbose:package`, ArchUnit tests, Spring Modulith `ApplicationModules.of(App.class).verify()` | package cycles, module violations |
| Go | `go list -deps ./...`, `goda graph ./... \| dot`; internal/ packages as hard walls | package graph |
| .NET | NetArchTest, `dotnet-depends` | namespace rules as tests |
| PHP | deptrac (layers + collectors) | violations list |
| Ruby/Rails | packwerk (`bin/packwerk check`), `packs` | privacy/dependency violations with a todo baseline |

Record for each candidate module: inbound edges (who depends on it), outbound edges, and cycles it participates in.
Cycles are the first thing to break.

## 2. Data coupling (who touches which tables)

The import graph misses the strongest coupling in most monoliths, which is shared tables.

- Build a **table × code-area matrix**: grep the SQL/ORM usage per area. Examples:
  `rg -o "FROM\s+\w+|JOIN\s+\w+|INSERT INTO\s+\w+|UPDATE\s+\w+" <area>`, the ORM model imports per area, and
  Prisma `prisma.<model>` calls.
- Per table, mark the **writer areas** (should be exactly one, the owner) and the **reader areas**.
- Find **cross-area joins and foreign keys**. Each one becomes a contract call, a read model, or a reason to keep
  two areas in one module.
- Find the **god tables**, meaning many writers. They usually need splitting by lifecycle (for example
  `orders` → `orders` + `payments` + `fulfilment`).

## 3. Change coupling (what changes together)

Run `scripts/coupling-report.sh <repo> <depth> "<since>" <top> "<roots>"`:
- **hotspots** (churn × size) are where characterization tests are needed before anything moves;
- **co-change pairs** are either one module or a missing contract between two;
- set `depth` to the level where module candidates live (it counts path segments, e.g. `apps/backend/src/modules/x` = 5).

## 4. Runtime and ownership signals (optional but cheap)

- Route → handler → tables traces from logs or APM tell you which flows cross which areas.
- `git shortlog -sn -- <area>` shows who owns what today. Conway's law is real, so align modules with teams where
  possible.
- Feature flags and config keys per area show coupling through shared configuration.

## Output: the boundary decision table

| Candidate module | Owns tables | Inbound deps | Outbound deps | Cycles | Hotspots | Co-change partners | Decision |
|---|---|---|---|---|---|---|---|
| billing | invoices, invoice_lines | orders, reports | customers | billing↔orders | invoice.service.ts | orders (9) | module; contract `createInvoiceForOrder`; break cycle via event `order.completed` |
