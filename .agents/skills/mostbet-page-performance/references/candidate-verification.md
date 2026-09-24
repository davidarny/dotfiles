# Candidate verification

Read this when comparing baseline and candidate performance. Before pushing measurement refs, triggering either deploy pipeline, or submitting a preprod WPT series, read [runtime and captures](runtime.md).

## Establish a baseline

When source changes need isolation, create, provision, and commit from the task checkout through [Mostbet worktrees](../../mostbet-worktrees/SKILL.md). Preserve existing worktree changes.

Measure the affected cell first. Add control cells only for plausible regressions or the requested coverage.

Validate page identity in every measured iteration. For authenticated routes, inject the token through the environment and assert the authenticated page marker. For anonymous routes, remove `user_token` and reject authenticated content.

Use Catchpoint WPT for the production investigation and preprod candidate comparison. Inspect the actual test setup and request headers; limits of one public test flow do not establish that all WPT authentication is unsupported. Retain the source's measurement limits.

Record the base revision, source diff state, GitLab pipeline and job URLs, deployed revisions, WPT test IDs and result URLs, node/device/browser versions, route identity, viewport/DPR, cache mode, auth state, sanitized cookie names and state, connectivity, and capture configuration. Baseline and candidate must differ only by the source change and their assigned stand; the crossover must reverse that assignment.

Match the actual user agent and backend environment as well as viewport and throttling. Desktop Chrome with a narrow viewport is not an iPhone run. A preprod frontend using production APIs remains a preprod result with that backend, not a production frontend measurement.

## Admit one candidate

Before editing source or triggering a candidate build for JS or HTML work:

1. Rank the initial first-party chunks, HTML payload, and main-thread tasks by measured contribution.
2. Map the target through `loaded artifact -> module -> primary page content -> render or data boundary -> source condition`.
3. Start attribution at the primary content graph: listings and cards, their data adapters and hooks, filters, state, pagination, then shared UI used by that content. Move to route-specific secondary content and auxiliary metadata, analytics, or utilities only when their measured contribution is material.
4. Record current transferred and decoded bytes or main-thread duration, route-specific versus shared ownership, why the work loads or executes now, what the candidate should remove or defer, and the behavior it must preserve.
5. Derive the acceptance threshold from that baseline contribution. Do not use an assumed chunk owner, source-file size, or convenient edit boundary as the target.

If a required link or contribution is unknown, continue attribution. Source possibility and a cheap edit do not admit a candidate.

## Test one candidate

For an existing candidate, validate its diff and evidence. Implement or revise it only when changes are in scope.

Implement the smallest readable change that tests one verified cause. Preserve the reason and invariant behind the current behavior. Do not combine unrelated optimizations.

Run focused correctness checks before performance measurements. If the candidate changes after measurement starts, discard that series and start a new candidate series.

When a candidate targets what an accepted candidate left behind, both arms of its comparison must carry that accepted change; otherwise the earlier cause still dominates and hides the residual. A page whose content mounts late swamps a 0.17 CLS residual from its sidebar; measured against the accepted content fix, the same residual reads cleanly.

That needs two branches with different lifetimes. The reviewable one stays off `master` and contains only its own change, so the MRs never duplicate each other and merge in any order. The deployed one is a `<KEY>-measure-<suffix>` branch per [Mostbet worktrees](../../mostbet-worktrees/SKILL.md): disposable, named after the change under test rather than the accumulated stack, and deleted once the verdict is recorded. Put the base SHA and the applied change's SHA in the evidence, not just the combined SHA, or deleting the branch strands the revision the numbers refer to.

Write down what the candidate should move, and by roughly how much, before the first pass lands. A prediction recorded in advance is falsifiable; the same sentence written afterwards is not, and it is the only cheap guard against reading a stand effect or a coincidence as the candidate's.

Keep independent candidates identifiable. Give each its own branch: one investigation task carries several through the `<KEY>-<suffix>` form in [Mostbet worktrees](../../mostbet-worktrees/SKILL.md), so a second candidate needs no second Jira key and no waiting. Removing one experiment must preserve the other candidate, its MR, and published history. Reuse a valid completed series; repeat it only when changed code/configuration or mixed candidates invalidate the comparison.

## Reset after rejection

A rejected candidate ends its causal branch. Return to the baseline attribution before editing an adjacent boundary. The next candidate must target a different measured cause or use new artifact evidence showing why the rejected implementation failed to isolate the original cause. Record its expected artifact delta before changing source.

After two consecutive rejected candidates, stop source changes and rebuild the ranked bottleneck dossier. Do not start another build until runtime or bundle evidence admits a new candidate.

## Measure baseline and candidate

Follow the remote build, deploy, identity, measurement, artifact, and crossover procedure in [runtime and captures](runtime.md).

- Use task or project requirements for sample counts and acceptance thresholds. Otherwise begin with a small diagnostic series, then collect balanced repeated samples sufficient to distinguish the proposed effect from run-to-run noise. Record the chosen materiality and guard thresholds before accepting a candidate.
- Compare median, p90, and run-to-run variation for the primary metric and guards. Preserve raw per-run values and sample counts; small-series p90 is descriptive and does not establish a stable tail estimate. Alternate or interleave baseline and candidate runs when practical to expose time-dependent backend or machine drift.
- Track LCP, FCP, TTFB, CLS, Fully Loaded, transfer size, request count, LCP element/resource timing, layout shifts, and long tasks when relevant.
- Report INP only for a journey that performs a qualifying interaction; navigation-only evidence cannot establish it.
- If the result is close to noise, extend both sides equally within the task's time/resource limits. A larger count alone does not repair mismatched conditions or prove significance.
- Never combine runs with different source, identity, auth, config, cache, viewport, browser, or server conditions.

Keep any unexplained delta between the two preprod stands unassigned. Use the required crossover and, when necessary, deploy the same revision to both stands as a remote control to determine whether the stand or deployment metadata changes requested chunks, HTML, or runtime metrics. Preserve earlier measurements as valid observations, but do not attribute their delta to the candidate until the control isolates causality.

Derive exact bundle, request-count, and static-budget claims from comparable WPT exports and, when needed, GitLab analyzer artifacts whose build inputs differ solely by the source change. Preprod timing alone does not isolate byte-level artifact changes because the builds embed deployment-specific public metadata and use live shared infrastructure.

Accept a timing candidate when the target metric improves beyond observed noise and meets the recorded materiality/guard criteria. Evaluate CLS by a meaningful absolute delta. A smaller bundle with an unchanged target timing does not prove that the reported latency problem is fixed. Reject a demonstrated regression; mark insufficient evidence inconclusive.

Keep invalid, partial, and stopped runs out of the comparison. Retain the downloaded WPT exports in task-owned protected storage, and treat HAR, screenshots, logs, cookies, and response data as sensitive.
