# Decoupling the database without downtime

Do the steps in order. Each step is one or more small, deployable migrations. Never combine "move data" and
"switch reads" in one release.

1. **Assign ownership.** Every table has exactly one owning module (the decision table in `analysis-tools.md`).
   God tables are split by lifecycle first.
2. **Namespace.** Move tables into a schema per module (`m_<key>`), or adopt a strict prefix. In Postgres,
   `ALTER TABLE … SET SCHEMA` plus a temporary `CREATE VIEW public.<old> AS SELECT * FROM m_<key>.<t>` keeps old
   queries working while callers migrate.
3. **Route reads through the owner.** Replace foreign reads with contract calls or a **read model**: a projection
   table in the consumer's schema, fed by the owner's events. Reports and analytics read from views or a
   warehouse, not from module tables.
4. **Route writes through the owner.** Only the owner writes its tables. Other modules call its contract
   (commands), or emit events the owner consumes.
5. **Replace cross-module foreign keys** with IDs plus application-level validation (through the contract), and add a
   reconciliation job that reports orphans. Keep FKs **inside** a module.
6. **Replace cross-module transactions** with reserve → confirm/release, or with the transactional outbox, plus
   idempotent consumers (an inbox table with `(consumer, event_id)`).
7. **Expand → migrate → contract** for every column or table change:
   - add the new structure;
   - dual-write or backfill;
   - switch reads;
   - stop the old writes;
   - drop the old structure in a later release.
8. **Multi-tenant apps:** while touching every table, add `tenant_id` and row-level security if they are missing.
   Test isolation through the real runtime connection, not as a superuser.

Checks per step:
- migrations are idempotent and reversible where possible;
- query plans exist for the new read paths;
- the characterization tests are still green;
- the boundary checker reports no table access from non-owners.
