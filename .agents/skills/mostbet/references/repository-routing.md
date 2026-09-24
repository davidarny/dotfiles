# Repository Routing and Project Catalog

Workspace root: `~/Developer/Dats.Team`; use the actual checkout path, including an existing historical lowercase path.

This document records stable ownership and navigation. Verify changing details—versions, branches, hosts, CI refs, image names, datasource identifiers, thresholds, and environment values—from current repository files.

## Direct children

| Path | Type | Role |
|---|---|---|
| `.codegraph/` | local tooling metadata | Workspace-level CodeGraph data. It is not a product repository and must not be committed. Each Git repository also has its own `.codegraph/` index. |
| `mostbet-next/` | Git repository | Customer-facing Mostbet web application. |
| `mostbet-spa/` | Git repository | Legacy browser-rendered Mostbet application with its own build and deployment pipeline. |
| `mostbet-core/` | Git repository, npm workspace monorepo | Shared `@core/*` libraries, test utilities, assets, and developer tooling. |
| `deploy/` | Git repository | Central GitOps, build, and Kubernetes deployment configuration. |
| `performance-synthetic-monitoring-tests/` | Git repository | Sitespeed and Catchpoint synthetic test production and fleet management. |
| `performance-budgets/` | Git repository | Performance budget collection, reporting, Grafana dashboards, and alerts. |
| `sitespeed-lcp-export/` | Git repository | Sitespeed LCP and Catchpoint WPT export to Google Sheets. |

The listed Git repositories are independent. `mostbet-core` owns its own npm workspaces and publishes packages consumed by other repositories. A published dependency does not establish a local workspace link or automatic synchronization; inspect current manifests and lockfiles for each relationship.

## Routing summary

| Primary repository | Owns | Choose it for |
|---|---|---|
| `mostbet-next` | Next.js frontend source and application tests | UI, routing, SSR/client logic, API clients, auth/profile flows, localization, frontend instrumentation |
| `mostbet-spa` | Legacy React frontend, Webpack configuration and application tests | SPA features, browser routing, legacy auth/state/localization, base-path and CDN builds |
| `mostbet-core` | Shared package source, build/test tooling, exports and release contracts | `@core/*` dependencies, UI library, icons/tokens, markers, test fixtures/CLI, shared lint configuration |
| `deploy` | GitLab CI, image build, Helm/Kubernetes, ingress, Vault integration, runtime environment | CI/CD, images, deployment jobs, environments, resources, probes, metrics scrape, ingress, injected API/OTEL config |
| `performance-synthetic-monitoring-tests` | Sitespeed/WPT producer and measurement fleet | Synthetic scenarios, URL lists, metrics production, browser/network profiles, custom plugins, Ansible VM deployment |
| `performance-budgets` | Budget calculation and Grafana resources | Thresholds, PromQL, RUM/synthetic comparison, reports, dashboards, alert rules |
| `sitespeed-lcp-export` | Monthly performance exports | Google Sheets layout/writes, Sitespeed LCP export, Catchpoint submit/collect/aggregate flows |

If a task spans domains, choose the primary repository by the file or contract that must change. Treat downstream consumers as secondary until evidence shows they also require edits.

---

## `mostbet-next`

### Purpose

Large multilingual customer-facing application covering home, sportsbook/esports, casino/live casino, poker, authentication, profile, payments, promotions, bonuses, loyalty, missions, VIP, and referrals.

### Stack

- TypeScript and Next.js App Router
- React, Redux Toolkit, SWR, `next-intl`
- Sentry, OpenTelemetry, Prometheus metrics, GrowthBook
- npm and Node.js
- Jest/Testing Library, Playwright, Storybook, MSW/WireMock
- ESLint, Prettier, Stylelint, Husky

Use `package.json` and engine fields as the authority for current versions.

### Important paths

- `src/app/layout.tsx` — global document layout.
- `src/app/[locale]/layout.tsx` — localized application composition and providers.
- `src/app/[locale]/page.tsx` — localized home entrypoint.
- `src/proxy.ts` — locale/session/realm/request routing layer.
- `src/instrumentation.ts` — OpenTelemetry, metrics, Sentry, and cache initialization.
- `src/app/metrics/route.ts` — application metrics endpoint.
- `src/api/` — fetcher, endpoints, server actions, and API contracts owned by the frontend.
- `src/ui/` — reusable UI, page composition, providers, and styles.
- `src/shared/` — routing, localization, hooks, utilities, constants, and auth helpers.
- `src/redux/` — store, slices, middleware, and providers.
- `e2e/` — Playwright tests and API mocks.
- `code-style/` — architecture, installation, run, and deployment documentation.
- `Dockerfile.web`, `Dockerfile.storybook` — source-owned image definitions used by deployment CI.
- `.gitlab-ci.yml` — delegates the real pipeline to `deploy`.
- `eslint-custom-rules/` — local nested ESLint plugin package, not a separate product repository.

### Typical validation

```bash
npm install
npm run type:check
npm run lint
npm run lint:styles:check
npm run test
npm run test:e2e
npm run build
```

Run only the checks relevant to the change. First-time local setup may require locale assets described in `code-style/5-installation.md`.

### Routing cautions

- Frontend source owns API path usage, but backend implementations are outside this workspace.
- Deployment environment values, images, ingress, and production runtime settings are owned by `deploy`.
- Documentation may lag the package manifest; verify current versions and commands.

---

## `mostbet-spa`

### Purpose and stack

Legacy customer-facing React application, independent of the Next.js SSR application. It has mixed JavaScript/TypeScript, React Router with connected-react-router/history, Redux, Axios, i18next, Sass, and custom CRA-derived Webpack/Babel scripts. Jest and Testing Library provide application tests. Read current manifests for library versions and browser support; SSR/core upgrade targets are not defaults for SPA.

### Important paths

- `src/index.js`, `src/bootstrap.js` — asynchronous bootstrap, React root, providers and browser initialization.
- `src/components/App/`, `src/pages/`, `src/landings/` — application composition and UI.
- `src/router/routes.js` — browser route definitions.
- `src/store/`, `src/initializeReduxStore.ts`, `src/logic/` — state initialization and application logic.
- `src/api/`, `src/axiosConfig.js` — API access and Axios configuration.
- `src/i18n.js` — i18next setup, separate from SSR's next-intl.
- `src/setupTests.ts`, `jest.config.json`, `config/jest/` — test setup and configuration.
- `config/webpack.config.js`, `config/webpack-config/`, `config/paths.js`, `config/env.js` — bundling, asset paths and build-time environment.
- `scripts/start.js`, `scripts/build.js`, `scripts/build_local.js`, `scripts/setHomePage.js` — development and build entrypoints.
- `package.json`, `yarn.lock` — commands, engines, resolutions and Yarn Classic dependency graph.
- `.gitlab-ci.yml` — CI include for `deploy/mostbet/mostbet-front/.gitlab-ci.yml`.
- `Makefile`, `deploy/`, `ansible-runner/` — legacy delivery tooling; inspect callers before executing.

### Working and validation boundaries

Use the repository's Yarn workflow and preserve `yarn.lock`; do not introduce an npm lockfile or apply core npm-workspace commands. Verify the actual Node/Yarn selected by the environment against current engines and CI. Old README setup commands and legacy Dockerfiles can describe different runtimes; establish which files the active pipeline uses.

Derive checks from `package.json`: `lint`, `type-check`, `test`, and the build variant relevant to the task. The test wrapper may watch by default; choose a bounded mode supported by the current script. Preserve the configured browser baseline and polyfills when updating dependencies. Inspect direct and transitive dependencies rather than assuming similarly named SSR libraries use compatible majors.

Build variants set `REACT_APP_INNER_ROUTE` and `REACT_APP_DESTINATION` for root, `/spa/`, development prefixes and CDN output. `scripts/setHomePage.js` writes the destination into tracked `package.json` before building. Record the starting value, use an isolated task checkout and review any resulting manifest diff; do not ship a build-induced homepage change unintentionally. Check deep-link reloads, history navigation, lazy chunks and asset URLs for the selected base path.

`make dev` is documented as a deployment to selected servers, not a local dev-server command. Deployment/Ansible commands require the requested delivery scope and a known target; use `yarn start` for local development. The presence of service-worker helpers does not prove registration is enabled; inspect the bootstrap and actual registration before reasoning about caching.

### Cross-project boundary

Resolve SPA CI from its own include, not `deploy/mostbet-next`. Source similarities, a shared API host or the same user-facing feature do not establish a package dependency on `mostbet-next` or `mostbet-core`. Verify manifests/imports and external auth/cookie/API contracts before adding work in another repository. Use the general Dats.Team sibling-worktree convention when isolation is needed; `mostbet-worktrees` is specific to `mostbet-next`.

---

## `mostbet-core`

### Purpose and ownership

Owns shared packages under `packages/*`. Read root and package instructions before work; root `package.json`, `lerna.json`, `nx.json` and package manifests establish current workspace, task and release behavior.

- `packages/ui/` — shared React components, styles, Storybook and visual tests.
- `packages/icons/` — SVG generation, React icon modules and published asset paths.
- `packages/tokens/` — design-token import and CSS theme generation.
- `packages/marker-tree/` — marker construction and consumer test selectors.
- `packages/testing/` — Playwright fixtures, mock record/replay and TestRail/mock-management CLI.
- `packages/scripts/` — developer commands for installing and linking shared packages.
- `packages/oxlint-config/`, `packages/oxlint-plugin/` — shared lint/format configuration and custom rules.

### Dependency and release work

Use npm workspace commands verified in the current manifests. Root Lerna/Nx commands fan out across packages; select affected workspaces first, broadening checks when shared tooling or emitted artifacts warrant it. Check the actual Node/npm selected by `mise` against both core and consumer engines before installation.

For a dependency change, distinguish package runtime dependencies, build-only tools and peer requirements imposed on consumers. Compare release tags and published artifacts when a version bump has little source change. Check generated JS/CSS, declarations, `exports`, `types`, `bin` filenames and ESM/CJS loading. Source typecheck alone does not prove that the packaged artifact works in a consumer.

Derive build, type-check, lint, unit, coverage and visual-test commands from the affected package scripts. Inspect lifecycle scripts before running them: clean/build/generator commands may remove or overwrite generated assets, and token-loading commands may call external services. Use a disposable task checkout for generated-output comparisons and respect the workspace deletion rules.

When the task includes a consumer update, validate a built or prerelease package in that consumer before the stable release/update sequence defined by the repository. Confirm release authorization from the task; testing does not require publishing. Keep unrelated core packages and consumer applications outside the implementation scope.

### Consumer boundary

`mostbet-next` has consumed `@core/marker-tree` and `@core/testing`; confirm its current manifest rather than assuming every core package is installed. Changes in core UI/icons/tokens affect only proven consumers after they adopt the new artifacts. `@sb/react-lib` belongs to the separate sportsbook library, not `mostbet-core`; locate its producer independently.

---

## `deploy`

### Purpose

Central GitOps repository for GitLab CI, image build/deploy, Helm values, Kubernetes services, ingress, probes, resources, metrics, alerts, and Vault-backed configuration.

The common hierarchy is project/application/environment/cluster/namespace/postfix. Underscore-prefixed directories contain shared templates and scripts.

### Stack

- GitLab CI YAML
- Helm/Kubernetes values and templates
- Python validation and migration utilities
- Vault, shell, `curl`, and `jq`
- External shared CI and chart templates

There is no root application package manager or conventional build.

### Important paths

- `mostbet-next/.gitlab-ci.yml` — build/deploy contract for frontend web and Storybook images.
- `mostbet-next/web/` — web service template and environment values.
- `mostbet-next/storybook/` — Storybook deployment values.
- `_template/` — baseline for new service deployment definitions.
- `_common/` — shared deployment fragments.
- `_scripts/` — operational scripts; inspect before running because some mutate files or Vault.
- `cicd-check.py` — repository validation script.
- `.gitlab-ci.yml` — root operational pipeline.

### Typical validation

```bash
python3 cicd-check.py
```

Treat secret migration/export commands as state-changing. Never run them as validation.

### Routing cautions

- The repository contains many product namespaces, but for this skill the primary cross-project owner is `deploy/mostbet-next`.
- Shared CI refs and environment values are volatile; read current YAML.
- A frontend deployment change may require source Dockerfile or runtime environment verification in `mostbet-next`.

---

## `performance-synthetic-monitoring-tests`

### Purpose

Distributed synthetic performance testing for desktop/mobile, first/warm view, anonymous/authenticated, production/preproduction, and Catchpoint WebPageTest matrices. Publishes metrics/artifacts and manages measurement servers through Ansible.

### Stack

- Sitespeed.io and Browsertime/Chrome
- Bash orchestration
- JavaScript ESM custom plugins
- Docker and JSON configuration
- Ansible inventories/playbooks
- GitLab CI
- Optional local Grafana, InfluxDB, and object storage services

There is no root Node package; plugin subdirectories have independent npm manifests.

### Important paths

- `loop.sh` — long-running suite scheduler.
- `run.sh` — native/container suite execution.
- `config/` — reusable browser/device/cache/auth profiles and metric plugin settings.
- `tests/` — production, preproduction, local, and script-oriented URL/journey suites.
- `machines.csv` — fleet dimensions and roles.
- `deploy/` — Ansible inventories, templates, tasks, and playbooks.
- `.gitlab-ci.yml` — inventory/config validation and fleet deployment jobs.
- `scripts/webpagetest.sh` — independent interactive Catchpoint WPT submission flow.
- `plugins/lateststorer/` — latest artifact/summary publication.
- `plugins/s3ng/` — object-storage upload.
- `plugins/fileRemover/` — result-file filtering/removal.
- `plugins/excludeMetrics/` — metric filtering before publication.

### Typical validation

```bash
ANSIBLE_CONFIG=deploy/ansible.cfg ansible-inventory -i deploy/inventories --graph
ANSIBLE_CONFIG=deploy/ansible.cfg ansible-playbook -i deploy/inventories deploy/playbooks/* --syntax-check
```

Validate changed JSON configuration separately. Full suite execution is operational and potentially long-running; do not start it unless requested.

### Routing cautions

- Changes to metric names, labels, groups, test names, profiles, units, or aggregation can break both performance consumers.
- Preproduction and production targets depend on deployed frontend environments and ingress configuration.
- Catchpoint WPT logic overlaps with `sitespeed-lcp-export`; it is duplicated, not imported.

---

## `performance-budgets`

### Purpose

Collects synthetic metrics through Grafana/Prometheus-compatible APIs and RUM Web Vitals through Superset, calculates UX/content/network/API budgets, writes Markdown/JSON reports, and builds/deploys Grafana dashboards and alert rules.

### Stack

- TypeScript
- Bun runtime and package manager
- Grafana Foundation SDK
- Native HTTP clients for Grafana, Prometheus-compatible APIs, and Superset
- Vitest, Oxlint, Oxfmt, Husky

### Important paths

- `config.json` — pages, profiles, metric selectors, RUM mappings, and thresholds.
- `scripts/collect-budgets.ts` — main data collection and report generation flow.
- `scripts/export-grafana.ts` — code-first Grafana resource export.
- `scripts/deploy-grafana.ts` — direct Grafana provisioning deployment.
- `lib/` — clients, queries, calculations, and report generation.
- `grafana/` — dashboard, alert-rule, model, and query definitions.
- `tests/` — calculator, client, resource, query, and report tests.
- `package.json` — authoritative commands and dependency versions.

### Typical validation

```bash
bun install
bun run typecheck
bun run lint
bun run test
bun run grafana:export
bun run grafana:deploy:dry
```

Use dry-run operations before any Grafana write. Do not deploy dashboards or alerts unless explicitly requested.

### Routing cautions

- The repository consumes synthetic telemetry but does not own its production schema.
- It deploys Grafana resources directly and does not use the central `deploy` repository for that flow.
- RUM/Superset and observability backends are external to this workspace.

---

## `sitespeed-lcp-export`

### Purpose

Provides two Python CLI flows:

1. Query monthly Sitespeed LCP through Grafana/VictoriaMetrics-compatible APIs and write mapped values to Google Sheets.
2. Submit, collect, aggregate, and export Catchpoint WebPageTest results to Google Sheets.

### Stack

- Python
- Click, requests, gspread, python-dotenv
- setuptools/pip editable installation
- Pytest
- Make convenience targets
- GitLab CI scheduled/manual export jobs

### Important paths

- `sitespeed_lcp_export/cli.py` — Sitespeed export orchestration.
- `sitespeed_lcp_export/grafana.py` — Grafana proxy client.
- `sitespeed_lcp_export/metrics.py` — metric query and label mapping.
- `sitespeed_lcp_export/sheet_layout.py` — worksheet structure parsing.
- `sitespeed_lcp_export/sheets_writer.py` — planned and guarded batch writes.
- `wpt_export/cli.py` — WPT submit/run/collect CLI.
- `wpt_export/api.py` — Catchpoint API, retries, throttling, and pagination.
- `wpt_export/collect.py` — metric extraction and monthly aggregation.
- `tests/` — metrics, sheets, WPT API/collection, and CLI tests.
- `pyproject.toml` — authoritative package metadata and console entrypoints.
- `.gitlab-ci.yml` — tests and scheduled/manual dry-run/apply jobs.

### Typical validation

```bash
make dev
make test
make dry
```

Google Sheets writes and Catchpoint submissions are external side effects. Use dry-run paths unless the user explicitly requests apply/submit.

### Routing cautions

- The Sitespeed metric contract comes from `performance-synthetic-monitoring-tests`.
- Grafana access conventions overlap with `performance-budgets`, but no code package is shared.
- Catchpoint WPT ownership overlaps with the synthetic repository; compare both implementations before changing their common matrix or API assumptions.
