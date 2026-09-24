# Rebase workflow

Use this reference only for an authorized local rebase in `mostbet-next`.

## Worktree safety

- Use the exact Jira key as the branch name and `<repo-parent>/<repo-name>-<JIRA_KEY>` for a temporary worktree. Keep it outside the repository tree.
- Reuse a matching worktree only when it is clean. Preserve dirty worktrees, report affected paths, and continue independent MRs.
- Do not read, copy, or replace `.env.local` for a rebase.
- Do not use `rm -rf`; task-owned cleanup uses `rf <path>` followed by `git worktree prune`.

## Steps

1. Create or reuse a clean worktree at the recorded remote source branch. If a local branch diverged from that remote SHA, preserve it and report `SKIP_LOCAL_DIVERGED`.
2. Run `git rebase origin/<target>`.
3. For each conflict, inspect the target version, `git rebase --show-current-patch`, and the conflicted source/callers when relevant. Resolve routine conflicts and continue the authorized rebase. Ask only when the correct behavior requires a user decision that source, history, and requirements cannot resolve; never choose `ours` or `theirs` blindly.
4. Before `git rebase --continue`, run `git diff --check` and stage only resolved paths.
5. After rebase, verify that `origin/<target>` is an ancestor and the worktree is clean. Audit the final diff and applicable project rules, then run affected correctness checks and required repository gates. Use `glab-ci` or `glab-job` only when a relevant pipeline/job artifact is part of that verification; optional e2e or prolonged CI polling needs demonstrated risk or an explicit request.
6. Report every MR as updated, already current, conflict, or blocked with its exact reason. If a required check cannot run, record the blocker.
