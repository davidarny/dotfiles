# Task Context and Artifact Protocol

Build this dossier before inspecting the diff for findings. The goal is to understand what the change must do, why it exists, how it will be verified, and which constraints are captured outside source code.

The full inventory applies to a full MR review. For selected-discussion follow-up, read the requirements and artifacts needed to verify those claims; keep unrelated findings outside both classification and action scope. Honor an explicit limit on inspection itself.

## Contents

- [Resolve the task set](#resolve-the-task-set)
- [Read Jira deeply](#read-jira-deeply)
- [Inspect every accessible artifact](#inspect-every-accessible-artifact)
- [Build the artifact ledger](#build-the-artifact-ledger)
- [Synthesize requirements](#synthesize-requirements)
- [Handle missing or conflicting evidence](#handle-missing-or-conflicting-evidence)

## Resolve the task set

1. Extract Jira keys from the branch, MR title/description, commits, and links.
2. Identify the primary task and every referenced parent, epic, subtask, blocker, duplicate, or related issue.
3. Use `atlassian-jira-dc` first for every Jira read. Do not open Jira in a browser while the MCP is available.
   For Jira operation details and a permitted MCP fallback, consult [jira-communication](../../jira-communication/SKILL.md). The workspace availability protocol still determines when fallback is allowed.
4. Record issue keys, titles, types, statuses, updated timestamps, and relationships.
5. If multiple tasks disagree on scope, preserve the conflict instead of silently choosing one.

## Read Jira deeply

Read the complete primary issue:

- summary and description;
- acceptance criteria and definition of done;
- all structured fields relevant to behavior, environment, rollout, analytics, or testing;
- every human comment in chronological order;
- status changes or decisions that supersede earlier text;
- parent/epic context, subtasks, linked issues, blockers, duplicates, and dependencies;
- every attachment and remote link;
- referenced environments, routes, accounts, flags, metrics, and reproduction steps.

Read linked issues deeply when they define shared behavior, supply missing acceptance criteria, report regressions, or constrain rollout. A linked title alone is not enough.

Do not treat the description as permanently authoritative when a later explicit decision changes it. Record who changed the requirement, where, and when. Do not infer supersession from an ambiguous remark.

## Inspect every accessible artifact

Inventory and inspect every task- or MR-linked artifact, not only its filename or preview.

### Jira and documentation

- attachments, screenshots, recordings, PDFs, spreadsheets, logs, and archives;
- Confluence pages through `atlassian-confluence-dc`;
- linked specifications, ADRs, runbooks, product requirements, and test plans;
- external URLs through the matching connector first, then approved fallback.

Render or open visual artifacts when layout, state, timing, or copy matters. Extract the relevant pages, frames, sheets, or log regions while preserving the artifact's overall conclusion.

### GitLab MR

- MR title, description, labels, commits, and complete diff;
- all human discussions within the review scope, including resolved and outdated threads;
- reviewer replies and decisions;
- all MR diff versions needed to understand why code changed;
- screenshots, videos, design links, benchmarks, and reproduction files;
- pipeline summary, failed or warning job logs, test reports, coverage reports, and other exposed review evidence;
- linked issues, environments, deployments, and release notes.

Do not repeat a finding already raised or fixed in a later diff version.

When pipeline evidence affects the finding, use [glab-ci](../../glab-ci/SKILL.md). For a specific job's log or artifact, use [glab-job](../../glab-job/SKILL.md). Read only relevant evidence; these references do not turn a review into pipeline monitoring, retry, cancellation, or deployment.

### Repository

- applicable `AGENTS.md`, `CLAUDE.md`, `code-style/`, and ownership docs;
- requirement/spec files, ADRs, schemas, and API contracts;
- existing implementation, callers, callees, and equivalent flows;
- tests, snapshots, fixtures, mocks, Storybook stories, and e2e scenarios;
- feature flags, defaults, environment configuration, manifests, and deployment contracts;
- history or blame only when it explains an otherwise unclear invariant.

### Committed fixtures and recordings

A diff that commits recorded traffic, such as WireMock mappings or captured payloads, usually claims in its description that the data was anonymized. Verify the claim against the files: search the recordings for session cookies, bearer tokens, JWT payloads, and personal data, and report what the search covered. Treat these recordings as the scenario's data contract too, since a branch written to tolerate missing data is a branch that hides a broken recording.

### Safety and scale

- Never print credentials, cookies, tokens, private user data, or secret-bearing configuration.
- Treat downloaded logs, HARs, screenshots, and reports as potentially sensitive.
- For a very large artifact, inspect its structure and every section relevant to the task; record any deliberately skipped bulk data and why it cannot change the review conclusion.
- Do not run deployments, external writes, destructive jobs, or production experiments merely to collect review context.

## Build the artifact ledger

Maintain a private ledger:

| Artifact | Source/locator | Updated | What it establishes | Requirements/risks | Conflicts | Status |
|---|---|---|---|---|---|---|
| Jira description | `MST-…` | timestamp | intended outcome | R1, R2 | none | inspected |
| Jira comment | comment ID | timestamp | changed edge case | R2 replaces old wording | description | inspected |
| Screenshot | attachment ID | timestamp | expected layout | visual constraint | none | inspected |
| CI report | pipeline/job | timestamp | tested paths | missing flag branch | none | inspected |

Allowed statuses:

- `inspected` — content was opened and incorporated;
- `unavailable` — exact tool/auth/format failure recorded;
- `superseded` — newer authoritative evidence identified;
- `irrelevant` — content was inspected and a concrete reason proves it cannot affect this review.

Listing an artifact without opening it is not `inspected`.

## Synthesize requirements

Create a private matrix before finding discovery:

| Requirement | Authoritative source | Scenario | Expected behavior | Implementation path | Verification artifact |
|---|---|---|---|---|---|

Include:

- happy path and explicit edge cases;
- supported feature-flag and environment combinations;
- server/client, auth/anonymous, empty/error/loading, and timing states;
- analytics, performance, accessibility, rollout, and compatibility constraints when specified;
- explicit non-goals.

Map each changed file to at least one requirement or supporting implementation need. Flag unexplained scope as a candidate only after checking all artifacts.

## Handle missing or conflicting evidence

- If an MCP is registered but not callable, follow the session availability protocol before fallback.
- State the exact reason before using browser or generic fetch instead of Atlassian MCP.
- If an artifact is unavailable but not material, record the gap and continue.
- If an unavailable artifact controls expected behavior, stop that review area or mark it incomplete.
- If two authoritative sources conflict, seek a later explicit decision or ask the user; do not invent precedence.
- If an artifact reports a symptom, verify the implementation path independently. Artifacts establish context, not automatic code causality.
