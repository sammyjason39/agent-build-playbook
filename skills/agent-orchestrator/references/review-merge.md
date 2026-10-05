# Review → merge → CI (never skip a step)

An agent's report is a claim, not evidence. Each step below has caught real defects that were reported as done:
- logic copied from old code that was wrong in the first place;
- a fix that opened a new hole (for example, a requester able to approve their own request);
- a blanket conflict resolution that silently dropped someone else's fix;
- generated files that drifted because the wrong command was run.

## 1. Read the final report
`tail -c 4000 $ORCH_ROOT/logs/<name>.log` — the table, the commands run, and "not done / proposals".

## 2. Check the scope
`scope-check.sh <name> '<allowed ERE>'`. Anything out of scope is either reverted, or accepted explicitly with a
reason that goes into the merge message.

## 3. Read the diff, not just the summary
`git -C $WT_ROOT/<name> diff $(cat $ORCH_ROOT/bases/<name>)..HEAD -- <the risky files>`. Look for:
- security semantics: auth, tenancy, signatures, approvals, who-can-decide;
- silent behaviour changes in shared code (SDK interfaces, defaults);
- tests that assert the implementation instead of the requirement, and timing-sensitive assertions
  (`now()` called twice, values one second from a limit);
- new dependencies, and cycles between packages.

## 4. Re-run the gates yourself, on the merged result
```sh
git -C $REPO checkout main && git -C $REPO pull --ff-only
git -C $REPO merge --no-ff <branch> -m "merge: <ID> <summary>"
<install --frozen-lockfile>; <typecheck>; <lint --max-warnings 0>; <boundary lint>
<tests of every touched package>   # sequential: pnpm -r --workspace-concurrency=1 --no-bail
<regenerate generated artifacts> && git diff --exit-code -- <generated dirs>
```

## 5. Push and watch CI to the end
```sh
git push origin main
ci-watch.sh --latest main     # as a Monitor; report every failure with its log
```
If CI fails: read `gh run view <id> --log-failed`, fix (or send a follow-up task), push, watch again.
Never report "done" on a red or unfinished CI.

## 6. Clean up
`git worktree remove <wt>`; `git branch -D <branch>` once merged; delete `$ORCH_ROOT/data/<name>`.
