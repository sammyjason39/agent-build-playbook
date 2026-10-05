# `<key>` — <Title>
**Layer:** <foundation|system|business|addon> · **Wave:** <W1-x> · **Depends on:** <keys> · **Enhances:** <keys> · **Consumed by:** <keys>

## One-shot prompt
> Read `00-COMMON-BRIEF.md`, `MODULE-CONTRACT.md`, `DESIGN.md`, then this spec. Build module `<key>` with the
> 11-step procedure. <One sentence on what makes this module special or risky.>

## Goal
<2–4 sentences: who uses it, the core loop, what other modules get from it.>

## Sources
- `<ALIAS> <path>` → <what to port> (Keep)
- `<ALIAS> <path>` → <what to generalise> (Generalise)
- <what not to bring> (Drop — reason)

## Scope
- **<Sub-domain>:** fields, rules, states, edge cases.
- …

## Data (`<schema>`)
<tables>

## Contract (exposes)
`method({input})` → output (one line each; idempotency/concurrency notes).

## Events
Emits `<key>.<entity>.<verb>` … · Consumes `<other>.<entity>.<verb>` (what it does).

## Agent tools
<audience>: `<key>.<tool>` (read | confirm | approval) …

## Datasets
`<key>.<dataset>` …

## UI
<pages with archetype>, widgets, agent cards, extension contributions.

## Setup steps
<what a tenant must configure before use>

## Acceptance
- <testable statements: invariants, concurrency, money/time correctness, permission and isolation cases>
