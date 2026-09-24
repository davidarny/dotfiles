# Dats.Team

Rules for Dats.Team work. `AGENTS.md` points here; they are as mandatory as `AGENTS.md` itself.

## Dats.Team network access

- Before the first network request to any Dats.Team resource in a turn, verify real Jira reachability with:
  `curl --silent --show-error --fail --connect-timeout 5 --max-time 10 https://jira.dats.tech/rest/api/2/serverInfo | jq -e '.baseUrl == "https://jira.dats.tech"' >/dev/null`
- This preflight gates all Dats.Team hosts and tools, including GitLab and the MCP servers `elasticsearch-main`, `mostbet-elasticsearch`, `grafana`, `atlassian-jira-dc`, and `atlassian-confluence-dc`.
- If the preflight fails, do not call Dats.Team resources and do not diagnose the failure as credentials, permissions, MCP startup, or service health yet. Tell the user that GlobalProtect may be disconnected, ask them to connect it, and rerun the preflight after they confirm.
- Rerun the preflight before troubleshooting any Dats.Team `403`, timeout, DNS, connection, or unexpected MCP availability error. GlobalProtect processes, the enabled system extension, and `utun` interfaces do not prove that its tunnel is connected.

## Dats.Team projects

Applies to Dats.Team projects, normally located under `~/Developer/Dats.Team`. Ignore this section for unrelated projects.

- Task branch: the exact Jira key, e.g. `MST-185094`, `INFRASTRUC-79752`. When one task needs several branches at once, suffix the key in kebab-case: `<KEY>-<suffix>`, e.g. `MST-207625-sidebar`. Commits still carry `[<KEY>]`. Derive the key from the issue, current branch, or MR; ask only when creating a task branch requires an unknown key. Existing release branches use the exact supplied release name through `mostbet-release-update`. Read-only work needs no new branch or invented key.
- Commit: `type: [KEY] imperative lowercase description`, no period. Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `style`, `ci`, `build`.
- Forge: GitLab at `gitlab.dats.tech`. Use authenticated `glab`, never `gh`. Run `glab` from the target repository checkout; outside one, `glab` targets `gitlab.com`, so pass `--hostname gitlab.dats.tech` to `glab api` and `-R gitlab.dats.tech/<group>/<project>` to other commands. Treat a GitLab `401` as a token problem only after confirming the request went to `gitlab.dats.tech`.
- MR: follow [dats-team-mr-create](../skills/dats-team-mr-create/SKILL.md) for title, Russian body, assignee, reviewers, duplicate handling, and publication. Prefer a description file for multiline text; use `master` for task MRs unless the requested workflow specifies another target.
- View pipeline: `glab mr view <id>`, `glab ci status`
- GitLab issue comments use `glab issue note`; Jira comments use the Atlassian route below. Do not substitute a GitLab issue for a Jira issue.
- Browser: `glab mr view <id> -w`
- Say MR, not PR, for GitLab.
- Write code comments, JSDoc, Jira comments, and GitLab MR review comments in Russian.
- Dats.Team task worktree: for `mostbet-next`, follow [mostbet-worktrees](../skills/mostbet-worktrees/SKILL.md); it selects the layout supported by the task base, provisions the checkout, and validates Jira-labelled commits. For other repositories, when isolation is needed, create a direct sibling at `<repo-parent>/<repo-name>-<KEY>` using branch `<KEY>` from the current task base, normally `origin/master`, or attach the existing branch. Follow current repository provisioning instructions, inspect `.env.local` metadata before touching it, and use `mise` when dependencies are required.

## Dats.Team cleanup

Before the final response of every completed Dats.Team task, invoke the `dats-team-cleanup` skill. It removes only task-owned clean resources and restores only branches changed by that task. When there is nothing to clean up, finish without a cleanup disclaimer.

## Atlassian

For every Jira or Confluence URL, issue/page lookup, search, or action, **always use the matching Atlassian MCP first**: `atlassian-jira-dc` for Jira and `atlassian-confluence-dc` for Confluence. Extract the issue key or page identifier from the URL and call MCP directly; do not open the page first. Never use `agent-browser`, built-in browser, or generic web fetch while the matching MCP is available. Browser fallback is allowed only after verifying that MCP is unavailable/disconnected, authentication failed, or the required operation is UI-only/unsupported; state the reason before falling back.
