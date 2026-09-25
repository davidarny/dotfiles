---
name: mostbet-page-performance
description: Diagnose production Mostbet page performance from Catchpoint WebPageTest exports and verify candidates through GitLab deployments plus comparable WPT runs on preprod14/15.
---

# Mostbet Page Performance

Investigate one verified bottleneck at a time. Treat source inspection and single runs as diagnostics; claim an optimization only after repeated comparable baseline and candidate measurements.

Use repository tools and ordinary shell commands directly. Do not depend on skill-local scripts, generated registries, lane locks, or orchestration helpers.

## Boundaries

- When Jira context is needed, read it through the Atlassian Jira MCP.
- Use Grafana when the task describes a production regression.
- Use current evidence appropriate to the claim: source for implementation, installed versions for API contracts, runtime artifacts for observed behavior, and history for prior design decisions. Memory and earlier reports are leads to verify.
- If the user asks to start an investigation over without prior agent work, build a fresh evidence chain from the supplied inputs. Do not import conclusions from the excluded session or its scratch artifacts.
- Separate `verified fact`, `hypothesis`, and `unknown`. Publish only verified facts unless the user explicitly requests hypotheses.
- For implementation, complete scoped commits, push, and MR delivery under the shared autonomy policy. An investigation-only request retains that scope. If the user excludes remote deployment, finish source and artifact analysis without running a candidate comparison.
- Updating a test environment or rolling it back is a separate external action. Use the user's established authorization; a monitor, cron entry, or finished measurement does not authorize a rollback.
- Preserve unrelated changes. Never reset, clean, stash, stop, or delete work owned by another task.

## Completion

Finish safe, available checks needed to resolve the requested performance claim. For each material uncertainty, choose a check that can verify or falsify it and follow the evidence until resolved or blocked by an identified access, infrastructure, or reproduction constraint. Inspect runtime network behavior when build inventory cannot establish what the browser loaded.

Keep task resources until the required evidence is captured. An intermediate finding is not a completion point while requested checks remain. A user stop, narrower scope, or time/resource limit takes precedence; finish independent work within that boundary and state what the missing evidence prevents.

## Preflight

Before reading evidence or touching any system, run [preflight](references/preflight.md): prove every access and tool the task will need with one real call each, acquire its secrets once, and choose transports that need no approval. Preflight is complete when every needed check has passed or has a named fallback, and the user has been told in one message that they can leave, together with the only events that would call them back.

## Choose the work needed

- For source, Jira, dashboard, or supplied-artifact analysis, follow the diagnosis workflow below.
- Before creating, provisioning, or committing from a task worktree, read [Mostbet worktrees](../mostbet-worktrees/SKILL.md).
- Before configuring, launching, monitoring, or exporting Catchpoint WebPageTest, read [WPT investigations](references/wpt.md). It holds the whole REST sequence — credential, endpoints, payload, node/device/connection ids, result field map — so run it rather than researching the API. Follow it through completed exports and page-identity validation, not just test submission.
- Before pushing candidate revisions, triggering GitLab build/deploy pipelines, or reading any preprod measurement, read [runtime and captures](references/runtime.md). It holds the whole preprod path — stands, deploy readback, narrowed Sitespeed pass, the Grafana series to read first, the on-box reports to fall back to, and the runner restore that ends the task.
- Before choosing or implementing a performance candidate, collecting new runs, or assessing baseline/candidate comparability, read the relevant sections of [candidate verification](references/candidate-verification.md). Its implementation section applies only when changing a candidate is in scope.

## Workflow

### Define the measured problem

Start from the supplied evidence and requested claim. For a Jira investigation, read its description and comments; for a production regression, inspect the relevant Grafana panel or current production evidence.

Establish the production symptom before building a candidate. Run the affected production page through Catchpoint WPT, or reuse a current valid supplied series, then download, validate, and analyze the required exports. Use that evidence to admit hypotheses and candidates. Production results diagnose the problem; candidate acceptance comes from comparable preprod baseline/candidate WPT runs.

When the investigation includes the task's broader history and related work, read chronological comments, changelog, current and historical issue links, key mentions, relevant Confluence pages, and MR/development context. Record which decisions supersede earlier requirements.

Survey existing work before admitting a candidate, and survey it whole rather than from the first page a list command happens to return:

- **Merge requests.** Read the count first — `X-Total` on `merge_requests?state=opened&per_page=1` — then page through all of them and filter the complete set. Repeat for `state=merged` over a window covering the task's age. A merge that lands during the investigation moves the baseline: check whether production already serves it before trusting an earlier measurement.
- **Jira.** Search the route itself, not only the task key. A closed earlier investigation of the same page carries its measurements and its rejected hypotheses. Read the parent's `issuelinks` for the whole decomposition, and read the sibling tasks that already reached a verdict — they establish which remedy this codebase accepts for a given cause, so the candidate matches the existing pattern instead of inventing a second one.

Name the covering MR or issue for every cause you decide not to pursue.

Keep the user's route, metric, period, product, and exclusions explicit. In a route-specific investigation, distinguish the route's contribution from shared layouts/chunks and previously tracked defects. A known CAPTCHA, analytics request, off-screen component, or global bottleneck is not automatically a new route finding. Include it only when current evidence makes it relevant to the requested scope.

Record:

- exact route, locale, viewport, DPR, cache mode, connectivity, and auth state;
- reported metric and affected cell;
- expected final pathname and one stable page-specific DOM marker;
- forbidden states such as 404, login redirect, guest shell, skeleton, or error page.

Read the producer's metric definition, units, labels, and aggregation before interpreting a dashboard. Page-level response-code totals, SSR upstream counters, browser API timings, and server processing time cover different events. Query samples and Prometheus step points are not independent browser runs; count actual runs from their source records.

If the required cell or page identity cannot be validated, stop conclusions and comparisons that depend on it. Mark mismatched measurements `invalid` and missing evidence `inconclusive`; continue independent source or artifact checks within scope.

A by-design redirect measures its destination. An unavailable account/flag/balance prerequisite does not justify copying conclusions from another page. Report the prerequisite and change a monitor only when that change is authorized.

### Prove the bottleneck

Build the shortest complete evidence chain:

```text
late pixels -> viewport element -> component -> render/data boundary -> request or resource -> timing -> source condition
```

Use filmstrips, screenshots, HAR, traces, resource timing, DOM state, source, and git history as needed. Distinguish delayed request discovery from backend time, transfer time, and main-thread rendering. Verify runtime state for auth, feature flags, media queries, lazy boundaries, hydration gates, and waits; source alone proves only possible behavior.

When the task covers JS and HTML, inspect both generated payloads and their browser delivery. Use GitLab build or analyzer artifacts for generated size or duplication claims and remote runtime evidence for loaded resources. Separate shared versus route-specific bytes, compressed transfer versus decoded size, and build inventory versus actually requested chunks. Verify the installed framework contract before recommending configuration changes.

Before changing an existing SSR/layout boundary, inspect why it was introduced and verify that the candidate preserves that invariant. State a measured contribution or a clearly labelled estimate; do not promise an improvement percentage from source size alone.

Challenge attractive explanations with the raw trace. A connectivity label does not establish the throttling mechanism; matching cache headers do not establish the same CDN edge. Validate those claims from the runner configuration, protocol evidence, and request metadata before using them as causes. For runner/authentication defects, inspect the synthetic journey and a working CI login flow before changing application behavior.

### Admit a candidate

Do not edit source or start a candidate build until the baseline proves the candidate's measured contribution and complete path:

```text
loaded artifact -> module -> primary page content -> render or data boundary -> source condition
```

For JS and HTML work, rank the initial first-party chunks, HTML payload, and main-thread tasks before choosing a target. Start with the page's primary content graph, including listings, cards, data hooks, filters, state, and pagination. Admit auxiliary metadata, analytics, or utility work only when measurements show that it materially contributes to the requested problem.

Record the target's current transferred or decoded bytes, main-thread duration, route-specific versus shared ownership, why the browser loads or executes it now, the exact work the candidate should remove or defer, and the correctness invariant. Derive materiality from the measured baseline rather than assumed chunk ownership or source size. If any link or contribution remains unknown, continue diagnosis instead of implementing a diagnostic guess.

### Verify a candidate

When the task calls for an optimization comparison, read [candidate verification](references/candidate-verification.md). This covers baseline identity, independent candidates, repeated samples, and acceptance criteria. An investigation-only request ends with the supported diagnosis; it does not require implementing a candidate.

### Report the result

Define only the performance-specific result here. When the result is intended for Jira, apply `$dats-team-jira-comment` for comment structure, wording, validation, authorization, and publication.

Publish one comment per candidate, as soon as that candidate reaches a verdict, rather than one combined report at the end of the task. Each comment stands on its own: the symptom it targeted, the source change, the revisions and conditions measured, the numbers on both sides with the guards, the verdict, and the MR. A reader following the task then sees which change bought which metric. State the shared diagnosis once, in the first such comment or its own, and reference it from later ones instead of repeating it.

Report measurement validity and candidate outcome separately when they differ. Use the applicable verdict for the series or candidate being assessed:

- `accepted`: repeated comparable evidence proves the improvement and guards are safe;
- `rejected`: the candidate is worse or a guard regresses;
- `inconclusive`: evidence is too noisy or a verified blocker prevents a conclusion;
- `invalid`: page identity or measurement conditions differ;
- `stopped`: the user deliberately stopped the attempt.

Classify the measurement separately from the candidate: mismatched identity or conditions invalidate the series; missing evidence leaves the claim inconclusive. Decide candidate acceptance or rejection only from valid comparable evidence. A partial diagnosis can establish one fact while leaving another unproven.

Apply [unslop](../unslop/SKILL.md) to lead with the verified symptom, cause, and measured outcome. Use [show-me](../show-me/SKILL.md) when a comparison or causal flow helps the reader. For a candidate comparison, keep the diff, exact revisions, conditions, sample counts, median, p90, variation, delta, guard results, correctness checks, and verdict in the evidence record. Present the measurements and conditions needed to assess the claim, with descriptive links to supporting detail; do not turn that record into a mandatory reporting template.

For an investigation without a candidate, report the verified diagnosis and its limits rather than forcing an acceptance benchmark. A preprod PoC, passing CI, deployment, and post-deploy effectiveness are separate results. Do not claim the production symptom is fixed until production evidence supports it. If the user will supply a new snapshot or explicitly declines polling, wait for that input without creating a monitor.

If the user stops attempts against a hanging or inaccessible source, preserve that access boundary. Finish independent source and artifact checks and report which claim the missing evidence prevents; do not keep retrying the same SSH or secret lookup.

Support the performance claims with reachable repository, Jira, and Grafana evidence where available.
