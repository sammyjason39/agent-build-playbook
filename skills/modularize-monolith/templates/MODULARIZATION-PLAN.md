# Modularization plan — <repo>

Status: draft · Base commit: `<sha>` · Owner decisions: K-xx table below.

## 0. Decisions
| # | Decision | Source |
|---|---|---|
| K-01 | Target shape: modular monolith in place (no new repo) | Owner |
| K-02 | Module mechanism: <folders + boundary tool / packages / Gradle modules / packwerk packs> | Owner |
| K-03 | DB strategy: <schema per module / prefix ownership>; cross-module FKs → IDs | Owner |
| K-04 | Release rule: app shippable after every merge; no feature freeze / <freeze window> | Owner |
| K-05 | Parallelism: <n agents>, single owner for shared hot files per wave | Owner |

## 1. Current state (evidence)
Summary of the scan (`scans/<repo>.md`) and coupling report: areas, cycles, god tables, hotspots.

## 2. Target module map
| Module | Responsibility | Owns tables | Public contract (ops) | Emits events | Consumes | Depends on |
|---|---|---|---|---|---|---|

Allowed dependency direction (layers): `foundation → business → edge`. No cycles.

## 3. Boundary rules (enforced)
- Checker: `<tool + config path>`; ratchet baseline `.boundaries-baseline` (only shrinks).
- Rules: only `modules/<key>/contract` importable from outside; only `<key>` touches `<key>` tables; no new cross-module FKs.

## 4. Safety net
- Characterization tests for: <hotspot list> (owner of each).
- Flaky tests quarantined: <list>.

## 5. Waves
| Wave | Tasks (one ownership slice each) | Parallel | Gate |
|---|---|---|---|
| M0 | CI green, characterization tests, skeleton, checker + baseline | 1–2 | baseline committed, CI green |
| M1 | leaf modules: <a>, <b> (facade → redirect → move) | n | per-module DoD |
| M2 | break cycles <x↔y> (events / inversion) | … | no cycles |
| M3 | core modules <…>; DB ownership steps | … | per-module DoD |
| M4 | harden walls, remove re-exports, CODEOWNERS | … | baseline = 0 |

## 6. Definition of Done per module
- [ ] contract derived from real call sites; all external callers use it
- [ ] internals moved; no external imports of internals (checker: 0 for this module)
- [ ] owns its tables; no foreign writes; foreign reads via contract/read model
- [ ] cycles involving it broken
- [ ] characterization tests unchanged and green; module tests green
- [ ] baseline shrunk in the same PR; docs/CODEOWNERS updated

## 7. Risks · 8. Open questions
