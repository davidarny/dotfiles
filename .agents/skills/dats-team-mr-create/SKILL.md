---
name: dats-team-mr-create
description: Prepare, create, or correct Dats.Team GitLab merge requests using the team's title and description conventions.
---

# Dats.Team MR creation

Use this skill for MR preparation, description correction, or publication from a repository under `~/Developer/Dats.Team` on `gitlab.dats.tech`. Read the nearest repository instructions and, when present, `.claude/commands/create-mr.md`; follow `$glab-mr` for GitLab operations and use `glab`, never `gh`.

## Scope and mode

- Use `Create` for MR delivery included in the requested implementation or publication under the shared autonomy policy. Use `Prepare` when the user asks only for draft text or explicitly excludes publication. `Prepare` returns the body without GitLab writes; `Create` includes the scoped push and MR creation. A GitLab draft is `Create` with `--draft`. Do not ask for permission again.
- A description-only correction changes only the requested body: preserve title, assignee, reviewers, branches, and code, then verify both the corrected fact and removal of superseded wording.
- For a description-only edit of an existing MR, use its current metadata and authorization, then skip repository creation preconditions, duplicate lookup, push, and MR creation. Apply only the body rules and verify the edited MR.
- Apply these workspace overrides: target `master`, assign `d.arutyunyan`, and use the uppercase Jira branch key, with its kebab-case suffix when the branch carries one. For `performance-synthetic-monitoring-tests`, request reviewers `i.tyapkin` and `m.maklashov`; otherwise follow explicit repository reviewer rules or automation. Project automation can overwrite reviewers at creation, so read them back and set them again if they differ.

## Preconditions

Run independent checks together and stop on a required failure:

1. `git rev-parse --show-toplevel` must resolve inside `/Developer/Dats.Team/` or `/Developer/dats.team/`, including an allowed submodule or sibling `<repo-name>-<KEY>` checkout.
2. Normalize `git remote get-url origin` and require host `gitlab.dats.tech`; derive the project path from that remote.
3. Require `git rev-parse --abbrev-ref HEAD` to match `^[A-Z]+-[0-9]+(-[a-z0-9-]+)?$`: the Jira key, optionally followed by a kebab-case suffix when one task carries several branches. Take the key from the part before the suffix. Preserve a nonconforming branch and resolve its identity; never rename it silently.
4. Inspect `git status --porcelain`, separating unrelated work from the scoped commits. Fetch `origin/master`, then require at least one commit in `origin/master..HEAD`.

Gather the task commits and diff (`git log`, `git diff --stat`, `git diff`). For a very large diff, use the commits and stat plus focused reads. Keep dynamic values in safely quoted arguments or a temporary description file; never use `eval`.

## Title and description

When composing a new task commit subject as part of authorized work, apply [caveman-commit](../caveman-commit/SKILL.md) within the project's commit rules. When deriving an MR title from an existing commit, copy that subject unchanged as required below; the wording skill does not authorize rewriting commits or running git operations.

Choose the task commit, excluding incidental merge commits, and copy its final subject exactly in the form `<type>: [<JIRA-KEY>] <lowercase imperative summary>`; do not independently reword it, add a scope, or fabricate a ticket. If several task commits make that choice ambiguous, resolve it from scope or ask one focused question.

The body starts directly with these three sections, in this order, and contains no other section:

```markdown
## Кратко
Одно или два предложения о сути и причине изменения.

## Что изменено
- Логические изменения с описанием смысла.

## Зачем
Техническая или продуктовая причина и неочевидные компромиссы.
```

Include a Jira link in `Кратко` only when the context supplies one. Keep QA guidance and detailed evidence in Jira through `$dats-team-for-qa` and `$dats-team-jira-comment`, never in the MR. Do not invent checks, results, screenshots, or user actions; do not publish local paths, hosts, ports, worktrees, temporary artifacts, secrets, or private tooling. Apply [humanizer](../humanizer/SKILL.md) in embedded mode, then [unslop](../unslop/SKILL.md) for reader-first reporting, retaining the three headings and supported facts. Preserve exact technical details only where the reader needs them to understand the change; keep operational identifiers in working records. The result must contain no em or en dash.

Use [show-me](../show-me/SKILL.md) within these sections when a before/after comparison or small flow makes the change easier to understand. Choose a view supported by GitLab; a simple change can stay in prose.

## Review and publication

In `Create` mode, verify `glab` authentication and run the duplicate check before any push:

```bash
glab mr list --source-branch "$branch" --target-branch master --output json --per-page 100
```

If an open MR already uses this source and target, reuse it and complete the requested branch/body update; do not create a duplicate or stop before delivering the update. In `Prepare` mode return the following reviewable block. In `Create` mode validate the same fields internally and publish without an approval ceremony:

```text
Branch:  <branch>  →  master
Ticket:  <JIRA-KEY>
Assignee: d.arutyunyan
Title:   <title>

--- description ---
<the complete body>
---
```

When reusing an existing MR, skip `glab mr create` and update only the requested metadata. Apply the same branch push and read-back checks below.

Before publishing, fetch the current relevant refs and inspect the upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{u}`. When an upstream exists, require it to be exactly `origin/<branch>`, compare its fetched head with the reviewed commits, reconcile only authorized remote changes, and preserve unpublished or unrelated commits. Require a fast-forward push and never force-push as part of MR creation. Push only the scoped commits, then require `git ls-remote --exit-code origin "refs/heads/$branch"` to point to the reviewed `HEAD`.

With authenticated `glab`, inspect the installed `glab mr create --help`, prefer `--description-file`, pass `--target-branch master`, `--source-branch`, `--assignee d.arutyunyan`, required reviewers, and `--draft` only in GitLab draft mode. Verify the returned title, body, source/target, assignee, reviewers, and draft state; after an ambiguous failure, inspect the source branch before retrying. For an authorized URL handoff, or when the CLI/auth path is unavailable after reporting the duplicate-check limitation, construct the URL-encoded `/-/merge_requests/new` link with source, target, title, and description after validating those fields. Above 7,500 characters omit only the description and print the body separately. The prefilled URL never submits the MR and still requires setting `d.arutyunyan` manually before submission.
