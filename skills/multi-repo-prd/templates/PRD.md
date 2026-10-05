# PRD — <Product name>

Status: draft · Owner: <name> · Language: <owner's language> (engineering docs stay English)

## 0. Locked decisions
Every owner answer becomes a row; later documents cite the ID. Never delete a row — supersede it.

| # | Decision | Source |
|---|---|---|
| K-01 | **Stack:** … | Owner, <date> |
| K-02 | **Packaging:** modular monolith with service-grade boundaries (folder, DB schema, contract, API/MCP per module) | Owner |
| K-03 | **Where modules live / who consumes them:** … | Owner |
| K-04 | **Parallelism:** … (e.g. all modules in parallel after a short blocking contract wave) | Owner |
| K-05 | **Porting rule:** port proven logic + its tests, rewritten to the contract; never copy blindly | Proposed |

## 1. Vision
### 1.1 Primary user story
### 1.2 Other stories the same catalog must serve
### 1.3 Non-goals

## 2. Responsibilities
| Area | Owner (team) | Notes |
|---|---|---|
| Platform shell, auth, billing, marketplace | … | |
| Modules | … | |
| Kernel reference implementations adopted by the platform | … | |

## 3. Source analysis
Summarise each scan report (`scans/<ALIAS>.md`), with pinned SHAs.
### 3.1 Strengths taken from each source (with paths)
### 3.2 Debt that must NOT be carried over

## 4. Overlaps and primary-source decisions
| Capability | Sources that have it | Primary source | Why |
|---|---|---|---|

## 5. Module catalog (summary — full index in CATALOG.md)
Layers: foundation · system · business · add-on.

## 6. Architecture (short — law is in MODULE-CONTRACT.md)

## 7. AI integration
### 7.1 Main agent and module tools
### 7.2 Module activation by the agent / marketplace
### 7.3 Customer-facing agents (audience, subject binding)

## 8. Marketplace / bundles

## 9. Data, tenancy and migration
### 9.1 Tenancy model · ### 9.2 Master-data ownership · ### 9.3 Legacy tenant migration (separate phase)

## 10. Execution plan
| Wave | Contents | Parallel | Exit gate |
|---|---|---|---|
| W0 — Contracts (blocking) | SDK + dev host + tooling + foundation contracts & stubs | 1–2 | G0 |
| W1 — Fan-out | every module, exclusive folder ownership, stubs for unfinished deps | see ORCHESTRATION-PLAN | G1 = DoD per module |
| W2 — Integration | stubs → real modules, journeys per story, isolation, tool evals | 1 per bundle + security | G2 |
| W3 — Release | metadata, docs, integration guide, versioning/publish | few | G3 = clean install |

### 10.1 Collision rules
### 10.2 Definition of Done per module
(manifest valid · contract with zod DTOs/events · idempotent migrations + RLS + isolation test through the real
runtime connection · API + OpenAPI + guards · tools + evals · UI per DESIGN · unit/integration/property/contract
tests · boundary lint · README with provenance)

## 11. Non-functional requirements
## 12. Risks
## 13. Open questions (Q-xx → become K-xx when answered)
