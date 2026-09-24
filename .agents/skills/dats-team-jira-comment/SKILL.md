---
name: dats-team-jira-comment
description: Draft, publish, or edit Dats.Team Jira comments for results, decisions, status, and evidence.
---

# Dats.Team Jira comments

Own the comment's evidence, authorization, and publication. Follow current workspace Atlassian routing and apply `$jira-communication`, `$jira-syntax`, and `$humanizer`; keep their tool and markup rules there.

## Mode

Determine the result and authorization from the current request and context:

- `Draft` prepares text without Jira writes.
- `Publish` adds one new comment only with explicit publication authorization.
- `Edit` changes one existing comment only when its target is explicitly identified or confirmed.

Investigation, reporting, finishing a task, creating an MR, or showing a draft does not authorize a Jira write. Comment permission does not include changing fields, status, assignee, links, attachments, or other issue state.

## Evidence

1. Resolve the exact issue key; read its summary, description, current comments, and relevant linked evidence.
2. Check the latest comments for an identical result before posting. Inspect linked tasks, MRs, dashboards, or repository evidence when they support the requested claim.
3. Complete safe in-scope checks before drafting. State verified facts as facts, mark material hypotheses and unknowns, and match wording to the actual decision state (proposal, local implementation, published MR, deployed, or verified after deployment).
4. Verify Jira link type and direction from the current issue's side before describing a dependency.

## Body

Apply [unslop](../unslop/SKILL.md) for concise natural prose. Lead with the outcome in natural Russian, then include the observations or decisions the reader needs. Report completed work; follow the global communication rules instead of automatically listing skipped checks or scope exclusions. Keep technical bookkeeping in the evidence record and use descriptive links in the comment.

Choose length and structure for the content. A detailed investigation may use `h3. TL;DR`; a short result needs no summary heading. Use [show-me](../show-me/SKILL.md) when a comparison, sequence, or check/result view helps, rendered in Jira wiki markup. Choose table columns for the actual information; a table is optional. Use a supported list or table rather than an unsupported diagram or a local HTML link. Do not add TL;DR to a `For QA` handoff.

Keep published text self-contained. Link only reachable Jira issues, MRs, repository files, dashboards, or documentation. Keep local paths, hosts, ports, temporary artifacts, skill internals, secrets, cookies, tokens, and raw sensitive logs out of it. For QA, use `$dats-team-for-qa`; it owns the body and publishes into the issue description.

## Validate and publish

After the factual draft, apply `$humanizer` in embedded mode and `$unslop`, then check the global communication rules. Apply `$jira-syntax` and its validator as a separate gate. Apply the latest requested wording and scope; an edit to one comment does not rewrite earlier issue history.

In `Draft` mode return the final Jira-formatted body. In `Publish` or `Edit` mode perform exactly one authorized comment operation, verify the issue key, comment ID, author, and returned body, and read it back only when the write response is insufficient. On an ambiguous write, verify Jira before retrying; never add a second comment merely to supply a missing summary. Remove task-created validation files with `$dats-team-cleanup`.
