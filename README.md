# agent-build-playbook

**English** · [Bahasa Indonesia](README.id.md)

Skills and scripts that let one **high-reasoning main AI** (the coordinator) plan the work and dispatch it to
**CLI coding agents** (workers: opencode, pi, Antigravity, or any CLI). Each worker runs in its own git worktree,
and the coordinator reviews and merges everything until CI is green.

Most people only need the **agent orchestration** part. It works on any repo, in any language, with no planning
documents required. The other skills add planning for bigger efforts:
- **Several repos → one new modular product** (`multi-repo-prd`).
- **One overly complex repo → modular, in place** (`modularize-monolith`). The app keeps shipping at every step.
- **Review and fix until production ready** (`hardening-review-loop`), and **release packages**
  (`monorepo-release`).

**Contents:** [Quick start: orchestration only](#quick-start-agent-orchestration-only) ·
[Models](#models-strong-coordinator-light-workers) · [Skills](#skills) · [Which skill?](#which-skill) ·
[Features](#features) · [Use cases](#use-cases) · [Installation](#installation) ·
[Example prompts](#example-prompts) · [Principles](#principles)

```
                        ┌────────────────────────────────────────────┐
  you ── goal ─────────▶│  COORDINATOR (main AI, high reasoning)     │
                        │  Claude Opus 5.5 / GPT 6 Astra, effort high │
                        │  reads code · splits work · writes prompts  │
                        │  reviews diffs · merges · watches CI        │
                        └──────┬───────────────┬───────────────┬─────┘
              clear goal + ownership + tests + out-of-scope    │
                               ▼               ▼               ▼
                        ┌──────────┐    ┌──────────┐    ┌──────────┐
                        │ opencode │    │    pi    │    │   agy    │   WORKERS
                        │ worktree │    │ worktree │    │ worktree │   (low–medium reasoning)
                        │ branch A │    │ branch B │    │ branch C │
                        └──────────┘    └──────────┘    └──────────┘
```

## Quick start: agent orchestration only

Requirements: `git`, `jq`, `gh` (logged in, for CI watching), and at least one worker CLI (opencode, pi, or
Antigravity `agy`) that is logged in.

```sh
git clone https://github.com/sammyjason39/agent-build-playbook ~/agent-build-playbook
~/agent-build-playbook/install.sh claude        # or: all | opencode | hermes | antigravity | antigravity-cli
```

Then, in your project, tell your main AI:

```
Use agent-orchestrator. Goal: <what you want>. Split it into tasks with clear ownership, dispatch them to
opencode (low effort) one at a time, review every diff before merging, and keep CI green.
```

What the coordinator does with the skill's scripts:

```sh
export ORCH_ROOT=~/code/myrepo-wt/_orchestration                         # outside /tmp
cp ~/agent-build-playbook/skills/agent-orchestrator/scripts/orch.env.example $ORCH_ROOT/orch.env  # REPO, EXECUTOR…
S=~/agent-build-playbook/skills/agent-orchestrator/scripts
$S/new-worktree.sh fix-login-timeout                                      # worktree + branch
#   … writes $ORCH_ROOT/prompts/fix-login-timeout.md (goal, ownership, tests, out-of-scope)
$S/launch.sh fix-login-timeout '`src/auth/**`, `tests/auth/**`' opencode   # worker runs (background)
$S/watch.sh fix-login-timeout                                             # commits / STALL / FINISHED
$S/scope-check.sh fix-login-timeout '^(src/auth/|tests/auth/)'            # nothing outside ownership
#   … reviews diff, runs the tests itself, merges, then:
$S/ci-watch.sh --latest main                                              # until CI is green
```

You don't run these by hand unless you want to. The coordinator follows the procedure in
[`skills/agent-orchestrator/SKILL.md`](skills/agent-orchestrator/SKILL.md).

## Models: strong coordinator, light workers

| Role | Recommended | Reasoning | Why |
|---|---|---|---|
| **Coordinator** (the AI you talk to) | **Claude Opus 5.5** or **GPT 6 Astra**, or the most intelligent model you have | **High** | It reads the code, decides boundaries and trade-offs, writes the prompts, and judges the diffs. Quality here decides everything. |
| **Workers** (dispatched CLI agents) | Any capable coding model via **opencode**, **pi**, or **Antigravity `agy`** (or a custom CLI) | **Low–medium** | Each prompt arrives with a clear goal, file ownership, required behaviour, tests and out-of-scope list, so execution needs little deliberation. Raise it only for an algorithmic task or after a failed attempt. |

Setting it up:
- **Coordinator in Claude Code:** `/model` → choose Opus 5.5 and set effort to **high**. In other tools, pick the
  strongest model and the highest thinking or effort setting.
- **Workers:** set them in `orch.env`:
  ```sh
  EXECUTOR=opencode      # opencode | pi | agy | custom
  EXEC_MODEL=""          # empty = the tool's default; opencode uses provider/model
  EXEC_EFFORT=low        # opencode --variant · pi --thinking · agy --effort
  ```
  You can override the executor per task with `launch.sh <task> '<ownership>' pi`. Details are in
  [`executors.md`](skills/agent-orchestrator/references/executors.md).

## Skills

| Skill | Use it when | Contents |
|---|---|---|
| [`agent-orchestrator`](skills/agent-orchestrator/SKILL.md) ⭐ | You want work delegated to other agents: "orchestrate", "dispatch", "run agents in parallel / one by one" | Worktree, launch (opencode / pi / agy / custom), watch, resume, scope-check and ci-watch scripts; worker prompt templates; parallelism math; review-and-merge guide |
| [`modularize-monolith`](skills/modularize-monolith/SKILL.md) | One repo is too complex and you want modules, or to prepare for services later | Git coupling report, architecture scan, boundary-violation ratchet, strangler playbook, zero-downtime DB decoupling, plan and task templates |
| [`multi-repo-prd`](skills/multi-repo-prd/SKILL.md) | You want several repos merged into one modular product | Per-repo scan, owner-decision log, PRD / architecture / design / catalog templates, one-shot prompt pack per module |
| [`hardening-review-loop`](skills/hardening-review-loop/SKILL.md) | You want agent output checked and fixed until production ready | Production checklist, read-only reviewer prompt, the findings → fix → verify loop |
| [`monorepo-release`](skills/monorepo-release/SKILL.md) | You need to publish packages from a monorepo and let other teams install them | Package-content gate, GitHub Packages publishing with scope aliasing, release workflow, clean-install test |

### Which skill?

| Your situation | Start with | Then |
|---|---|---|
| You have a task or a plan and want agents to do it | `agent-orchestrator` | `hardening-review-loop` |
| One large, tangled codebase | `modularize-monolith` | `agent-orchestrator` → `hardening-review-loop` |
| Several repos to combine into one product | `multi-repo-prd` | `agent-orchestrator` → `hardening-review-loop` → `monorepo-release` |
| Agents already did the work and you doubt the quality | `hardening-review-loop` | `agent-orchestrator` for the fixes |
| A monorepo that other teams need to consume | `monorepo-release` | — |

## Features

### `agent-orchestrator`: the coordinator plans, workers execute
- **Any repo, any stack, standalone.** No PRD or special layout is needed. `INSTALL_CMD` can be anything
  (`npm ci`, `pip install …`, `go mod download`, …).
- **Multiple executors:** opencode, pi, Antigravity `agy`, or a custom CLI. Model and effort are configurable
  globally and per task.
- **Isolation:** one git worktree and branch per worker, plus a private data or session directory (parallel
  opencode runs otherwise collide on a shared database).
- **Parallelism planning:**
  - split the work into disjoint ownership slices;
  - layer the tasks by dependency;
  - `MAX_PARALLEL = min(ready tasks, RAM, CPU, API budget)`;
  - on a small or shared machine, run workers one at a time.
- **Scripts:**
  - `new-worktree.sh`: creates the worktree and branch, installs dependencies, records the base commit;
  - `launch.sh`: runs the worker with a unique completion marker;
  - `watch.sh`: prints commits, STALL and FINISHED events;
  - `resume.sh`: continues the same session;
  - `scope-check.sh`: rejects edits outside the worker's ownership;
  - `ci-watch.sh`: prints each CI job result until the run completes.
- **Prompt templates** that a low-effort worker can execute: a common header (worktree rules, ownership,
  verification, report format) and a task prompt (goal, requirements with file:line, tests, out-of-scope).
- **Review before merge:** report → scope → risky diff → gates re-run by the coordinator → merge → CI green →
  cleanup.
- **Failure playbook:** stalled worker, early exit, ownership requests, decisions that need the owner, merge
  conflicts.

### `modularize-monolith`: modular in place, always shippable
- **`coupling-report.sh`** works on git history, in any language, without a build. It reports hotspots (churn ×
  size), churn per area, and areas that change together (hidden coupling).
- **`scan-monolith.sh`** runs a read-only worker that maps areas, the dependency graph and cycles, which code
  touches which tables, shared hot files, candidate modules and an extraction order.
- **Per-stack analysis tools:** dependency-cruiser/madge, import-linter, ArchUnit/Spring Modulith, Go, .NET,
  deptrac, packwerk. They feed a **boundary decision table**.
- **`ratchet.sh`** works with any checker. Today's violations become the baseline, new ones fail CI, and the
  baseline can only shrink.
- **Strangler playbook:**
  - safety net: characterization tests, skeleton, ratchet;
  - per-module extraction, leaf-first: contract → facade → redirect callers → move internals → cut DB access →
    break cycles;
  - harden the walls.
- **Zero-downtime DB decoupling:** table ownership, schema per module, read models, cross-module foreign keys →
  IDs plus reconciliation, outbox, expand → migrate → contract.

### `multi-repo-prd`: several repos → one modular product plan
- A read-only scan of each source repo, pinned to a commit. Every claim cites a path.
- Owner decisions are asked at most four at a time, each with a recommendation, and logged as `K-xx` so they are
  never asked again.
- Templates: PRD, locked architecture contract, locked design system, catalog with a coverage map (every source
  feature gets a home or a reasoned drop), orchestration plan, RFC process.
- A one-shot prompt pack: a common brief, briefs per wave, and one spec per module with testable acceptance
  criteria, so many agents can build in parallel without inventing decisions.

### `hardening-review-loop`: done means verified, not "the agent said so"
- A production checklist: data access and tenancy, auth and approvals, integrations and webhooks, time / money /
  identifiers, concurrency, error handling, CI and release hygiene, docs.
- A read-only reviewer prompt. Findings carry severity, file:line, a concrete failure scenario, and the test that
  would prove the fix.
- The loop: findings → ownership-scoped fix tasks → workers → every claim verified → merge → CI. Trade-offs go
  to the owner and are recorded.

### `monorepo-release`: ship packages others can install
- A package-content gate: only what consumers need, checked for every publishable package.
- GitHub Packages publishing that keeps your source scope through npm aliases. It runs from a GitHub Actions
  workflow with `GITHUB_TOKEN`, tags the release, and runs a clean-install test.
- Access instructions for laptops, the CI of other repos, and servers.

## Use cases

1. **Delegate a feature or a refactor to cheap agents, safely.** A strong model plans, cheaper workers execute
   in isolated worktrees, and nothing merges without review and a green CI. *(agent-orchestrator)*
2. **Use a small or shared server well.** Workers run one at a time with watchers and resume; a session that
   stalls doesn't take the machine down with it. *(agent-orchestrator)*
3. **Mix tools by strength.** For example, pi for quick fixes, opencode for longer tasks, Antigravity where its
   tooling helps, all under one coordinator. *(agent-orchestrator)*
4. **Untangle a legacy monolith without a rewrite.** Evidence-based module boundaries, a CI ratchet, leaf-first
   extraction, and a database split with no downtime. *(modularize-monolith → agent-orchestrator)*
5. **Prepare for microservices later.** Contracts and events inside the monolith first, so extracting a module
   becomes a deployment change. *(modularize-monolith)*
6. **Consolidate several products into one platform.** One PRD, locked architecture and design, a prompt pack, and
   parallel module builds. *(multi-repo-prd → agent-orchestrator)*
7. **Audit AI-generated code before production.** Concrete findings, fix tasks, verified claims.
   *(hardening-review-loop)*
8. **Find hidden coupling before estimating a change.** One command shows the riskiest files and the areas that
   always change together. *(coupling-report.sh)*
9. **Publish internal packages for other teams.** *(monorepo-release)*

## Installation

All skills use the standard **Agent Skills** format: a folder with a `SKILL.md` (frontmatter `name` and
`description`) plus `scripts/`, `templates/` and `references/`. Claude Code, opencode, Hermes and Antigravity
all read this format; only the folder they look in differs. Scripts are bash, so on Windows use WSL.

### Everything at once

```sh
git clone https://github.com/sammyjason39/agent-build-playbook ~/agent-build-playbook
cd ~/agent-build-playbook && ./install.sh all    # or pick: claude opencode agents hermes antigravity antigravity-cli
```

`install.sh` creates **symlinks**, so a `git pull` updates every tool. It never overwrites a real directory with
the same name. Set `SKILLS_COPY=1` to copy instead, for tools or sandboxes that don't follow symlinks.

| Target | Global location | Used by |
|---|---|---|
| `claude` | `~/.claude/skills/<skill>` | Claude Code (opencode reads it too) |
| `opencode` | `~/.config/opencode/skills/<skill>` | opencode |
| `agents` | `~/.agents/skills/<skill>` | opencode and other tools that read `.agents/skills` |
| `antigravity` | `~/.gemini/config/skills/<skill>` | Antigravity IDE |
| `antigravity-cli` | `~/.gemini/antigravity-cli/skills/<skill>` | Antigravity CLI (`agy`) |
| `hermes` | `~/.hermes/skills/agent-build-playbook/` | Hermes Agent (one category with all skills) |

### Claude Code
- **As a plugin, without cloning:**
  ```
  /plugin marketplace add sammyjason39/agent-build-playbook
  /plugin install agent-build-playbook@agent-build-playbook
  ```
  To update, run `/plugin marketplace update agent-build-playbook`.
- **As personal skills:** `./install.sh claude`.
- **Per project:** copy or symlink `skills/*` into `<repo>/.claude/skills/` and commit them, so the whole team
  gets them.

### opencode
opencode reads `~/.config/opencode/skills/`, `~/.claude/skills/` and `~/.agents/skills/` globally, and
`.opencode/skills/`, `.claude/skills/` and `.agents/skills/` per project.
```sh
./install.sh opencode
opencode debug skill | grep -E '"name": "(agent-orchestrator|modularize-monolith|multi-repo-prd|hardening-review-loop|monorepo-release)"'
```

### Hermes Agent
- **From GitHub as a tap:**
  ```sh
  hermes skills tap add sammyjason39/agent-build-playbook
  hermes skills install sammyjason39/agent-build-playbook/agent-orchestrator
  hermes skills install sammyjason39/agent-build-playbook/modularize-monolith
  hermes skills install sammyjason39/agent-build-playbook/multi-repo-prd
  hermes skills install sammyjason39/agent-build-playbook/hardening-review-loop
  hermes skills install sammyjason39/agent-build-playbook/monorepo-release
  ```
  To preview first, run `hermes skills inspect sammyjason39/agent-build-playbook/<skill>`. To update, run
  `hermes skills check` and then `hermes skills update`.
- **From a clone (best if you edit the skills):** add the folder to `~/.hermes/config.yaml`:
  ```yaml
  skills:
    external_dirs:
      - ~/agent-build-playbook/skills
  ```
  Alternatively, run `./install.sh hermes`.
- **Per project:** put the skills in `<repo>/.agents/skills/` or `<repo>/.hermes/skills/`, then run
  `hermes skills trust` in that repo.

### Antigravity (IDE and CLI `agy`)
The IDE and the CLI use **different** global folders:
```sh
./install.sh antigravity        # IDE: ~/.gemini/config/skills/  (legacy ~/.gemini/antigravity/skills/ is also read)
./install.sh antigravity-cli    # CLI: ~/.gemini/antigravity-cli/skills/
```
Per project, both read `<workspace>/.agents/skills/<skill>/`. Reload the workspace or start a new `agy` session
after installing.

### Compatibility notes
- These skills come from runs where **Claude Code was the coordinator**. In Hermes or Antigravity the agent you talk
  to takes that role, and the scripts still dispatch workers through `launch.sh`.
- Claude Code features such as Monitor and background shells have plain equivalents elsewhere:
  - run `launch.sh` in the background (`nohup … &`);
  - follow it with `watch.sh`;
  - follow CI with `ci-watch.sh`.
- The scripts find their config through `ORCH_ROOT` (`export ORCH_ROOT=…`, see
  [`opencode.md`](skills/agent-orchestrator/references/opencode.md)).

## Example prompts

Write them in any language. Skills activate from context, or name the skill to be sure.

### Orchestration only (`agent-orchestrator`)
```
Use agent-orchestrator. Add rate limiting to our public API: decide the design, split it into tasks with
clear file ownership, dispatch them to opencode with low effort, review each diff, merge, and keep CI green.
```
```
This machine has 4 CPUs and 8 GB RAM. Work out how many workers can run in parallel safely, then run the
backlog in docs/todo.md. Report at each milestone.
```
```
Dispatch the quick fixes to pi (thinking low) and the migration task to opencode (variant medium).
One worktree per task; nothing merges until its tests pass on main.
```
```
The worker on task fix-search-pagination stopped halfway. Resume it, then check its scope and diff.
```

### Monolith (`modularize-monolith`)
```
This repo is too complex. Use modularize-monolith: measure coupling (imports, tables, co-change), propose a
module map, and ask me only the decisions that matter. Don't change code yet.
```
```
Run the coupling report for src/ at depth 3 over the last 12 months and explain which areas belong together
and which need a contract between them.
```
```
Set up wave M0: characterization tests for the top 10 hotspots, a module skeleton, a boundary checker with a
ratchet in CI. Then extract the notifications module first, in small tasks.
```

### Several repos (`multi-repo-prd`)
```
Study ~/code/shop-app, ~/code/inventory-app and ~/code/crm-app. I want one modular product in a new repo.
Use multi-repo-prd: scan each repo, brainstorm the key decisions with me, then write the PRD, architecture,
design system, catalog and a one-shot prompt per module.
```

### Review and fix (`hardening-review-loop`)
```
Review what the agents built in this repo. Is it on the right track? List findings with file:line and severity.
```
```
Fix everything that is still missing until it's production ready. Orchestrate workers for the fixes, commit,
push, and make sure CI is green.
```
```
Opening the export endpoint to anonymous users is fine if requests are signed. Record that decision and
implement it.
```

### Release (`monorepo-release`)
```
Publish all packages to our organisation's GitHub Packages and keep our source scope. Run it from GitHub
Actions, tag it, and test a clean install in an empty project.
```

### End to end
```
From planning to release: modularize this repo, build the tasks with workers one at a time, review and harden
until production ready, then publish. Report progress in English.
```

## Principles

- **Strong coordinator, light workers.** The thinking goes into the prompt, so execution can be cheap.
- **Write prompts after reading the code.** Each prompt has a goal, file:line, required behaviour, tests and
  out-of-scope.
- **Exclusive ownership per worker:** one worktree, one branch, one data dir.
- **A worker's report is a claim.** The coordinator checks scope, reads the diff, re-runs the gates and waits for
  green CI before calling anything done.
- **Owner decisions are recorded once** (a decisions table, ADRs or RFCs) and never asked twice.
- **Small machine → one worker at a time.** See the math in
  [`parallelism.md`](skills/agent-orchestrator/references/parallelism.md).
- **Report to the owner at milestones**, in their language, and state failures plainly.

Origin: these skills were distilled from a real build in which a coordinator directed CLI agents through about 40
modules, several hardening cycles, and a package release.
