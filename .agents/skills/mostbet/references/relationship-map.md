# Relationship Map

This is a navigation and blast-radius map, not a substitute for current source. Confirm every edge from current manifests, configuration, queries, and implementation before changing another repository.

## Evidence classes

- `explicit`: direct CI include, configuration reference, source call, or matching owned path.
- `operational/config`: shared deployment environment, hostname, ingress, image, or runtime configuration contract.
- `telemetry/protocol`: producer/consumer relationship through metrics, labels, datasource, HTTP API, or report schema.
- `inferred`: an organizational or infrastructure relationship still requiring evidence.

Operational and telemetry edges do not establish source dependencies.

## Topology

```text
mostbet-spa source
    | independent legacy CI include
    v
deploy/mostbet/mostbet-front

mostbet-core/packages/*
    | published @core/* artifacts, peer/engine contracts
    v
confirmed package consumers (including mostbet-next)

mostbet-next source
    | explicit CI include and source-owned Dockerfiles
    v
deploy/mostbet-next
    | image build, Helm/Kubernetes, ingress, runtime environment
    v
deployed frontend environments
    | browser-level synthetic measurements
    v
performance-synthetic-monitoring-tests
    | Sitespeed metric and label protocol
    +------------------------------+
    |                              |
    v                              v
performance-budgets         sitespeed-lcp-export
    |                              |
    v                              v
Grafana dashboards/alerts   Google Sheets reports

performance-synthetic-monitoring-tests <--> sitespeed-lcp-export
             independent/overlapping Catchpoint WPT flows
```

## Verified edges

### `mostbet-spa -> deploy`

- **Type:** `explicit` CI include.
- **Contract:** SPA delegates CI to `mostbet/mostbet-front/.gitlab-ci.yml` in the deployment repository; this is a separate pipeline from SSR.
- **Evidence to inspect:** `mostbet-spa/.gitlab-ci.yml`, its referenced deploy YAML, `mostbet-spa/package.json`, `scripts/setHomePage.js` and `config/paths.js`.
- **Impact:** coordinate SPA build variants, base paths, CDN destinations, pipeline runtime and delivered assets. Trace the active Docker/Ansible path before treating a legacy file as deployed configuration.

### `mostbet-spa <-> mostbet-next`

- **Type:** potential `operational/config` and external API contracts, to establish per task.
- **Evidence to inspect:** both applications' route/auth/cookie/API implementations and the relevant deployment host/redirect configuration.
- **Impact:** a shared session, cross-application redirect or backend contract may require coordinated changes after that link is verified.
- **Not established by similar features:** shared source, a local package link, identical dependency versions or an automatic requirement to port every change. Check core-package consumption separately from manifests and lockfiles.

### `mostbet-core -> mostbet-next`

- **Type:** `explicit` published-package dependency, not a local workspace link.
- **Contract:** consumer-pinned `@core/*` artifacts and their exports, declarations, CLI, peer dependencies and supported engines.
- **Evidence to inspect:**
  - `mostbet-core/package.json`, `lerna.json`, `nx.json`
  - affected `mostbet-core/packages/*/package.json`, source and build configuration
  - `mostbet-next/package.json`, `package-lock.json` and imports/scripts using the package
- **Impact:** marker changes can alter test selectors; testing changes can affect fixtures, mock CLI, Playwright and CI browser compatibility. For other packages, establish a real consumer before claiming frontend impact.
- **Delivery:** validate emitted artifacts and the consumer's resolved dependency tree. Source changes or publication in core do not update an already pinned consumer.
- **Ownership:** `@sb/react-lib` has its own producer outside core. Core changes do not implicitly relax sportsbook peer constraints.

### `mostbet-next -> deploy`

- **Type:** `explicit`
- **Contract:** frontend GitLab CI includes the Mostbet pipeline from the central deployment repository.
- **Evidence to inspect:**
  - `mostbet-next/.gitlab-ci.yml`
  - `deploy/mostbet-next/.gitlab-ci.yml`
- **Impact:** deployment pipeline contract changes can affect frontend builds and releases without a source change in the frontend repository.

### `deploy -> mostbet-next runtime`

- **Type:** `explicit` and `operational/config`
- **Contract:** deployment CI builds source-owned web/Storybook Dockerfiles, pushes images, deploys Helm resources, and injects API and observability environment values.
- **Evidence to inspect:**
  - `deploy/mostbet-next/.gitlab-ci.yml`
  - `deploy/mostbet-next/web/template.yaml`
  - `deploy/mostbet-next/web/**/values*.yaml`
  - `deploy/mostbet-next/storybook/**/values*.yaml`
  - `mostbet-next/Dockerfile.web`
  - `mostbet-next/Dockerfile.storybook`
  - `mostbet-next/next.config.mjs`
  - `mostbet-next/src/api/fetcher/`
  - `mostbet-next/src/instrumentation.ts`
- **Impact:** coordinate changes to Dockerfile names, image build inputs, public/runtime variables, API routing, metrics paths, OpenTelemetry endpoints, ingress, probes, or resources.

### `deploy -> synthetic targets`

- **Type:** `operational/config`
- **Contract:** synthetic suites target preproduction and production frontend environments provisioned by deployment configuration.
- **Evidence to inspect:**
  - current ingress/host values under `deploy/mostbet-next/web/`
  - current URL and journey files under `performance-synthetic-monitoring-tests/tests/`
- **Impact:** environment, domain, redirect, auth, cookie, or ingress changes can invalidate synthetic targets.
- **Not:** a CI include, package dependency, or source import.

### `performance-synthetic-monitoring-tests -> performance-budgets`

- **Type:** `telemetry/protocol`
- **Contract:** Sitespeed produces metric names and dimensions consumed by budget queries and selectors.
- **Producer evidence:**
  - `performance-synthetic-monitoring-tests/config/`
  - `performance-synthetic-monitoring-tests/deploy/templates/`
  - `performance-synthetic-monitoring-tests/machines.csv`
  - `performance-synthetic-monitoring-tests/tests/`
- **Consumer evidence:**
  - `performance-budgets/config.json`
  - `performance-budgets/lib/`
  - `performance-budgets/grafana/`
- **Impact:** verify metric names, labels, page groups, test names, profiles, units, aggregation, and historical continuity on both sides.
- **Not:** a shared package or direct CI dependency.

### `performance-synthetic-monitoring-tests -> sitespeed-lcp-export`

- **Type:** `telemetry/protocol`
- **Contract:** the exporter queries Sitespeed metrics and maps their labels into monthly reports.
- **Producer evidence:** synthetic `config/`, fleet metadata, and test suites.
- **Consumer evidence:**
  - `sitespeed-lcp-export/sitespeed_lcp_export/config.py`
  - `sitespeed-lcp-export/sitespeed_lcp_export/metrics.py`
  - `sitespeed-lcp-export/sitespeed_lcp_export/grafana.py`
- **Impact:** coordinate metric name, label, unit, group, profile, and aggregation changes.
- **Not:** a source import or package dependency.

### Synthetic telemetry transport

- **Type:** `inferred`
- **Known:** Sitespeed output uses an Influx-compatible publication path; consumers query Prometheus-compatible data through Grafana/VictoriaMetrics.
- **Unknown here:** the infrastructure component that performs or exposes the complete transport between those protocols.
- **Rule:** do not claim a specific transport implementation without evidence from infrastructure outside these repositories.

### `performance-synthetic-monitoring-tests <-> sitespeed-lcp-export`

- **Type:** `explicit overlap`, not dependency
- **Contract:** both implement Catchpoint WebPageTest submission assumptions and overlapping URL/location/device/network matrices.
- **Evidence to inspect:**
  - `performance-synthetic-monitoring-tests/scripts/webpagetest.sh`
  - `performance-synthetic-monitoring-tests/docs/WEBPAGETEST.md`
  - `sitespeed-lcp-export/wpt_export/config.py`
  - `sitespeed-lcp-export/wpt_export/api.py`
  - `sitespeed-lcp-export/wpt_export/collect.py`
  - `sitespeed-lcp-export/.gitlab-ci.yml`
- **Impact:** compare both implementations for API URL/version, authentication header, payload fields, node/device/network mappings, custom headers, throttling, retries, result metrics, and environment variable names.
- **Ownership distinction:** the synthetic repository provides an interactive submit path; the exporter provides submit, collection, aggregation, scheduled jobs, and sheet writes.

### `performance-budgets <-> sitespeed-lcp-export`

- **Type:** `telemetry/protocol`
- **Contract:** both use similar Grafana datasource proxy and Prometheus-compatible query conventions.
- **Evidence to inspect:**
  - `performance-budgets/lib/prometheus.ts`
  - `performance-budgets/config.json`
  - `sitespeed-lcp-export/sitespeed_lcp_export/grafana.py`
  - `sitespeed-lcp-export/sitespeed_lcp_export/config.py`
- **Impact:** datasource/proxy/auth/query-semantics changes may require coordinated updates.
- **Not:** shared code, workspace linkage, or automatic synchronization.

### `performance-budgets -> mostbet-next`

- **Type:** `operational/config` for target mapping; otherwise performance governance
- **Contract:** budgets evaluate telemetry for deployed frontend pages and journeys.
- **Evidence to inspect:** current page/group mappings in budget config and current frontend/deploy route ownership.
- **Impact:** route/page-group changes can require budget mapping updates; threshold/report changes usually do not require frontend source edits.
- **Do not infer:** automatic CI enforcement unless a current pipeline or ticket proves it.

### `sitespeed-lcp-export -> mostbet-next`

- **Type:** `operational/config` for target mapping; otherwise reporting
- **Contract:** monthly Sitespeed and WPT reports represent deployed frontend properties.
- **Evidence to inspect:** current exporter mappings, synthetic targets, and deploy/frontend route ownership.
- **Impact:** domain, route, page-group, and product-label changes may require reporting updates.
- **Not:** a source dependency.

## Major cross-project workflows

### Frontend release

```text
mostbet-next source and Dockerfiles
  -> frontend GitLab include
  -> deploy/mostbet-next build jobs
  -> image registry
  -> Helm/Kubernetes values and templates
  -> deployed web/Storybook services, ingress, secrets, metrics, and probes
```

Primary repository depends on the requested change:

- application code or Dockerfile behavior: `mostbet-next`;
- pipeline, environment, ingress, Kubernetes, or runtime injection: `deploy`.

### Synthetic measurement to budgets

```text
deployed frontend
  -> Sitespeed suites on managed measurement hosts
  -> metric names and fleet/test labels
  -> external telemetry storage and Grafana access
  -> performance-budgets synthetic queries
  -> RUM comparison, budget reports, dashboards, and alerts
```

A producer schema change starts in `performance-synthetic-monitoring-tests`; a threshold/dashboard/report change starts in `performance-budgets`.

### Monthly Sitespeed reporting

```text
Sitespeed telemetry
  -> Grafana/VictoriaMetrics-compatible query
  -> label and worksheet mapping
  -> guarded Google Sheets write
```

The producer is `performance-synthetic-monitoring-tests`; the reporting consumer is `sitespeed-lcp-export`.

### Catchpoint WebPageTest reporting

```text
frontend URLs and test matrix
  -> Catchpoint submission
  -> history/result collection
  -> aggregation
  -> Google Sheets reporting
```

Check both repositories because submission assumptions are duplicated. Use `sitespeed-lcp-export` as primary for scheduled collection/reporting changes and the synthetic repository as primary for its interactive shell flow.

### Application observability

```text
mostbet-next metrics endpoint and OpenTelemetry instrumentation
  -> deploy-owned scrape/runtime configuration
  -> external observability backends
```

This application telemetry plane is distinct from browser-level Sitespeed telemetry. Do not assume performance budgets consume the application's own metrics endpoint.

## Explicitly absent direct edges

No verified direct integration exists for:

- `performance-budgets <-> deploy`;
- `sitespeed-lcp-export <-> deploy`;
- sibling repositories through Git submodules;
- sibling repositories through npm, Bun, pip, Composer, or Go workspace links; the core published-package edge above is separate from local workspace linkage;
- CI include/trigger relationships among the three performance repositories;
- a shared generated API contract or telemetry-schema package.

When evidence still shows no edge, say so instead of creating a speculative coordination task.
