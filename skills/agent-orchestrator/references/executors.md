# Coordinator and worker models

The playbook splits the work in two:

| Role | Who | Model | Reasoning |
|---|---|---|---|
| **Coordinator** (main AI) | the agent you talk to: Claude Code (or Hermes, Antigravity, opencode in interactive mode) | the most capable high-reasoning model available, e.g. **Claude Opus 5.5** or **GPT 6 Astra** | **high** |
| **Worker** (executor) | a CLI agent started by `launch.sh` in its own worktree: **opencode**, **pi**, **Antigravity CLI (`agy`)**, or any CLI (`custom`) | a fast, cheaper coding model is fine | **low–medium** (raise for a hard task) |

Why it works: the coordinator does the expensive thinking once. It reads the code, decides the boundaries, and
writes a prompt with a clear goal, file ownership, required behaviour, tests and out-of-scope. A worker that
receives such a prompt does not need deep reasoning to execute it. It needs to follow it and verify. Raise the
worker's effort only for tasks that are genuinely algorithmic or ambiguous, or after a failed attempt.

## Setting the coordinator to high reasoning
- **Claude Code:** in `/model`, pick the model (for example Opus 5.5) and set reasoning effort to **high**.
  You can also set `model` in `~/.claude/settings.json`.
- **Other coordinators:** choose their strongest model and their highest "thinking", "reasoning" or "effort"
  setting in that tool's model or config menu.

## Worker executors

Set the default in `orch.env` (`EXECUTOR`, `EXEC_MODEL`, `EXEC_EFFORT`), or override it per task:
`launch.sh <name> '<ownership>' <executor>`.

| `EXECUTOR` | Install | What `launch.sh` runs (in the worktree) | Effort flag | Isolation |
|---|---|---|---|---|
| `opencode` | `curl -fsSL https://opencode.ai/install \| bash`, then `opencode auth login` | `opencode run --auto --dir <wt> [--model p/m] "<prompt>"` | `--variant <EXEC_EFFORT>` | own `XDG_DATA_HOME` (required for parallel runs) |
| `pi` | `npm i -g @earendil-works/pi-coding-agent`, then log in or set API keys | `pi -p --session-dir <data>/pi [--model m] "<prompt>"` | `--thinking off\|minimal\|low\|medium\|high\|xhigh\|max` | own `--session-dir` |
| `agy` | Antigravity CLI, logged in | `agy -p "<prompt>" --dangerously-skip-permissions [--model m]` | `--effort low\|medium\|high\|max` | runs in the worktree directory |
| `custom` | anything with a non-interactive mode | `bash -c "$EXEC_CMD"` with `$PROMPT_FILE`, `$WT`, `$AGENT_DATA` exported | your flags | your choice |

Notes:
- Every executor runs **with auto-approved tools** (`--auto`, pi's default, `--dangerously-skip-permissions`).
  That is acceptable only because each worker works in a **disposable git worktree** on its own branch and you
  review before merging. Never point a worker at your main checkout.
- `resume.sh` continues the same session with the same executor: opencode `--continue`, pi `-c`, agy `-c`, or
  `EXEC_RESUME_CMD` for custom.
- Mixing is fine. For example, use pi for quick fixes, opencode for longer tasks, and agy when a task benefits
  from its built-in browser tools.
- Parallel runs: opencode is proven safe with separate data dirs. For other executors, start with
  `MAX_PARALLEL=1` and raise it once you have watched two of them run side by side.

## Checklist for a prompt a low-effort worker can execute
- [ ] One goal, stated in the first line.
- [ ] An exact ownership list (paths or globs). Everything else is read-only.
- [ ] Findings or requirements with file:line where they exist.
- [ ] The required behaviour, including names, defaults and edge cases.
- [ ] The tests to add, and the exact verification commands.
- [ ] An out-of-scope list.
- [ ] The final report format: what changed, the tests that prove it, the commands run, and what was not done.
