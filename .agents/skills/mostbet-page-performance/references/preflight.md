# Preflight

Run this before reading evidence or touching any system. The goal is an **unattended** run: every access the task will need is proven now, while the user is still at the keyboard, so the investigation and measurements that follow never stop on a prompt, an approval dialog, or a broken tool.

## Prove each access with one real call

Registration, a running process, a config entry, or `glab auth status` alone is not proof. Make one read-only call per row the task needs and record the result.

| Need | Proving call | What this setup gets wrong |
| --- | --- | --- |
| Network | The Jira reachability check in `~/.agents/references/dats-team.md` | It gates every row below; a failure means GlobalProtect, not credentials. |
| Jira, Confluence | Read the task issue and its comments through the Atlassian MCP | — |
| GitLab API | `projects/<id>` for `datsteam/mostbet/mostbet_next` and `datsteam/performance/performance-synthetic-monitoring-tests`; read `permissions.project_access` and `permissions.group_access` | Playing `deploy_single` and pushing deploy tags need Developer or higher on the effective level. |
| Git transport | `git fetch` over HTTPS with `glab auth git-credential`, as `dats-team.md` describes | SSH signs through the 1Password agent. The request that raises the approval dialog fails with `communication with agent failed` while the dialog is still open; the next request succeeds once the user approves. For the unattended part of the run, use HTTPS. |
| Stands | `curl` the task route on `preprod14` and `preprod15` with `Cookie: wellcome=in202511`, expecting 200 | — |
| Preprod runners | `ssh speed.mumbai.preprod 'hostname; pgrep -af loop.sh'`, then the same for `speed.frankfurt.preprod` | `Host speed.*` connects through `~/.ssh/sitespeed-proxy`, which adds a VPN route with `sudo` and so only works while the user can answer. A fresh `known_hosts` has no entries for the runners, which shows up as `Host key verification failed`. Show the user the fingerprints from `ssh -v -o UserKnownHostsFile=/dev/null`, accept them with `StrictHostKeyChecking=accept-new` once approved, and confirm with `ssh-keygen -lF <ip>`. Record whether `loop.sh` runs the full preprod suite or an earlier narrowed pass. |
| Grafana | One datasource read (uid `ac874ca1-8d7f-4da8-8b3f-37df78544021`) through the Grafana MCP | A `TLS handshake timeout` while `curl` to the same host succeeds means `mcp-grafana` was built with Go 1.27: its ClientHello lists ML-DSA, and the IPS on the GlobalProtect path drops it. The dotfiles pin a Go 1.26 build (`mcp/servers.toml`). Until the server is fixed, query the HTTP API with the same key: `~/.claude.json` stores the `${GRAFANA_API_KEY}` placeholder, and the shell environment holds the value. PromQL goes to `/api/datasources/proxy/uid/<uid>/api/v1/query`. |
| Catchpoint | Take the API key into a [1password-handoff](../../1password-handoff/SKILL.md) snapshot, then make one `GET /history` call | Its approval prompt must happen during preflight, not in the middle of the measurements. |
| Auth token | Decide from the canonical suite whether the task measures an authenticated cell; if it does, obtain the token now | The Sitespeed auth suite takes the token from `PERF_AUTH_TOKEN` (`tests/scripts/auth.cjs`). |
| Code navigation | `codegraph status mostbet-next` and one FFF search inside the repository | — |

Leave out a row only when the task clearly will not use it, for example runners and stands during an investigation that excludes preprod.

## Handle a failing check

Name the layer that failed (network, transport, authentication, host key, tool process), make one bounded probe, and then either use the documented fallback or ask the user a single question. If the user is repairing something, wait and rerun only that check. A broken tool that is not needed right away but will take time to diagnose can go to a separate session with the full symptom and probe record, while this task continues on the fallback.

## Release the user

Preflight ends with one message: a table listing every check and its result, then a plain statement that the user can leave. After that come only the events that would bring the user back, such as a GlobalProtect disconnect (the runner route needs `sudo` again), a missing secret, or the decision on keeping or dropping a route added to the preprod suite. Anything that can be settled with a sane default, like restoring runners to the state on `master`, is stated as that default instead.
