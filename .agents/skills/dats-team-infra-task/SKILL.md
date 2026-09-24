---
name: dats-team-infra-task
description: File a Dats.Team infrastructure ticket through the OPS Help Desk portal when a host, network path, service, or pipeline needs the infrastructure team.
---

# Dats.Team infra tickets

Infrastructure work is requested through the Help Desk portal. A developer account cannot create an issue in `INFRASTRUC` directly; portal requests land there as ordinary issues.

Use this skill when the current task hits an infra-owned cause: a host that stopped answering, a blocked network path, a service or pipeline that needs an operator. The request that uncovered the cause authorizes the ticket, and the published ticket is the deliverable: finish it rather than handing back text. Write the ticket in Russian and follow `$jira-syntax` for markup.

## Establish the evidence

An infra engineer has to act on the ticket without asking you anything. Carry these into the body:

- the symptom in one sentence, with the exact hosts, addresses, and ports;
- when it started, read from telemetry or logs, as a date;
- a control host or path that still works, which scopes the problem instead of leaving it global;
- the check you ran and what it printed, so the engineer repeats it in one command;
- the business impact, stated apart from the symptom, because the form asks for it separately.

Prior tickets on the same host or path belong in the body too: a recurring failure changes the ask from "перезагрузить" to "разобраться с причиной".

## Create the request

Run the Jira reachability preflight from [dats-team.md](../../references/dats-team.md) first; the portal sits behind the same network as the rest of Jira.

Portal `OPS`, service desk id `23`, creates `INFRASTRUC` issues. Its catalogue and field sets are the source of truth; re-read them when a type looks unfamiliar:

```bash
curl -s -H @<(printf 'Authorization: Bearer %s\n' "$JIRA_API_TOKEN") \
  "https://jira.dats.tech/rest/servicedeskapi/servicedesk/23/requesttype?start=0&limit=25"
curl -s -H @<(printf 'Authorization: Bearer %s\n' "$JIRA_API_TOKEN") \
  "https://jira.dats.tech/rest/servicedeskapi/servicedesk/23/requesttype/<id>/field"
```

The field call returns `required` and `validValues` per field, so an option id is never a guess.

| Request type | id | Use for |
|---|---|---|
| Проблемы в разных окружениях (приложение крутится на серверах) | 892 | хост лёг, нет сетевого доступа, деградация на обычных серверах |
| Проблемы в разных окружениях (приложение в K8S-окружении) | 1232 | то же для приложений в кластере |
| Whitelists | 886 | сетевые разрешения и списки доступа |
| Починить внутренний сервис/pipeline внутреннего сервиса (Gitlab CI/CD) | 1029 | внутренний сервис или его пайплайн |
| Выдача доступа | 861 | доступ, роль или токен в GitLab, Grafana, Vault, K8S, на сервер |
| Доступ к деплой панели | 1732 | именно панель `deploy.mst9.tech` |
| Я не нашел нужного раздела | 1030 | ничего не подошло |

The catalogue holds more than fifty types, so page it: the first call with `limit=50` stops before `1030` and the server-hardware types. Fetch `start=50` too before concluding that nothing fits.

Type `892` requires `summary`, `description`, `customfield_15502` (влияние на бизнес), `customfield_15513` (ссылка на репозиторий в GitLab), `customfield_15504` (ссылка на логи или графики), `customfield_16518` (Окружение: DEV `17656`, STAGE `17657`, PROD `17658`, INFRA `17659`) and `customfield_14903` (DevTeam: `Mostbet.com` = `15802` for this workspace). A Grafana Explore deeplink showing the gap serves the logs field better than a dashboard root.

Type `861` additionally requires `customfield_15135` (кому нужен доступ, user array), `customfield_15136` (должность), `customfield_15137` (подразделение), `customfield_15138` (проект или система), `customfield_15417` (куда: GitLab `19334`, Vault `19330`, K8S `19331`, SSH `19333`, Grafana `19335`, Sentry `19336`, Nexus `19337`, Kibana `19342`, другое `19353`), `customfield_15140` (read-only `16024`, read-write `16025`), `customfield_15141` (согласующий руководитель), `customfield_15142` (СТО/тимлид) and `customfield_15404` (обоснование).

Do not ask the user for the personal fields. Copy them from their last access request:

```bash
# JQL: project = INFRASTRUC AND reporter = <username> ORDER BY created DESC
# then read customfield_15136, _15137, _15138, _15141, _15142 off an issue of type
# "Service Request with Approvals"
```

Submit it as the reporter:

```bash
curl -s -X POST -H @<(printf 'Authorization: Bearer %s\n' "$JIRA_API_TOKEN") -H "Content-Type: application/json" \
  --data @request.json "https://jira.dats.tech/rest/servicedeskapi/request"
```

with `{"serviceDeskId":"23","requestTypeId":"892","requestFieldValues":{...}}`. Build `request.json` with a script rather than a heredoc, so the Russian description keeps its newlines.

The shell already has the token as `JIRA_API_TOKEN` (from `~/.config/mcp/mcp-secrets.env`). The `-H @<(...)` form feeds the header through a pipe, so the token never appears in command arguments, where `ps` would show it; keep it out of output and files too. Only if the variable is empty, read it from 1Password:

```bash
JIRA_API_TOKEN=$(op read 'op://Dats.Team/Jira/API key')
```

`op` unlocks through the 1Password desktop app, which relocks on idle. The first call after that relock waits on an approval prompt on the user's screen and returns empty if it is not answered; `op whoami` then reports `account is not signed in` even though nothing is wrong with the login. Retry the same call once, and only treat it as a real failure if the second attempt is empty too.

Creating through `/rest/api/2/issue` or a Jira MCP create tool answers `Field 'summary' cannot be set. It is not on the appropriate screen, or unknown`. That is the project refusing create permission, so switch to the portal endpoint instead of debugging screens. `createmeta` is disabled on this instance and returns 404; issue types come from `/rest/api/2/project/<KEY>`.

When the API path fails, open `https://jira.dats.tech/plugins/servlet/desk/portal/23` in the built-in browser pane of the current app and submit the same fields through the form.

## Close the loop

- Link the new ticket to the task that uncovered the cause: the infra ticket is the side that displays `blocks`, so the source task reads `is blocked by`. When the ask removes future friction rather than unblocking the current task, use `Relates` and say so instead of overstating the dependency.
- Jira automation adds its own `relates to` between the same pair when the description mentions the source key. Remove the duplicate, keeping `Blocks` where it applies and one `Relates` otherwise.
- Link a repeat failure to the earlier ticket on the same host with `Relates`.
- Update the source task through `$dats-team-jira-comment`: edit the comment that recorded the gap so it now carries the new key, rather than adding a second comment.
- Type `892` creates a `Problem` at `Major` priority; type `861` creates a `Service Request with Approvals` that opens in `Согласование с руководителем`. Leave priority and assignee to infra triage.
- Finish with `$dats-team-cleanup`.
