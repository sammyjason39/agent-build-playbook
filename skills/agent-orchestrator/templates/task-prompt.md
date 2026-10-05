# Task <ID> — <one-line goal>

<!--
Written by the orchestrator AFTER it has read the code. Each finding names the file and, where useful,
the line, states the observed behaviour and why it is wrong. The agent should not have to rediscover
the problem — only fix it. Keep it under ~60 lines; one task = one coherent ownership slice.
-->

## Context
<2–5 lines: what exists today, what was decided (owner decisions K-xx / RFC-nnn), what this task unblocks.>

## Findings
1. `<path/to/file.ts>` (~line N): <observed behaviour> → <consequence / risk>.
2. ...

## Fix
1. <Concrete required behaviour, including names of new symbols/env vars/defaults.>
2. <Edge cases that must be handled: empty, concurrent, cross-tenant, timezone, idempotency …>
3. Tests: <each case that must have a test; which real path (e.g. runtime DB role, HTTP layer)>.
4. Docs: <README / guide sections to update>.
5. Verify ONE package at a time: <pkg-a>, <pkg-b>; lint `--max-warnings 0`; boundary lint;
   regenerate <generated docs> only if routes/tools changed.

## Out of scope
- <Things the agent must not do even if tempting (refactors, renames, other modules).>
