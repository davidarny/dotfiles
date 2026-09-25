---
name: dats-team-for-qa
description: Prepare tester handoffs for Dats.Team Jira issues with concrete scenarios and expected results.
---

# Dats.Team For QA

Own tester-facing content, structure, and publication. Apply `$dats-team-jira-comment` for Jira context, `$humanizer`, `$jira-syntax`, validation, and cleanup. Keep QA guidance in Jira, never in a GitLab MR description or comment.

## Gather the QA contract

Read the Jira issue and relevant MR or change. Extract only what a tester needs:

- reachable MR link, when one exists;
- environment, route, role, feature flag, viewport, device, cache, or network preconditions that materially affect the scenario;
- the main user action and observable expected result;
- fallback, error, or regression cases directly affected by the change;
- a measurable acceptance threshold only when the task requires one.

The tester runs every scenario before release, on a preprod stand deployed from the MR branch. Write each check as a browser-observable action and outcome: what the page shows, how the UI behaves, what DevTools exposes. Server-side effects stay with the developer's own verification. Describe source-traced regression risk in the same browser terms. When the change has no browser-visible effect, open with one sentence saying so, and write the scenario as a regression comparison against a preprod stand running master.

Keep implementation details, full benchmark output, and generic neighboring checks out of the handoff. Do not invent setup, deployment, pipeline status, environment readiness, or expected results; report a blocker when evidence cannot define a meaningful result.

QA deploys one branch at a time to a stand and tests branches separately. Give each branch its own handoff, and name the exact branch to deploy next to its MR link; a section never asks QA to deploy several branches together. Do not replace a missing account, flag, or balance prerequisite with an assumed result. Keep an engineering investigation report as a separate Jira comment through `$dats-team-jira-comment`.

## Structure

Start with `h3. For QA`; put the branch to deploy and the reachable MR link immediately below it. With several branches, title each section `h3. For QA: <branch>`. For a narrow change, use a short sentence or compact bullets. For a multi-step change, add only sections that carry information:

- `*Предусловия*` for required setup;
- `*Основной сценарий*` with numbered user actions;
- `*Ожидаемый результат*` with observable outcomes;
- `*Fallback*` for a verified fallback path;
- `*Регрессия*` for source-traced neighboring behavior.

Omit empty headings. Preserve exact routes, flags, response codes, and commands when the tester needs them to reproduce or judge the scenario. Apply [unslop](../unslop/SKILL.md) for reader-first wording and [show-me](../show-me/SKILL.md) when a compact scenario/outcome comparison or sequence helps. Render visuals in Jira-supported markup and choose the form for the actual task. Keep the handoff focused on what the tester should do and observe rather than an inventory of the author's unperformed checks. Do not prepend `h3. TL;DR`.

Publish For QA in the issue description rather than a comment: replace the existing For QA sections, or append them at the end of the description when absent, and keep the rest byte-identical. A request to write or publish For QA authorizes that description edit and no other field. When only a draft is requested, return the body without a Jira write.
