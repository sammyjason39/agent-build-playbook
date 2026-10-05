# Module Contract — `<sdk package>` v0

Status: **LOCKED <date>** (owner decision K-xx). Later waves may add detail but not change §0; any change goes
through `docs/rfcs/` with owner approval. Language: English (read by engineers and AI agents).

Goal: every module runs in-process today, yet can be lifted into its own service or repository later
**without rewriting callers**. Every rule exists to keep that door open.

## 0. Locked architecture decisions
| # | Decision |
|---|---|
| A-01 | Modular monolith; every module extractable later without changing callers (§12). |
| A-02 | Stack + exact major versions: … |
| A-03 | One folder per module; `contract/` is the only public surface. |
| A-04 | One DB schema per module; no cross-schema SQL, joins, or foreign keys. |
| A-05 | Cross-module only via serializable contracts, versioned events through a transactional outbox, or tools. No distributed transactions (reserve → confirm/release). |
| A-06 | Tenancy model (e.g. shared DB + `tenant_id` + RLS ENABLE/FORCE + non-owner NOBYPASSRLS runtime role). |
| A-07 | API convention (prefix, OpenAPI, permission guard on every route, audit on every mutation). |
| A-08 | AI: every capability is a tool; one execution gate (identity → permission → schema → risk/confirmation → audit); identity never from tool input. |
| A-09 | Ownership of system modules and kernel reference implementations. |
| A-10 | Extension points are the only way one module augments another. |
| A-11 | Money/quantity/time types; timezone source. |
| A-12 | UI only through the shared UI kit, per DESIGN.md. |

## 1. Repository layout
## 2. Module folder (`manifest.ts`, `contract/`, `backend/`, `agent/`, `frontend/`, `migrations/`, `tests/`)
## 3. Manifest (fields, validation)
## 4. Contracts (sync calls; stubs; versioning)
## 5. Events (naming, envelope, outbox, idempotent consumers)
## 6. Tools (risk, confirmation, audience, evals)
## 7. Database conventions (schema, RLS template, ids, money, time, migrations)
## 8. Kernel interfaces (provided by the platform; reference impls in the dev kernel)
## 9. Extension points
## 10. Testing (isolation through the real runtime path, contract suite, property tests, evals)
## 11. Datasets (reporting)
## 12. Lifting a module into its own service
## 13. Lint rules (boundaries, design tokens, SQL schema access)
