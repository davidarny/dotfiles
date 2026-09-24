# Preprod candidate measurement

Production is measured with Catchpoint WPT. Preprod is not: `preprod*.mostbet-ssr.com` answers **403** to any agent outside the corporate network, so a WPT test against a stand completes, spends its runs and returns a single failed document request. Preprod candidates are measured by the Sitespeed fleet in `performance-synthetic-monitoring-tests`, whose runners sit inside that network.

Local work may inspect source and downloaded artifacts or run focused correctness checks, but it must not build, start or measure baseline/candidate applications locally.

## Performance stands

- Use only `https://preprod14.mostbet-ssr.com` and `https://preprod15.mostbet-ssr.com`. They belong to the performance team; `code-style/16-deploy.md` records that reservation. Every other preprod stand belongs to QA and stays outside this workflow, and so does every `dev*` stand, whatever the deploy mechanism makes reachable.
- A stand runs the frontend against the `https://mostbet-gate.com` backend (`DEPLOY_ENV=preproduction`, `CLUSTER=stage`, `HELM_RELEASE=web-<release>`), so its timing describes that backend, not production.
- The preprod suites reach the stands with the cookie `wellcome=in202511`, and no `design=new`: the stand sets that itself.

## Deploying a revision to a stand

Deploy it yourself by pushing a tag. Push the revision's branch first, then tag the commit you want served:

```sh
git tag mostbet-next-<version>-preprod15 <sha>
git push origin mostbet-next-<version>-preprod15
```

`<version>` is digits and dots, above the highest existing one (`git ls-remote --tags origin | sort -V | tail`). The stand name is the tag's fourth dash-separated field and is what the pipeline deploys, so it must match the stand exactly.

That produces a pipeline with `source=push` carrying three jobs, `env`, `build:web` and `deploy:web`, and nothing else. `deploy:web` finishing is the moment the stand starts serving the revision. Allow roughly fifteen minutes from push.

The rule lives in `datsteam/ops/deploy`, `mostbet-next/.gitlab-ci.yml`, anchor `DEPLOY_TAG_STAND`. It covers `devi`, `dev<N>`, `dev<N>s<M>`, `preprod` and `preprod1` upward. It deliberately does not cover `production`, `preprod0` or a bare `dev`, so a tag cannot reach production. Read the anchor before assuming a stand is reachable; if it is gone, deploying is the user's manual step from the deploy panel, and you hand them a copy-paste table listing both stands, the `RELEASE` and the `ref`, including the stand that keeps what it already serves.

Use only the stands this workflow reserves, whatever the tag rule makes technically reachable.

Read back what a stand actually serves from the `deployInfo` object in the page's RSC flight payload:

```json
{"environment":"preproduction","stand":"preprod14","branch":"master",
 "commitSha":"<40 hex>","shortCommitSha":"<8 hex>","deployedAt":"<UTC>",
 "pipelineId":"<id>","pipelineUrl":"<url>"}
```

Fetch the route from this machine (inside the network) and read that object before and after every measurement round. Reject a stale image, a mismatched revision, a redirect, a guest shell, a skeleton or an error page.

`deployedAt` is the **build** job's start, not the moment the stand began serving that revision — the gap runs to ten minutes or more. To decide which measurement passes belong to the new revision, take `finished_at` of the pipeline's `deploy:web` job and discard every pass that started before it.

## Measuring through the Sitespeed fleet

### 1. Put the route in the preprod suite

Cells live in `tests/preprod/<cell>/<cell>.txt`, one line per URL and connectivity:

```text
https://preprod14.mostbet-ssr.com/en/promo --browsertime.connectivity.profile 3gfast --cookie wellcome=in202511
```

Add the route for both stands, matching the file's existing grouping and its three profiles (`4g`, `3gfast`, `native`). Commit on the Jira branch and push. Keep `preprod0` lines alone — that stand is not part of this comparison.

### 2. Run the narrowed pass

The dedicated preprod runners are `speed.mumbai.preprod` (13.200.63.41) and `speed.frankfurt.preprod` (35.159.45.190); `~/.ssh/config` carries the user and key under `Host speed.*`. Normally each loops `preprod/desktopFirstView preprod/emulatedMobileFirstView preprod/emulatedMobileWarmCache` forever.

`deploy_single` is a manual job in the branch (and MR) pipeline, a parallel matrix keyed by runner IP. It redeploys the repo tarball to that one runner and restarts `loop.sh` there. Four optional variables narrow what it then runs: `TEST_SUITES`, `TEST_DOMAIN`, `TEST_PAGE`, `TEST_CONNECTIVITY`. Leaving `TEST_DOMAIN` unset measures every host in the suite for that page and connectivity, which puts both stands in the same pass on the same machine — the comparison you want.

Find the job for the preprod runner and play it with variables:

```sh
P=datsteam%2Fperformance%2Fperformance-synthetic-monitoring-tests
glab api "projects/$P/pipelines?ref=<branch>&per_page=1"          # pipeline id
glab api "projects/$P/pipelines/<pipeline>/jobs?per_page=100"      # find deploy_single: [13.200.63.41, ...]
glab api --method POST "projects/$P/jobs/<job>/play" \
  -H "Content-Type: application/json" --input play.json
```

`play.json` holds `{"job_variables_attributes":[{"key":"TEST_SUITES","value":"preprod/emulatedMobileFirstView"},{"key":"TEST_PAGE","value":"/en/promo"},{"key":"TEST_CONNECTIVITY","value":"3gfast"}]}`. The explicit `Content-Type` matters: without it `glab api --method POST` sends none and GitLab answers 415.

Confirm the switch on the runner — `pgrep -af loop.sh` shows the exports and the narrowed suite.

### 3. Read the numbers from Grafana

Every pass also writes to VictoriaMetrics. Read the comparison here first — it is one MCP call and needs no SSH. Go to the on-box reports only for what these series do not carry.

Grafana MCP, datasource uid `ac874ca1-8d7f-4da8-8b3f-37df78544021`. The dashboard that already frames this comparison is **Preprod Compare**, uid `359c9f03-5677-43a3-802a-8c50169d5ecc` (folder `Performance`, uid `bfd4c6gzyxq0wf`); the same folder holds `Compare Web Vitals`, `LCP report`, `Web Performance regressions` and `CI Performance Comparison [VM]`.

Series are `<metric>_<aggregation>`, aggregation one of `min`, `mean`, `median`, `p90`, `max` (the data also carries `p10`, `p99`, `mdev`, `rsd`, `stddev`). Selector:

```promql
largestContentfulPaint_median{environment="preprod", statistics="googleWebVitals",
  summaryType="pageSummary", group=~"preprod1[45]_mostbet-ssr_com",
  machine="in_mumbai_cpu_8_ram_16_aws", page="_en_promo",
  testName="mobileFirstView_360x800", connectivity="3gfast", browser="chrome"}
```

| Label | Value |
| --- | --- |
| `group` | measured host, dots as underscores — `preprod14_mostbet-ssr_com`. Separates the two stands. |
| `page` | route, slashes as underscores — `_en_promo` |
| `environment` | `preprod`, `production`, `experiment` |
| `testName` | cell slug — `mobileFirstView_360x800`, `mobileWarmCache_360x800`, `desktopFirstView`, plus the `…Auth…` and `desktopFirstViewVisual` variants |
| `connectivity` | `3gfast`, `4g`, `native` |
| `machine` | preprod runners: `in_mumbai_cpu_8_ram_16_aws`, `de_frankfurt_cpu_8_ram_16_aws` |
| `summaryType` | always `pageSummary` for a route; `summary` is the run-wide roll-up |
| `statistics` | which producer group the metric belongs to — see below |
| `origin` | `browsertime`, `pagexray` or `coach` — the producer |

`statistics` routes the metric name:

| `statistics` | Carries |
| --- | --- |
| `googleWebVitals` | `largestContentfulPaint`, `firstContentfulPaint`, `cumulativeLayoutShift`, `totalBlockingTime`, `firstInputDelay`, `interactionToNextPaint`, `ttfb` |
| `timings` | `backEndTime`, `frontEndTime`, `fullyLoaded`, `pageLoadTime`, `domInteractive`, `serverResponseTime`, `ttfb`, and the whole navigation-timing set |
| `deltaToTFFB` | `largestContentfulPaint`, `firstContentfulPaint` measured from TTFB |
| `pageinfo` | `cumulativeLayoutShift`, `domElements` |
| `cpu` | `RecalcStyleCount`, `FirstMeaningfulPaint`, `JSHeapUsedSize`, `cpuBenchmark`, trace event durations (`Layout`, `ParseHTML`, `RunTask`, …) |
| `errors`, `console`, `cdp`, `browser`, `renderBlocking` | run health and browser identity |

Three metric names live in two groups each — `largestContentfulPaint` and `firstContentfulPaint` (`googleWebVitals` + `deltaToTFFB`), `cumulativeLayoutShift` (`googleWebVitals` + `pageinfo`), `ttfb` (`googleWebVitals` + `timings`). Omit `statistics` and the series double.

Artifact size and request counts come from `pagexray` as `*_value` metrics, which carry no `statistics`: `contentSize_value{contentType="html", party="firstParty"}`, the same for `javascript`/`css`/`image`/`svg`/`font`, and `200_value{responseCodes="response"}` for the request count. Pin `contentType` and `party`, or the unlabelled roll-up returns a mixed, unusable series. A markup change shows up here directly — SSR'ing a route moved `contentType="html"` from 414 874 to 442 158 bytes on the pass where the candidate took over.

The dashboard carries annotation tracks `mostbet_next_deploy_finished_preprod0/14/15`, so deploy boundaries are visible on the graph without looking up a pipeline.

Two limits. A pass writes one point per URL and the value is already an aggregate over that pass's iterations, so a median of these points is a median of medians; use a range query with a step no larger than the pass interval, never an instant query at "now". And nothing here carries `commitSha`, so revision identity still comes from step 4.

A flat gap at the right edge usually means the runner is stuck, not that the metrics broke. A pass that spans a deploy hits `config/webVitalsComplete.js`, the suite's `pageCompleteCheck`, which needs `loadEventEnd > 0`, one LCP entry, and five seconds with an unchanged LCP signature. While the stand is rolling this never becomes true, and browsertime retries the iteration five times at 120 s each — ten minutes with no pass completing and nothing written.

Do not wait that out. As soon as a deploy lands, or whenever a pass has been running far longer than the cell's normal duration, check and abort:

```sh
ssh speed.mumbai.preprod 'sudo -n docker logs --tail 50 sitespeedio 2>&1 | grep -c "trying .* more time"'
ssh speed.mumbai.preprod 'sudo -n docker kill sitespeedio'
```

`run.sh` starts one `docker run --rm --name sitespeedio` per URL and never checks its exit code, and `loop.sh` keys only on `run.sh`'s final `chown_results`. So killing the container ends that one URL's run and the loop proceeds to the next immediately; it does not stop monitoring. The aborted pass leaves a directory with no HAR for that host — discard it, as it straddles two revisions anyway.

Better still, kill it the moment `deploy:web` finishes, before the retries start. That turns a ten-minute stall into the next pass.

### 4. Go to the on-box reports for what Grafana does not carry

Per-iteration values, the deployed revision of each pass, waterfalls, traces, screenshots.

Results land on the runner under `sitespeed-result/<slug>/<YYYY-MM-DD-HH-MM-SS>/`, one timestamped directory per sitespeed invocation, where `<slug>` is the cell config slug. Inside, `pages/<host with dots as underscores>/<route>/` holds `index.html`, one `N.html` per iteration, `metrics.html` and `data/` with `browsertime.har.gz`, `trace-N.json.gz`, `console-N.json.gz` and `screenshots/`.

In the HAR, `log.pages[i]` is iteration `i` and carries `_googleWebVitals` (`largestContentfulPaint`, `cumulativeLayoutShift`, `firstContentfulPaint`, `ttfb`, `totalBlockingTime`) and `_cpu.longTasks`. The document entry's `response.content.text` holds the served HTML, so `deployInfo.commitSha` in it assigns that pass to a revision.

`data/screenshots/<iteration>/` holds `largestContentfulPaint.jpg` with the LCP element boxed in red, `layoutShift.jpg`, and `afterPageCompleteCheck.jpg`. Compare the baseline and candidate LCP screenshots: if the boxed element is the same, the candidate moved when it arrives, not what counts as LCP — which is the claim a timing improvement needs. The slug root also carries a latest-pass copy of these per URL (`<group>.<page>.<testName>.largestContentfulPaint.chrome.<connectivity>.jpg`, `…layoutShift…`, plus a `.json` with browser version and iteration count), but every pass overwrites it, so take the per-pass copies inside the pass directory.

Assign passes by that `commitSha`, not by wall-clock against the deploy time. Stands are shared: a pass can land on someone else's branch between your baseline and your candidate, and only the HAR shows it.

Copy what the comparison needs off the box into the task's evidence directory; `tar --exclude="trace-*.json.gz"` keeps a pass around 7 MB instead of 40. On-box reports are pruned within hours, so collect promptly.

### 5. Restore the runner

The narrowed run replaces that runner's normal preprod monitoring until someone puts it back: while it is narrowed, the other preprod cells and routes are not being measured. Restoring is part of finishing the task, not an optional follow-up.

Replay a `deploy_single` job for that runner **with no job variables**. The playbook then resolves `default_test_suites` from the inventory and restarts `loop.sh` with the full set.

Pick the pipeline deliberately, because `deploy_single` also ships that pipeline's copy of `tests/`. Replaying from your own branch restores every cell but leaves your suite edit on the runner. So decide with the user what happens to the route you added in step 1:

- keep it — open an MR for the suite change, merge it, then replay `deploy_single` from the new `master` pipeline;
- drop it — replay `deploy_single` from the last `master` pipeline, which takes the runner back to its pre-task state.

Confirm with `pgrep -af loop.sh` on the runner that the exports are gone and all three preprod cells are listed again, and record that check in the evidence.

## Preserve the comparison

- Treat the first baseline/candidate assignment to preprod14/preprod15 as half of the experiment. Swap the revisions between the stands and collect an equally sized second half before accepting a timing result.
- The crossover exists to separate a candidate effect from a stand effect, so it is only skippable when that question is already answered. CLS qualifies when it holds one value per revision across every run on both stands and the same-revision control put the two stands on the identical figure: the stand hypothesis is then falsified by the control rather than untested. A timing metric never qualifies. Skipping is the user's call; record the control figures that justify it next to the result.
- `master` moves during a measurement day. Before the crossover, check whether it still points at the candidate's base; if it has moved, rebase the candidate onto the new `master` and redeploy both stands, so each half compares one base. Halves may sit on different bases as long as each half is internally consistent — say so in the evidence, and support it with a measurement of the new base on the same route and cell.
- Before the candidate lands, run one pass with both stands on the same revision. That control measures the stand-to-stand delta under identical source, which is the only way to tell a candidate effect from a stand effect later. Keep any unexplained delta unassigned until the control or the crossover isolates it.
- Keep both halves separate in the evidence. Combine them only after confirming the same page identity, revision, cell, cookies, connectivity and iteration count.
- Finish one candidate before deploying the next. A rejected candidate ends that branch; return to the admitted baseline evidence before testing another source change.
- Keep the deployments and the narrowed run until every report is collected. Roll back or replace them only when that external action is authorized.
