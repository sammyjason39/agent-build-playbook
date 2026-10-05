# Design System — LOCKED <date> (K-xx)

Reference product to match: `<repo/app>` at `<sha>` (screenshots in `docs/design/`).

## 1. Principles (5–7 bullets: density, hierarchy, motion, language, accessibility)
## 2. Tokens — copied verbatim from the reference (`tokens.css`), never edited by modules
## 3. App shell (platform-owned): sidebar, header slots, command palette, chat panel
## 4. Page archetypes — every module page is exactly one of:
| Archetype | Use for | Required parts |
|---|---|---|
| List | collections | filter bar, table, bulk actions, empty state |
| Detail | one record | header, tabs, activity |
| Workspace | dense daily work (POS, schedule, timesheet) | … |
| Settings | module settings | sections, save bar |
| Dashboard | KPIs + widgets | … |
## 5. Components — the only UI building blocks (`<ui-kit>`): list them
## 6. Agent cards (inline in the main agent chat): confirmation, summary, list, error
## 7. Content and language (default locale, tone, number/date/money formats)
## 8. Enforcement: lint `design-tokens-only` (no hex/rgb/hsl, no palette classes, no font-family),
   light/dark snapshots at 375/768/1280, axe check.
