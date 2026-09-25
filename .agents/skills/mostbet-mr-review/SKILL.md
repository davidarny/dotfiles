---
name: mostbet-mr-review
description: Review Mostbet MRs or handle selected reviewer discussions against Jira requirements and current source.
---

# Mostbet MR Review

Perform evidence-first reviews. Keep candidate findings private, disprove them before publication, and finish at the user's requested verified outcome.

Use the `mostbet` skill for repository routing and cross-project impact. Follow `glab-mr` before any GitLab write. These references provide procedures; the user's requested scope and existing authorization govern actions.

Load [the comment format](references/comment-format.md) before drafting the first comment, not after writing one. Load the other `references/` files at the step that names them. When the requested outcome depends on an imported skill's own rules, read that skill's file rather than working from its description.

## Choose the review mode

- **Full MR review:** build the complete Jira and artifact dossier before discovering findings.
- **Targeted discussion follow-up:** inspect the requested reviewer or discussion scope at the current MR head, with only the requirements, history, source, and artifacts needed to judge those claims. Keep unrelated findings outside the ledger and action scope. Read every requested discussion and reply in that scope, including fixed, superseded, and rejected claims.
- **Comment rewrite:** the user asks to restate their own existing comments in this workflow's format. Replace each note's body in place with `PUT /projects/:id/merge_requests/:iid/notes/:note_id`, keeping one note per thread. A reply added under the original leaves the old wording standing and is the wrong shape for this request. Validate each restated claim like any other candidate: a comment the user wrote is a claim to prove, not evidence.

For either mode, classify each claim independently. A request to challenge comments calls for counterevidence. A review-only request produces a report; a request to fix findings includes scoped implementation, checks, commit, and push under the shared autonomy policy. Publish replies or resolve discussions when handling those discussions is part of the requested outcome. Resolve only after the concern is verified as addressed or explicitly withdrawn.

## Review contract

- Review the requested diff, not the whole codebase.
- Treat applicable repository rules as mandatory review gates. Map changed files to their instructions and audit the final diff; passing tooling or an existing violation does not waive a rule. Validate a diff-introduced rule violation as a candidate.
- Judge design quality on its own evidence. KISS, DRY, SRP, and YAGNI hold whether or not `code-style/` names them, and an undocumented convention still binds once current usage establishes it. A finding of this kind carries the same bar as any other: the concrete cost in this diff and a fix the file can hold.
- Treat the task, accessible linked artifacts, current source, tests, manifests, and framework contracts as evidence. Keep the dossier and candidate ledger private.
- Publish only `valid` new findings. In requested discussion replies, explain rejected claims with counterevidence and inconclusive claims with the missing evidence.
- Write comments in Russian; keep paths, identifiers, code, and commands in English.
- Audit a scope constraint the user states for the MR against every file outside its primary area, and give the verdict in the report even when the diff honors it. A constraint such as "tests only, selectors on components are allowed" names the check the user wants run.
- A review-only request produces a report or drafts. Modify the branch or publish comments only within established authorization.

## Delegate at the reviewer's level

- Delegate a full MR review or an independent judgment pass only to a subagent with the same model and reasoning effort as the parent reviewer, or a verified comparable level. Set both explicitly when the tool permits; do not assume inherited defaults match. If a comparable subagent is unavailable, perform the pass in the parent.
- Give lower-capability subagents only bounded mechanical work with checkable output, such as listing changed files, extracting issue fields, or collecting CI results. Verify their output before using it. Keep requirement interpretation, finding classification, discussion resolution, approval, and review publication with the parent or a comparable reviewer.

## 1. Pin the review target

1. Resolve the MR IID, project, source and target branches, base SHA, and head SHA. Fetch current refs and record the immutable comparison:

   ```bash
   git diff <merge-base>...<head-sha>
   git log <merge-base>..<head-sha> --oneline
   ```

2. Use an isolated clean worktree when the checkout is dirty or on another branch. Preserve user changes.
3. From the repository root through each changed file's directory, read the applicable instruction and referenced guides using the current agent's discovery precedence; do not combine mutually exclusive fallback files. Create the project-rule checklist before judging implementation correctness.
4. If a required guide cannot be read or an applicable conflict cannot be resolved by precedence and task context, stop only the affected review area and report the exact issue. If the head SHA changes, discard stale anchors and revalidate the checklist and every surviving finding.

## 2. Build the dossier before finding discovery

Read [the task context and artifact protocol](references/task-context.md) before implementation review. Use the Atlassian Jira MCP first.

**Full review:** read the complete task, all comments, relationships, and every accessible task- or MR-linked artifact that can affect the requested diff. Complete the requirement matrix and artifact ledger before discovery; record exact failures, contradictions, superseded requirements, scope, and non-goals.

**Targeted discussion follow-up:** read only the selected discussions and replies at the current MR head, plus the requirements, history, source, callers, and artifacts needed to judge those claims. Keep unrelated findings outside the ledger and action scope; do not expand this into a new full-MR review. Record any material unavailable evidence and stop only the affected claim when it is necessary to decide correctness.

For either mode, build a compact map of intended behavior, changed contracts, relevant callers/callees, flags/configuration, tests, applicable state boundaries, and cross-project edges from `mostbet`. Use CodeGraph for exact symbols and paths when its index belongs to the current worktree; use FFF for file and literal search. Do not infer behavior from the diff alone when unchanged source controls the claim.

## 3. Discover and validate candidates privately

Before discovering findings in a **full MR review**, read [the review passes](references/review-passes.md). Apply [code-review](../code-review/SKILL.md) for independent requirements/behavior and standards/design perspectives, with [thermo-nuclear-code-quality-review](../thermo-nuclear-code-quality-review/SKILL.md) inside the design pass. Test the promised behavior, not just the presence of implementation or tests: trace real producer-to-consumer contracts and ask which concrete regression each relevant test would detect. The reference defines Mostbet overrides, bounded parallel work, and the conditional use of [blast-radius](../blast-radius/SKILL.md).

For **targeted discussion follow-up**, use only the relevant pass to judge the selected claim. Keep the same validation bar without opening unrelated review work.

**Full review:** inspect every changed hunk with relevant context and record each candidate's current path/diff line, requirement or invariant, falsifiable claim, reachable trigger and source-to-effect path, observable impact, supporting/counterevidence, smallest decisive check, and plausible minimal fix. Prioritize broken requirements, reachable runtime/SSR/hydration/async/state/cache/error defects, flag and empty/partial-data regressions, security/data-loss/operational risks, and misleading contracts whose scope contradicts behavior.

**Targeted discussion follow-up:** classify only the requested discussions. Trace each claim to its current diff lines, relevant source and callers, and the selected task/artifact evidence; include a candidate only when needed to answer that claim. Do not discover or publish unrelated findings.

A focus area the user names in a full review sets where to look first, not where to stop. Sweep every declaration in the files it names, including the ones the named concern does not mention: type shapes, data tables, module state, and the consumers of each. The symbol the user pointed at is the entry point to those files, and a second pass over them after the user prompts is a pass that belonged in the first.

Read [the validation gate](references/validation-gate.md) before classifying candidates. For each one, prosecute the strongest concrete case and then try to refute it with guards, caller preconditions, types, framework semantics, configuration, flags, tests, and reachable-state analysis. Run the smallest decisive focused check when source evidence is insufficient. Do not post formatting preferences, broad refactors, hypothetical future problems, or unrelated pre-existing defects.

Classify each candidate as:

- `valid` — causality, reachability, semantics, impact, and a scoped fix are proven;
- `rejected` — evidence or a counterexample disproves it;
- `inconclusive` — the claim or impact cannot be established.

Missing tests justify a finding only when a concrete changed behavior has a demonstrated blind spot: identify the regression existing checks would miss and the smallest check that detects it. A green test count or a test named after the behavior is not proof that it exercises that behavior.

Only `valid` candidates become new findings. Requested replies still cover rejected and inconclusive discussions without presenting them as defects.

## 4. Draft and audit the result

After validating findings, apply [caveman-review](../caveman-review/SKILL.md) as a wording pass. This workflow's finding criteria, Russian comment format, and authorization rules override the imported skill's defaults. Keep the location, reachable trigger, causal evidence, consequence, and scoped fix; one-line output is optional. Use a short paragraph or example whenever compression would hide the reasoning. Preserve meaningful uncertainty and investigate it instead of converting an unverified suspicion into a question for the author. Ask only when the missing fact belongs to the author and the requested review scope calls for it. Function length alone proves no defect, and a retry recommendation needs the API's retry and idempotency contract. Compression neither replaces nor prohibits source inspection, tests, or linters required to validate a finding, and grants no fix, approval, or publication authority.

For drafts or publication, read [the comment format](references/comment-format.md) and apply [unslop](../unslop/SKILL.md) for reader-first reporting. Use [show-me](../show-me/SKILL.md) when a compact comparison, flow, or check/result view makes the outcome clearer. Its form follows the information and destination, not a fixed review template. The finding structure applies to new defects; discussion replies use concise Russian evidence and the applicable answer, without forcing `Фикс:` for a rejected or inconclusive claim. Anchor each new finding to the narrowest current changed line, state one defect and its consequence, give the causal evidence, and end with `Фикс:`. Keep the published comment self-contained and free of placement, fallback, or tooling commentary.

**Full review:** after discovery, audit the complete batch: re-read every cited line from the current head; refresh Jira and all in-scope MR discussions; verify requirement trace, reachability, specific impact, counterevidence, duplicates, addressed threads, and fix plausibility; and rerun focused checks affected by the final interpretation.

**Targeted discussion follow-up:** refresh only the selected discussions, their current head lines, and material requirements/artifacts; verify each requested claim, reply, fix, and resolution independently. Rerun checks affected by that claim. If a mandatory check fails, keep the affected finding or action private.

## 5. Publish only with established authorization

Publish through GitLab only when the user explicitly requests publication or the conversation already establishes that authorization. Use `glab` for `gitlab.dats.tech`, fetch fresh MR versions and SHAs immediately before posting, and verify the returned position for each new inline finding or the exact discussion ID for an existing-thread reply. Use the `glab-mr` JSON inline flow when native anchoring is unavailable; consult [glab-api](../glab-api/SKILL.md) only when the required REST operation or pagination is not covered there. A general resolvable discussion is the last placement fallback, with the limitation reported only to the user. Publish the complete validated batch for a full review; for a targeted follow-up, publish only the authorized response or fix for the selected discussions. In a comment rewrite, send each new body with `PUT` to that note's id and confirm the returned body is the one you wrote. Leave new threads unresolved, and revalidate if the head changes between audit and posting.

A published comment stays yours to correct. When later evidence shows a claim in it was overstated, wrong, or weaker than its `Фикс:` implies, rewrite that note with the corrected text and say so in the completion report.

## 6. Report completion

Complete the requested result rather than stopping at an intermediate checkpoint: a full review ends with a verified report or authorized publication; a targeted follow-up covers every requested discussion and only its authorized action; a re-review uses the current head.

Lead with the review outcome, then the findings or observed behavior that support it. When no candidate survives, say plainly that there are no findings in the reviewed changes and summarize useful completed checks. Keep revision SHAs, candidate counts, access logs, and the full evidence ledger in working records. Use descriptive links for findings and evidence that the reader needs. Apply the global communication rules instead of appending a checklist of unperformed work or unaffected systems. Reader-friendly reporting does not reduce the investigation, freshness, or validation requirements above.
