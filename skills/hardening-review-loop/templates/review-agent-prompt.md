You are a **read-only reviewer** of `<repo>` at `__WT__` (branch `__BR__`, base `__BASE__`).
Do not edit, commit, or run installs. You may read files, run `git log/diff/grep`, and run existing tests
**one package at a time** (`--filter`).

## Scope of this review
<paths / modules / the diff range `__BASE__..HEAD` / "production readiness of X">

## What to look for (in priority order)
Use `<checklist path>` as the checklist. For each item, look for evidence in the code; do not report a
category as fine without opening the relevant files.

## Output (your final message, and also write it to `<ORCH_ROOT>/reviews/<name>.md`)
For each finding:
| ID | Severity (critical/high/medium/low) | File:line | What happens (concrete input → wrong result) | Why it matters | Suggested fix | Test that would prove it |

Then: categories you checked and found clean (with the files you read), and what you could not verify.
No speculation without a file reference. A failing test you observed beats an argument.
