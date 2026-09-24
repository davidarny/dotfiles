# Review passes

Use these passes after the task dossier and project-rule checklist are ready. Their job is to generate falsifiable candidates; the [validation gate](validation-gate.md) decides what survives. Choose the probes that apply to the changed contracts, not a quota of findings or a checklist to run against every line.

## Independent perspectives

For a full MR review, apply [code-review](../../code-review/SKILL.md) with two separate perspectives:

- **Requirements and behavior:** check each relevant requirement and independent correctness invariant against reachable behavior. Trace data and state through the actual callers, error paths, and consumers. Inspect the tests that claim to protect those paths.
- **Standards and design:** audit documented rules and apply [thermo-nuclear-code-quality-review](../../thermo-nuclear-code-quality-review/SKILL.md) for a dedicated maintainability pass. Look for avoidable branching, indirection, duplicated state, weak type boundaries, misplaced responsibilities, and non-atomic updates. Seek a concrete restructuring that removes complexity while preserving required behavior. Distinguish a mandatory rule from a design judgment.

When native subagents are available and delegation is allowed, launch these perspectives in parallel with the same pinned diff, commits, task dossier, and applicable guides. Keep their candidate discovery independent. Give each a bounded scope and require the trigger, impact, source evidence, counterevidence, and a plausible fix for every candidate. If working solo, keep the perspectives as separate passes. A targeted follow-up uses only what the selected discussion needs.

The parent then revalidates candidates, merges duplicates, and orders surviving findings by consequence while preserving whether each is a behavior defect, rule violation, or design concern. Agent agreement, persuasive wording, accepted replies, and resolved threads are not correctness evidence.

### Mostbet overrides for imported skills

- Use the MR's resolved base/head and the Jira dossier. A valid MR request does not need another fixed-point question, an issue-tracker setup file, or another setup skill.
- Audit mandatory project rules even when tooling also enforces them. A passing tool does not waive a documented rule; verify a candidate rather than guessing that lint covers it.
- File length, smell labels, speculative future callers, and an imagined cleaner design are prompts to investigate. A structural finding needs a demonstrated maintenance cost, an applicable rule or concrete design problem, and a scoped alternative. Explain that cost honestly instead of inventing a runtime failure.
- Use Mostbet's validation, publication authority, and [comment format](comment-format.md). Do not publish the two agents' raw reports, force their headings or word limits, or turn review into implementation, approval, or a larger refactor.
- Apply [caveman-review](../../caveman-review/SKILL.md) only after validation, as a wording pass. Keep enough causal explanation to make the defect and fix understandable; terse output is not a discovery or evidence shortcut.

## Design principles and convention probes

Documentation lags practice, so a missing rule proves nothing about quality. Judge the diff against the design principles first, then against the conventions current usage establishes.

Run the principles as probes with named costs:

- **KISS.** Count the concepts a reader holds to follow one path: boolean parameters that fork behavior deep inside shared code, wrappers that add an implicit step, and state threaded through a call chain for one branch.
- **DRY.** Find one concept written twice, especially in adjacent lines and in two syntaxes. The cost is the pair drifting apart with nothing to catch it.
- **SRP.** Name each responsibility a function holds. A helper that performs an action, validates a response, asserts state, and cleans up has four, and its caller keeps none of them.
- **YAGNI.** Find the branch no supported input reaches, the parameter one caller passes, and the return field one consumer reads.

Measure the diff against the nearest existing equivalent before calling its structure a problem. Find the directory or module that already solves the same kind of task, then compare size, division of labour, and where the meaning lives. A helper directory larger than every comparable directory in the repository combined, feeding spec files that hold no assertions, is a measurement rather than an impression, and it converts a design opinion into evidence the author can check.

Repositories also carry conventions their documentation never states. Establish each one by counting current usage in comparable files, then judge the diff against that count. Report the count when the user questions a call.

Probe the conventions the diff actually touches:

- **Named types.** A module's public shape carries a name in a `*.types.ts` file. Flag an inline shape when it also duplicates a declaration, leaves an exported function's return type anonymous, or writes one concept in two syntaxes. Method shorthand and arrow properties differ under `strictFunctionTypes`, so two spellings of one type check by different rules.
- **Module constants.** Static objects and arrays follow the repository's dominant casing, and a static value built inside a render or a call is a rebuild the caller pays for.
- **Test selectors.** e2e assertions use the project's marker schema. A third-party class name, a computed style, or element geometry is a claim about implementation that breaks on an unrelated change.
- **Comment and message language.** Code comments, JSDoc, and assertion messages follow the repository's stated language.

A convention finding still passes the validation gate. State the count that establishes the convention, the concrete cost in this diff, and a fix the file can hold.

## Test sensitivity

For tests covering changed behavior, name a concrete regression that the test is meant to prevent. Ask: **if the implementation lost that behavior, would this test fail?** Follow the mock and assertion, not the test name.

Check whether the test observes the real boundary: a timeout test must exercise cancellation of a pending operation, not merely inject an error with a timeout-like message; a retry test must establish that the next attempt occurs after the relevant failure. Mocks should control external dependencies while retaining the contract being tested.

When source inspection cannot settle sensitivity, use a small temporary mutation or negative control in an isolated test setup. Compare the correct and deliberately broken variants without changing the submitted branch. Keep this proportional to the claim; do not add a mutation-testing dependency or demand tests for every line. A finding must identify the missing protection and the smallest regression test that supplies it.

Read global test setup, automatic mocks, fixtures, provider helpers, fake timers, and the configured environment before proposing test changes. A good test idea can still have an incompatible environment or assertions that pass for the wrong reason.

## Real boundary continuity

Trace one actual value through its producer, adapters, serialization, persistence, and final consumer or UI. Check that required fields, units, compound identity, context, and error meaning survive each changed boundary. A field collected upstream but dropped before the final consumer does not satisfy the requirement.

Where a new producer/consumer contract is tested only with independently hand-built fixtures, check whether either fixture can drift from the real output. Prefer a focused check that passes the real producer result to the consumer or serializer. Prove the specific field or behavior at risk instead of asking for generic integration coverage.

Read the actual error contract of wrappers: returning `{ data, error }` is different from throwing, and options may switch that behavior. Verify this before recommending retries, `allSettled`, or a new error boundary.

For flattening, merging, filtering, deduplication, and cache-key changes, identify what distinguishes two valid inputs. Check collisions, such as the same key in different domains, and the difference between raw and rendered counts. Do not infer that equal-looking values or functions have interchangeable identities.

## Interrupted work and repeated entry

For changed asynchronous or stateful flows, trace applicable transitions: start, success, error, cancellation, superseding request, unmount, and re-entry. Establish who owns the operation and who clears its loading state. An ignored stale response can be correct while leaving a flag stuck; an error can accidentally re-enable an observer and retrigger the same request forever.

Test the reachable sequence, including relevant ordering or batched delivery. Account for empty or filtered data when a sentinel, listener, or next request depends on visible content. A timing story alone is not proof; use source and a focused state/event check when order matters.

Keep resource cleanup tied to acquisition even when a sibling operation fails before aggregate results are available. For UI transitions, compare loading, ready, empty, and error states where affected, including geometry, semantics, and event ownership. A backdrop event bubbling through player handlers or a heading disappearing after hydration is part of the actual interaction contract.

## Other consumers and observable outcomes

When a candidate depends on effects outside the changed module, use [blast-radius](../../blast-radius/SKILL.md). Trace actual consumers, dependency versions, local patches, and lifecycle order, then test the key safety assumption with real code where feasible. Existing Mostbet tools and scope govern this pass; extra companion skills or agents are not required merely because the imported skill names them.

Group callers by their assumptions rather than applying the same fix everywhere. Compare payload shape, callbacks, default options, flags, and cleanup ownership. Check a neighboring proven solution, but verify its preconditions before reusing it.

For monitoring, fallback, retries, or durable history, start from the failure the task promises to handle and follow it to the observable signal or retained result. Check early exits and paths that never issue the request or event, not only success/error branches inside the receiver. Verify required data still exists after temporary artifacts expire. Keep unrelated gaps separate from the requested diff.

## Recheck after a correction

Validate the original trigger and the adjacent behavior changed by the proposed fix. Classify each subclaim independently: a comment may combine a valid defect, an incorrect explanation, and an unsafe fix. Preserve the valid part without importing the rest.

When consulting old discussions, compare comment time with MR versions. GitLab may reanchor a note to a later fixed revision, so its current position does not necessarily identify the originally reviewed code. Read the appropriate version before deciding that a historical claim was wrong or already addressed.
