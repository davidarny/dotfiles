---
name: mostbet-mr-maintenance
description: Audit or rebase open Mostbet MRs in mostbet-next and publish requested branch updates.
---

# Mostbet MR Maintenance

Use this skill only for `mostbet-next`. It requires authenticated `git` and `glab` access to `gitlab.dats.tech`. Use `mostbet` for repository routing and `mostbet-page-performance` when the task also needs performance evidence.

## Scope and mode

- Keep an audit read-only. A rebase includes validation and publication under the shared autonomy policy unless the user limits it to local work. Use `mostbet-release-update` for task-to-release merges and sequential main-checkout lint/build.
- Before changing anything, record the selected MR set, each remote source SHA, target SHA, and ownership of existing worktrees. Complete the requested mode and verify its result before reporting; continue independent eligible MRs when one is blocked.
- Preserve independent candidates and published MRs. Prefer a scoped corrective commit when rewriting is unnecessary; never delete a source branch or recreate an MR as a shortcut.

## Discover the MR set

1. For one MR, read it with `glab mr view <iid>`.
2. For a batch, list only current open MRs assigned to the requested user:

   ```bash
   glab api --hostname gitlab.dats.tech 'projects/datsteam%2Fmostbet%2Fmostbet_next/merge_requests?state=opened&assignee_username=<username>&scope=all&per_page=100'
   ```

   Record IID, source branch, target branch, and URL. Read all pages when needed; use `glab-api` for pagination or fields unavailable from MR commands. Refresh assignment, state, branch heads, and remote SHAs immediately before any push.
3. Fetch current refs before changing branches:

   ```bash
   git fetch origin --prune
   ```

   Rebase only when `origin/<target>` is not an ancestor of the source branch. Do not assume every MR targets `master`; report a non-master target when the request names `master`.

## Batch helper

Use `scripts/mostbet-mr-batch.sh` for an audit or rebase when its paginated inventory and worktree layout fit the request. Inspect every returned status before the next stage. Rebase prints the source, target, and prepared SHAs for each MR. After required correctness checks, pass the original source and verified prepared SHA to push; it checks current MR/ref state and uses the exact lease. No separate state file is needed. Read the publishing workflow before using push. Resolve each failed or skipped result from its concrete cause; continue independent eligible MRs.

```bash
bash ~/.agents/skills/mostbet-mr-maintenance/scripts/mostbet-mr-batch.sh audit --assignee d.arutyunyan
bash ~/.agents/skills/mostbet-mr-maintenance/scripts/mostbet-mr-batch.sh rebase --assignee d.arutyunyan
# After required project checks:
bash ~/.agents/skills/mostbet-mr-maintenance/scripts/mostbet-mr-batch.sh push --assignee d.arutyunyan --branch <KEY> --expected-remote <original-sha> --prepared-sha <verified-sha>
```

## Mode-specific procedures

- Keep temporary worktrees and rebase mechanics in the [rebase workflow](references/rebase.md); read it before creating or reusing a worktree.
- Keep actor checks, recorded-SHA leasing, and post-push verification in the [publishing workflow](references/publish.md); read it before publication under the shared autonomy policy.

## Cleanup and report

After verification, apply `dats-team-cleanup`: remove only task-created clean worktrees whose work is safely retained and preserve pre-existing worktrees unless deletion was explicitly requested.

Apply [unslop](../unslop/SKILL.md) when reporting the outcome for each requested MR, useful completed checks, and any blocker preventing the requested update. Translate helper status codes into their concrete meaning and use descriptive MR links. Keep raw statuses and revision hashes in working records. Use [show-me](../show-me/SKILL.md) if a batch is easier to scan as a compact comparison. Do not call a mode complete until its requested remote or local state has been verified.
