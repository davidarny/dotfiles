---
name: mostbet
description: Route Mostbet/Dats.Team work across Next.js SSR, legacy mostbet-spa, mostbet-core shared packages, deployment, and performance repositories when ownership or cross-project impact is unclear.
---

# Mostbet Workspace

This map covers `~/Developer/Dats.Team`, including the historical lowercase path and repository worktrees. Use it when repository ownership, the relevant specialized workflow, or cross-project impact needs clarification.

The workspace contains independent repositories connected through published packages, CI, deployed environments, telemetry schemas, and external APIs. `mostbet-core` is itself an npm workspace monorepo that owns shared `@core/*` packages; the workspace directory is not a single monorepo. Verify package relationships from producer and consumer manifests and lockfiles.

## Route the task

Choose the primary repository by the source or contract involved. Read [repository routing](references/repository-routing.md) when ownership or an entrypoint is unclear; consult only the relevant repository section. Read [relationship map](references/relationship-map.md) when a changed contract can affect another repository. Current source and configuration establish whether coordination is needed.

Distinguish `mostbet-next` (Next.js SSR) from `mostbet-spa` (legacy browser application). For SPA work, read its repository routing section and use its own Yarn, Webpack, routing, localization and test contracts. Similar features or URLs do not imply shared source or an automatic need to change both applications.

For `@core/*` implementation, dependency, packaging, or peer/engine changes, start in `mostbet-core` and read its section in the repository routing reference. Trace actual consumers before planning their updates. A request covering core and the application permits a coordinated library-and-consumer solution within that scope; a restrictive peer range is a compatibility constraint to investigate, not an automatic reason to stop at the consumer.

Follow applicable repository and subtree instructions, including their required guide and final-diff audits. The workspace's network and tool-routing rules still apply. A known repository and focused edit do not require reading the workspace catalog or relationship map.

Carry forward the requested outcome and existing authorization. Investigation ends with supported conclusions; implementation includes the relevant checks and fixing failures caused by the change. Apply the shared autonomy policy to complete scoped commits, pushes, MR updates, and verification without separate permission checkpoints. A stop or narrower scope overrides the earlier plan.

## Choose the specialized workflow

| Request | Skill |
|---|---|
| Page regression, runtime/resource timing, comparable measurements | `mostbet-page-performance` |
| Review a diff or handle reviewer findings | `mostbet-mr-review` |
| Rebase assigned open MRs | `mostbet-mr-maintenance` |
| Merge task branches into a release and validate it | `mostbet-release-update` |
| Prepare or create an MR | `dats-team-mr-create` |
| Draft, publish, or edit a Jira result comment | `dats-team-jira-comment` |
| Tester handoff | `dats-team-for-qa` with `dats-team-jira-comment` |
| Host, network path, service, or pipeline needs the infrastructure team | `dats-team-infra-task` |
| Finalize task-owned local resources | `dats-team-cleanup` |

For a small review correction, run the affected checks and required repository gates. Add e2e, repeated builds, or extended CI polling only for a concrete unresolved risk or an explicit request. A request for deep investigation requires finishing available evidence checks; it does not authorize unrelated implementation or publication.

## Environment and evidence

Use configured `mise` for Node/npm and verify the runtime used by scripts. Keep browser flags, authentication setup, and measurement transport changes in the synthetic repository when that is where the cause belongs.

For observability, use the available MCP first. After a verified MCP transport or capability failure, use the service's documented HTTP API with the current configured credentials and bounded queries. Keep credentials out of command arguments, logs, and artifacts. Reuse the diagnosed failure within the task and continue evidence gathering through the working API; a broken MCP does not by itself make the backend unavailable.

For cross-project conclusions, distinguish source/CI dependencies, deployment configuration, and telemetry/API contracts. Verify inferred edges before relying on them; report only the affected repositories and evidence needed for the decision. The [relationship map](references/relationship-map.md) defines the edge types and their source locations.

## Cross-project checks

- Shared `@core/*` changes: inspect `mostbet-core` package source, build configuration, exports/types/bin and peer/engine contracts, then the affected consumer manifest, lockfile and imports. Validate the built package as consumed; changing or publishing core alone does not update `mostbet-next`.
- Core test-tool or Node changes: check `@core/testing`, consumer Playwright/Node versions and CI browser images together. Keep package validation separate from publishing; follow the repository release workflow when a release is part of the requested outcome.
- Frontend CI, image, environment, ingress, API base, or OpenTelemetry changes: inspect `mostbet-next` and `deploy`.
- Legacy SPA build, base path, CDN or deployment changes: inspect `mostbet-spa` and the CI file referenced by its own `.gitlab-ci.yml`, rather than the SSR pipeline. Cross-application auth, cookie or route changes require checking both implementations only when a shared external contract is established.
- Deploy host or environment changes: inspect synthetic test targets.
- Sitespeed metric names, labels, page groups, test names, profiles, or units: inspect the producer plus both consumers (`performance-budgets` and `sitespeed-lcp-export`).
- Catchpoint WebPageTest API, matrix, device, location, network, header, or rate-limit changes: compare the independent implementations in `performance-synthetic-monitoring-tests` and `sitespeed-lcp-export`.
- Grafana datasource or Prometheus-compatible proxy changes: inspect both performance consumers; do not claim a shared package.
- Budget or reporting changes that only consume existing telemetry usually do not require a frontend source change, but their target mapping must still be verified.
