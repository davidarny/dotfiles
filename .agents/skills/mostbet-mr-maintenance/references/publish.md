# Publishing rewritten branches

Use this reference for publication included in the requested rebase or branch update. Honor an explicit local-only limit; otherwise follow the shared autonomy policy without another confirmation.

Before any GitLab write, verify the visible actor:

```bash
glab auth status --hostname gitlab.dats.tech
glab api --hostname gitlab.dats.tech user
```

Re-read the remote source ref and compare it with the SHA recorded before preparation. If it advanced, stop, fetch, and reconcile that MR. Bind the lease to the recorded SHA:

```bash
git push --force-with-lease=refs/heads/<branch>:<recorded-remote-sha> origin <branch>:refs/heads/<branch>
```

If the lease fails, stop for that MR and report the concurrent update; never replace it with an unconditional force-push. After success, read the remote ref back and compare it with the prepared local SHA. A local rebase, published branch, passing CI, and merged MR are separate states.

The batch helper's push mode takes the same original remote SHA and the verified prepared SHA as explicit arguments. Run the required project checks before invoking it; a successful rebase alone does not prove test success. Do not publish a branch whose target ancestry, worktree cleanliness, or prepared SHA has not been rechecked.
