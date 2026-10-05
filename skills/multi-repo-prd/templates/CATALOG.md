# Module Catalog

Every module, its dependencies, and a **coverage map proving every source feature has a home** (or an explicit
"platform" / "dropped" decision with a reason). Full specs: `prompts/modules/<key>.md`.

## 1. Index
| # | Key | Layer | Wave slot | Primary source | Spec |
|---|---|---|---|---|---|

## 2. Dependencies
`dependsOn` = hard (must be enabled) · `enhances` = optional integration.
| Module | dependsOn | enhances / uses if enabled | Consumed by |
|---|---|---|---|

The orchestrator derives waves from this table (topological layers); keep it the single source of truth.

## 3. Coverage map
`→ platform` = owned by the platform team · `→ SDK` = kernel interface · `✗` = dropped (reason).
### 3.0 New modules (no source) — why, borrowed patterns
### 3.<n> <ALIAS> — <source path> (@ <sha>)
| Source feature (path) | Home |
|---|---|

## 4. Bundles (marketplace metadata)
| Bundle | Modules | Target customer |
|---|---|---|
