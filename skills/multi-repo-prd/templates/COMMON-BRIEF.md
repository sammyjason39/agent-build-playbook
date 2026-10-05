# Common Brief — read this before any module task

You are an engineering agent building ONE module of **<Product>**. Product context: `docs/PRD.md`. Technical law:
`docs/MODULE-CONTRACT.md` (**locked**). Visual law: `docs/DESIGN.md` (**locked**). Your spec:
`docs/prompts/modules/<key>.md`. If they disagree: MODULE-CONTRACT and DESIGN win, then your spec, then the PRD.
Raise disagreements as an RFC (`docs/rfcs/`) — never resolve them silently.

## Source repositories (read-only, pinned)
| Alias | Repo | Ref |
|---|---|---|
| `<ALIAS>` | <url> | `<full sha>` (<branch>) |

Stack notes per source: what ports almost directly, what must be rewritten (ORM → raw SQL, single-tenant →
tenant_id, hardcoded vertical → generic, fixed timezone → tenant clock).

## Hard rules
1. **Ownership.** Write only inside `modules/<your-key>/` plus new files in `docs/rfcs/`.
2. **Boundaries.** Import only `<sdk>/*` and `<scope>/<dep>/contract`. SQL only against your schema.
3. **Tenancy.** Every table: `tenant_id`, RLS ENABLE + FORCE + policy; isolation test through the real runtime path.
4. **Numbers and time.** Decimal money/quantity; TIMESTAMPTZ; business dates from the context clock.
5. **AI safety.** Strict tool inputs; no identity selectors; writes need confirmation; destructive needs approval.
6. **No silent scope.** Build *Keep* and *Generalise*; never *Drop*; anything else → RFC.
7. **Dependencies not ready?** Use their `contract/stub.ts`. Never reach around it.
8. **Design is locked.** UI kit + semantic tokens only; one page archetype; default locale; light + dark.
9. **Truthful reporting.** Failing or partial ⇒ say so, with output.

## Procedure (commit after each step)
1. Read → write module README (*Scope*, *Provenance*, *Dropped*, *Open questions*).
2. Scaffold (`create-module <key>`), fill the manifest; boundary lint passes.
3. Contract: DTOs, service, events, extensions, stub.
4. Schema: migrations with RLS; apply twice (idempotency).
5. Domain + repositories: port source **tests first**, then logic; property tests for arithmetic.
6. API: guarded controllers, audit on mutations, OpenAPI, contract impl + provider suite.
7. Events + jobs: outbox in the same transaction; idempotent subscribers; per-tenant jobs.
8. Agent: tools, short domain prompt, ≥ 3 evals per tool.
9. Frontend: routes, settings, setup steps, widget, agent card, i18n; snapshots + axe.
10. Harden: isolation (REST, contract, tools, events), lint, typecheck, full module tests; README delivered vs scope.
11. Report: delivered vs spec (table), test numbers, RFCs, known gaps, intentional behaviour changes.

## Definition of Done
`docs/PRD.md` §10.2. A module without the isolation test or the tool evals is **not done**.
