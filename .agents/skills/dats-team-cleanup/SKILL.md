---
name: dats-team-cleanup
description: Clean up task-owned resources and restore task-switched checkouts when finishing Dats.Team work.
---

# Dats.Team Cleanup

Use only under `~/Developer/Dats.Team` (case-insensitive path) before the final response. For a read-only task with no temporary worktrees, artifacts, browser sessions, or branch changes, finish without a cleanup disclaimer.

## Ownership

Track in-session:

- named `agent-browser` sessions created for this task, including namespace;
- temporary worktrees created as direct repository siblings named `<repo-name>-<JIRA_KEY>` or `<repo-name>-<JIRA_KEY>-<lowercase-suffix>`;
- temporary artifacts created outside those worktrees, separately from requested deliverables and evidence;
- primary checkouts whose branch this task changed.

Never infer ownership from a path. A worktree must still be registered by `git worktree list --porcelain`, recorded as task-created, and located at the expected sibling path for its source repository. Preserve pre-existing worktrees, artifacts, branches, repositories, and shared sessions.

## Cleanup

1. When recorded task-created browser sessions exist, list them with the lifecycle commands in `$agent-browser`, close only those sessions, and recheck them. When none were created, skip browser commands. Leave unnamed, shared, pre-existing, or unrecorded sessions untouched.
2. For each recorded worktree, inspect its status and repository registration. Remove it only when registered, clean, its absolute path is the recorded repository's direct sibling with the allowed name, and its requested deliverables are retained outside the removal scope. Preserve it when the user needs an output at its current path. Run `rf <worktree>` from outside it, then `git worktree prune`.
3. After verification, remove only separately recorded temporary artifacts with `rf <path>`. Preserve requested deliverables, source evidence, and primary-checkout files.
4. For each primary checkout whose branch this task changed, require a clean status and verify that another task has not since taken ownership of it. Detect the default branch with `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`; remove `origin/` and switch only when currently elsewhere, unless another final branch was explicitly requested. If `origin/HEAD` is unavailable, use `master` only when that local branch exists; otherwise report the blocker.

If `rf` is unavailable, stop before deletion. Preserve dirty, missing, unregistered, requested, or pre-existing resources and report the exact reason when it blocks requested cleanup. A cleanup blocker does not invalidate the completed implementation. Do not fetch, pull, rebase, reset, stash, force-checkout, delete branches, or alter remote or deployed state. Recheck affected sessions and repositories. Apply [unslop](../unslop/SKILL.md) when reporting meaningful cleanup actions or a blocker requiring attention; omit routine inventories of untouched resources.
