# Task <ID> — <module>: <facade | redirect area X | move internals | cut DB access | break cycle>

<!-- One ownership slice per task. "Extract billing" is too big; split it into facade → redirect per area → move → DB. -->

## Context
Module `<key>` per `docs/MODULARIZATION-PLAN.md` §2. Contract: <ops>. Current baseline violations for this module:
<count> (`.boundaries-baseline`, lines matching `<key>`).

## Do
1. <Concrete step, e.g. "create `modules/billing/contract/index.ts` exporting `createInvoiceForOrder(orderId)` and `getInvoice(id)` that delegate to `src/services/invoice.service.ts` — no behaviour change">
2. <e.g. "redirect these call sites to the contract: `src/routes/orders.ts:88`, `src/jobs/close-day.ts:41` …">
3. Shrink the ratchet: `scripts/ratchet.sh --update .boundaries-baseline -- <checker>`, and commit the smaller baseline.

## Must stay true
- Characterization tests `<paths>` pass **without edits**. If one needs to change, stop and report why.
- No new boundary violations (`scripts/ratchet.sh .boundaries-baseline -- <checker>` exits 0).
- Behaviour unchanged: same HTTP responses, same DB writes, same events.

## Ownership
Only: <module folder>, the listed caller files, `.boundaries-baseline`. Shared hot files (<router/DI/settings>) are
NOT yours; describe needed edits in your report.

## Verify
<typecheck>, <tests of touched areas>, <characterization suite>, ratchet. Report the exact results.
