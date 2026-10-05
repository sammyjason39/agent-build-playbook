# Production-readiness checklist

Agents routinely report these as done when they are not. Check every item against the code, and skip the items
that do not apply to the stack.

## Data access and multi-tenancy
- [ ] The application connects with a **least-privilege** database role, never the owner or admin role, and
      startup refuses a privileged connection in production. Look for silent fallbacks to an admin URL.
- [ ] Tenant or ownership filtering is enforced in one place: row-level security, a repository layer or a query
      scope. A handler that forgets it must fail closed.
- [ ] Isolation tests go through the **real runtime path**. Tenant A cannot read or write tenant B through the
      API, background jobs, events or AI tools.
- [ ] The request context, meaning the user and tenant, is built **per request**, never cached in a singleton.
- [ ] Internal calls between modules run **as the caller**, not as a fixed system identity.

## Identity, authorization, approvals
- [ ] Secrets are required, strong and never defaulted to empty. Tokens expire, and lifetimes have an upper bound.
- [ ] Clients cannot elevate themselves, for example by claiming an admin or system role in a token or request body.
- [ ] Authorization is fail-closed: a route without an explicit rule is denied.
- [ ] Approval flows: a requester cannot approve their own request, required roles and thresholds are enforced,
      and links or automation never approve on their own.
- [ ] Public (unauthenticated) endpoints authenticate the caller another way, such as a signed payload,
      unguessable token or second factor, and never trust identifiers from the body.
- [ ] An audit trail records who did what. It is written on success and attributed to the right tenant.

## External integrations
- [ ] Webhooks verify signatures exactly as the provider documents. Check the algorithm against the docs; do not
      copy it from old code. Verification uses the raw body, and amounts or states are matched to your records.
- [ ] Test or sandbox shortcuts (mock providers, debug flags) are off by default in production.
- [ ] Credentials are never logged, never returned by the API, and only sent to their intended host.

## Time, money, identifiers
- [ ] Business dates use the **user's or tenant's time zone**, not the server's. Tests do not depend on the
      wall-clock hour or date.
- [ ] Money and quantities use decimal types and decimal math, never binary floats.
- [ ] Every database function, extension or feature used exists on the **oldest supported version** of the
      database or runtime, or is polyfilled by migrations.

## Concurrency and consistency
- [ ] Commands are idempotent (idempotency keys), and event consumers deduplicate.
- [ ] There are no distributed transactions. Use reserve → confirm/release or an outbox, plus a recovery job for
      stuck states.
- [ ] Double-processing (billing, stock, payouts) is tested with concurrent calls.

## API and error handling
- [ ] Validation errors return 4xx, not 500. Unexpected errors are logged with context and returned without
      internals.
- [ ] Error messages do not reveal which security check failed.

## Build, tests, CI, release
- [ ] CI runs lint (zero warnings), typecheck or compile, the boundary or architecture checks, and the tests, on
      the same database and runtime versions as production.
- [ ] Generated artifacts (API specs, clients, docs) are deterministic, and CI fails when they are stale.
- [ ] Every package or module declares the dependencies it uses, with no dependency cycles.
- [ ] Release artifacts contain only what consumers need: no tests, fixtures or secrets.
- [ ] There are no flaky tests. Compute "now" once, stay clear of time limits, and do not depend on test order.

## Documentation
- [ ] A setup or integration guide matches the code: env vars, roles, migrations, required services, and a
      production checklist.
- [ ] Decisions with trade-offs are recorded (a decisions table or ADRs), and changes to agreed architecture go
      through an RFC.
