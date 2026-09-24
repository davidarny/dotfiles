# Finding Validation Gate

Use this gate for every candidate finding before drafting or publishing a review comment. The dossier and freshness checks follow the selected mode in `SKILL.md`: a full review covers the complete relevant dossier; a targeted follow-up covers the selected claims and their necessary context. Do not expand a targeted request into a full review.

## Mandatory evidence record

Record:

| Field | Required evidence |
|---|---|
| Diff location | Current path and changed line |
| Claim | One falsifiable statement |
| Requirement source | Jira field/comment, attachment, linked artifact, or independent correctness invariant |
| Artifact evidence | Inspected dossier artifacts that support or constrain the claim |
| Causality | The reviewed diff introduces or exposes the behavior |
| Trigger | Concrete input, state, timing, flag, environment, or call sequence |
| Reachability | Actual caller/configuration path reaches the trigger |
| Effect | Observable incorrect behavior or maintainability contract violation |
| Impact | Who or what is affected and how |
| Support | Source, test, compiler, runtime, config, or official documentation |
| Counterevidence | Guards, invariants, types, tests, framework behavior, or alternate paths checked |
| Verification | Smallest decisive check and its result |
| Fix | Minimal credible correction |
| Verdict | `valid`, `rejected`, or `inconclusive` |

Do not publish a candidate with a blank field except when `Verification` is unnecessary because current source proves both the claim and its refutation search.

## Evidence hierarchy

Prefer stronger evidence:

1. deterministic reproduction or focused failing test;
2. compiler/typecheck/linter output that directly proves the claim;
3. exact current source plus a complete caller/configuration path;
4. current official framework or platform documentation;
5. inference.

Validate the diagnosis, supporting subclaims, and proposed fix separately. A sound defect does not prove that its example patch works in this repository's test environment or preserves other callers. A resolved or accepted discussion records its disposition, not independent proof of correctness.

Inference alone is not enough for publication.

Jira and linked artifacts prove intended behavior, constraints, and reported symptoms. They do not by themselves prove that the implementation produces the alleged runtime effect; connect them to current source or executable evidence.

## Mandatory gates

### 1. Task and artifact alignment

Confirm that the candidate is evaluated against the dossier required by the selected review mode:

- full Jira description and acceptance criteria;
- all Jira comments in chronological order;
- attachments, remote links, parent/epic, subtasks, and related issues;
- MR description, discussions, prior diff versions, screenshots, CI/test reports, and linked documents;
- relevant repository specifications, tests, fixtures, configuration, and feature flags.

Trace the candidate to an explicit requirement or an independent correctness invariant. Check whether a later authoritative artifact supersedes earlier wording. If sources conflict and ownership cannot be resolved, classify the candidate as `inconclusive`.

Reject findings based on partial Jira context or an uninspected relevant artifact.

### 2. Diff causality

Confirm that the finding concerns behavior introduced, changed, or newly exposed by the reviewed diff.

Compare with the actual base implementation and configuration. A hypothetical optimized baseline or an unrelated future rollout does not establish a regression in the current MR.

Reject:

- unrelated pre-existing defects;
- broad redesign opportunities;
- cleanup outside the changed contract;
- problems already fixed in the current head.

### 3. Reachability

Name the exact path that reaches the defect.

Check:

- callers and call order;
- feature-flag combinations;
- authenticated/anonymous and server/client branches;
- empty, partial, error, timeout, and unmount states;
- production configuration and defaults;
- mutual exclusion or invariants that make the state impossible.

Reject the candidate if its trigger is unreachable under supported behavior.

### 4. Semantic correctness

Verify the language, type-system, browser, React/Next.js, and library semantics the claim depends on.

Do not rely on intuition about:

- closure narrowing and callback execution;
- batching or ordering of observer/events;
- Suspense, streaming, hydration, or client/server execution;
- cleanup timing;
- promise rejection and cancellation;
- cache keys and invalidation;
- coercion, nullability, or default values.

Use a focused typecheck, test, reproduction, or official documentation when semantics are not obvious from current source.

### 5. Specific impact

Connect cause to an observable consequence:

- wrong UI or state;
- crash, stuck loading, hydration mismatch, or layout shift;
- stale/incorrect data;
- duplicated request or side effect;
- security or operational failure;
- a misleading current contract that causes callers to use the API incorrectly.

Avoid generic claims such as “может сломаться”, “небезопасно”, or “плохо масштабируется”.

Naming and maintainability findings are valid only when the current name contradicts actual scope or behavior, not merely because another name is preferred.

### 6. Refutation pass

Try to disprove the candidate before accepting it.

Ask:

- Is there a guard before the actual use?
- Does a caller guarantee the value or state?
- Are branches mutually exclusive?
- Does a fallback, cleanup, or error boundary already handle it?
- Does the type system narrow here, especially across an async callback or closure?
- Does current framework behavior differ from the assumed model?
- Does an existing test cover the exact state rather than a nearby one?
- Is the alleged effect visible, or does CSS/configuration preserve the contract?
- Is the suggested fix already harmful in an empty/error state?
- Does any Jira comment, attachment, screenshot, design, test report, or prior discussion contradict the interpretation?

Clearing a candidate needs the same evidence as keeping one. Before writing off a declaration, a literal, or a table as harmless, read every consumer of the values it declares: a field that looks like a display label often also drives a branch, a key, or a lookup. Judge it on those uses, not on how it reads at the declaration.

Write the strongest counterargument. A candidate is valid only if the evidence defeats that counterargument.

### 7. Minimal-fix plausibility

Identify a correction that addresses the proven cause without broad redesign.

The fix need not be the only solution, but it must:

- preserve relevant existing behavior;
- handle the demonstrated trigger;
- fit current repository patterns;
- avoid a known regression in adjacent branches.

If no credible fix or clarifying question exists, keep investigating or classify the candidate as inconclusive.

### 8. Freshness

Immediately before publication:

- refresh MR head SHA and diff refs;
- refresh Jira `updated` state, comments, attachments, and MR discussions;
- re-read the cited source;
- ensure the line is still changed and anchorable;
- check that another discussion or push has not already addressed it.

Any head change invalidates previous line anchors and requires revalidation.

## Verdict rules

### Valid

Use only when:

- causality, reachability, semantics, and impact are proven;
- the complete task dossier supports the interpretation;
- the refutation pass found no defeating counterexample;
- the comment can state the defect without hedging;
- the suggested fix is plausible and scoped.

### Rejected

Use when any evidence disproves the claim. Keep it private.

Example:

> Candidate: `observer?.disconnect()` is redundant because a null guard appears below callback creation.
>
> Counterevidence: the callback closes over the nullable outer variable before the guard; TypeScript does not preserve that later narrowing inside the closure, and `observer.disconnect()` produces `TS18047`.
>
> Verdict: `rejected`. Do not publish the comment.

### Inconclusive

Use when the behavior is plausible but cannot be proven from reachable source, tests, configuration, or current documentation.

Do not publish an inconclusive statement as a question merely to transfer investigation to the author. Ask a question only when the missing fact is genuinely owned by the author and the user explicitly wants question-style review feedback.

## Positive validation examples

### Batched observer entries

A callback reads only the first entry. Before commenting:

1. confirm the observer can deliver multiple relevant entries;
2. confirm their order and which entry represents current state;
3. construct the exact batch, such as `[enter, leave]`;
4. prove the current code schedules work from stale state;
5. run a focused regression test.

Only then comment on the stale-entry defect.

### Feature-flag fallback

A fallback is conditional. Before commenting:

1. enumerate supported flag combinations;
2. trace which block renders in each combination;
3. compare fallback and resolved layout for row count and empty data;
4. confirm a `null` fallback reintroduces the reviewed layout change;
5. verify the proposed fallback preserves branded and single-row variants.

Only then comment on the uncovered flag branch.
