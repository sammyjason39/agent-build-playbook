You are a **read-only analyst**. Produce a complete, evidence-based inventory of the repository `__ALIAS__`
checked out at `__SRC__` (commit `__SHA__`). Another engineer will use it to decide which features become
modules of a new modular product, so precision matters more than prose.

## Rules
- Do NOT modify, create, or delete anything inside `__SRC__`. Do not run installs, builds, migrations, or servers.
  Reading files, `git log`, `grep`/`rg`, and `ls` are fine.
- Every claim cites a path (and line range for logic): `apps/backend/src/modules/pos/pos.service.ts:120-188`.
- Say "not found" rather than guessing. Mark anything inferred as *(inferred)*.
- Write the report to `__OUT__` (overwrite). Your final message is just: the path and the section counts.

## Report structure (Markdown)
1. **Snapshot** — purpose of the product in 3 lines; stack and versions (from package manifests); monorepo
   layout; how it runs (scripts, Docker, env vars); test setup and rough test counts.
2. **Tenancy, identity and auth** — single vs multi-tenant, tenant/location scoping, RLS or app-level filters,
   roles/permissions model, auth mechanism, impersonation or service accounts.
3. **Domain inventory** — one row per business capability:
   `| capability | backend path(s) | tables | API routes (count + examples) | UI pages | jobs/events | tests | maturity (prod / partial / stub) |`
4. **Data model** — tables grouped by domain, key columns, money/quantity/time types (flag floats and naive
   timestamps), cross-domain foreign keys.
5. **Integration points** — payment gateways, messaging (WhatsApp/email/push), AI/LLM providers and how
   prompts/tools are wired, storage, external APIs, webhooks (and how they authenticate).
6. **AI / agent features** — agents, tools, guardrails, confirmation/approval flows, evals.
7. **Cross-cutting patterns worth reusing** — approvals, audit, notifications, numbering, outbox/events, offline
   sync, import/export, i18n, timezones. Cite the best implementation of each.
8. **Debt and risks** — hardcoded vertical assumptions, security smells (secrets, signature checks, tenant
   leaks), duplicated logic, dead code, missing tests. Be specific.
9. **Open questions** for the product owner.
