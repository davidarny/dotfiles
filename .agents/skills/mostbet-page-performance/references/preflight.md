# Preflight

Run this before reading evidence or touching any system. The goal is an **unattended** run: every access the task will need is proven now, while the user is still at the keyboard, so the investigation and measurements that follow never stop on a prompt, an approval dialog, or a broken tool.

## Prove each access with one real call

Registration, a running process, a config entry, or `glab auth status` alone is not proof. Make one read-only call per row the task needs.

| Need | Proving call | Gotcha |
| --- | --- | --- |
| Network | The Jira reachability check in `~/.agents/references/dats-team.md` | Gates every row below. |
| Jira, Confluence | Read the task issue and its comments through the Atlassian MCP | |
| GitLab API | `projects/<id>` for `datsteam/mostbet/mostbet_next` and `datsteam/performance/performance-synthetic-monitoring-tests`; read `permissions.project_access` and `permissions.group_access` | Playing `deploy_single` and pushing deploy tags need Developer or higher on the effective level. |
| Git transport | `git fetch` over HTTPS with `glab auth git-credential` | SSH waits for a 1Password approval, so use HTTPS for the unattended part. |
| Stands | `curl` the task route on `preprod14` and `preprod15` with `Cookie: wellcome=in202511`, expecting 200 | |
| Preprod runners | `ssh speed.mumbai.preprod 'hostname; pgrep -af loop.sh'`, same for `speed.frankfurt.preprod` | The SSH proxy adds a VPN route with `sudo`, so the first connection needs the user. `Host key verification failed` means the runner is missing from `known_hosts`: show the user the fingerprint and accept it with `StrictHostKeyChecking=accept-new`. |
| Grafana | One datasource read (uid `ac874ca1-8d7f-4da8-8b3f-37df78544021`) through the Grafana MCP | |
| Catchpoint | Take the API key into a [1password-handoff](../../1password-handoff/SKILL.md) snapshot, then one `GET /history` | |
| Auth token | Needed only when the canonical suite measures the route authenticated; obtain it now | |
| Code navigation | `codegraph status mostbet-next` and one FFF search inside the repository | |

Skip a row only when the task will not use it.

## Handle a failing check

Name the failing layer, make one bounded probe, then use a fallback or ask the user one question. A broken tool that needs lengthy diagnosis goes to a separate session with the full symptom record while this task continues.

## Release the user

End preflight with one message: the check table, then a plain statement that the user can leave, with the only events that would call them back. Settle everything else with a stated default.
