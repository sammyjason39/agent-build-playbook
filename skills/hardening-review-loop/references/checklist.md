# Production-readiness checklist

Each item below was a real defect in the reference build. The defects were reported as done by agents and were
caught only by review, tests, or CI. Check every item against the code.

## Tenancy and data access
- [ ] The runtime DB login is **not** an owner, superuser or BYPASSRLS role, and boot refuses one in
      production. Check for a silent fallback to the owner URL.
- [ ] Every table has RLS ENABLE + FORCE, including outbox and inbox tables.
- [ ] The policy tolerates an empty tenant setting (`NULLIF(current_setting(..., true), '')::uuid`) and does not
      raise on pooled connections.
- [ ] Isolation tests go through the **real runtime connection**, never a hand-issued `SET ROLE`.
- [ ] The request context is built **per request**. A singleton context means every request shares a tenant.
- [ ] Cross-module calls execute **as the caller**, not as a fixed host or boot identity.
- [ ] Public routes resolve the tenant from an unguessable token (hash-only storage) plus a second factor such
      as a provider signature or contact proof. Never from the body.

## Identity, auth, approvals
- [ ] JWT/session secrets have a minimum length and boot refuses empty ones; `exp`/`iat` are required; the TTL
      is bounded with a hard ceiling; `nbf` is checked.
- [ ] External tokens cannot claim system/automation/agent actors.
- [ ] Approvals:
  - "auto" mode only *creates* the request;
  - the requester can never decide;
  - required role, thresholds and quorum are enforced;
  - deep links never decide by themselves;
  - the approval is created at submission, not lazily at decision time.
- [ ] The guard is fail-closed: a route without a decorator is denied.
- [ ] Audit is written on success only, and on the **resolved** tenant for public routes.

## Integrations
- [ ] Webhook signatures are verified on the **raw body**, with the exact provider algorithm checked against the
      provider docs (e.g. Midtrans uses plain SHA-512, not HMAC). Amounts are matched to the intent. Mock
      providers are off unless explicitly enabled.
- [ ] Secrets are never logged and never sent to hosts other than the compiled-in provider base URL.
- [ ] Embedding and vector dimensions are fixed and enforced; changing them needs a migration and a re-embed.

## Time, money, ids
- [ ] Day boundaries use the **tenant time zone**, not server UTC. Check SQL `::date`, `CURRENT_DATE`,
      `date_trunc` and JS `new Date()` business logic. Tests must not depend on the wall-clock hour (they failed
      between 00:00 and 07:00 WIB).
- [ ] Money and quantity are decimal types and decimal math, never floats.
- [ ] Id functions exist on the **minimum supported DB version**. For example `uuidv7()` is PG 18 only, so
      PG 16 needs a polyfill, created by the migration runner before module migrations.

## Correctness under concurrency
- [ ] Commands are idempotent (idempotency keys), and consumers dedupe (`inbox`).
- [ ] Reserve → confirm/release instead of distributed transactions. A recovery sweeper exists for stuck
      reservations.
- [ ] Billing/stock never double-counts under parallel runs (tested with parallel calls).

## API hygiene
- [ ] Validation errors map to 400, not 500.
- [ ] Error responses do not reveal which factor failed when that would help an attacker.

## Build, CI, release
- [ ] Generated docs (OpenAPI, SDK, MCP) are deterministic: no random defaults or timestamps. CI fails on
      drift. Use the right command: `pnpm run docs`, not `pnpm docs`, which is a built-in.
- [ ] Tests run on the same DB major version and extensions as production (service container in CI).
- [ ] Every package declares the dependencies it imports, with no undeclared workspace dependencies and no
      cycles.
- [ ] Tarballs contain no tests or fixtures, and **every** published package is checked, including nested ones.
- [ ] Timing-sensitive tests: compute `now()` once, and stay well clear of limits (no `limit + 1 s`).
- [ ] Lint runs with zero warnings, typecheck passes, and boundary lint passes.

## Docs
- [ ] There is an integration or adoption guide that matches the code: env vars, roles, migration order,
      host-bound capabilities, a production checklist.
- [ ] Every owner decision is recorded (`K-xx`), and every change to locked docs has an RFC.
