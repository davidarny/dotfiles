# Catchpoint WebPageTest investigations

Drive Catchpoint through its REST API only. The portal UI, its GraphQL calls, and browser automation against it are outside this workflow; when the API cannot deliver something, record the gap and use the substitute named below.

## Establish the target

Read the issue and related tasks/MRs first. Record the measured URL, phase (`production`, `preprod14`, or `preprod15`), locale, expected page marker, required authentication/feature flags, device, network, location, cache mode, and run count. Reuse the requested measurement profile; when none is specified, choose and state a diagnostic profile. An iPhone viewport alone does not establish an iPhone user agent.

Match the canonical synthetic suite for the route: `performance-synthetic-monitoring-tests` holds the measured cell (`tests/<phase>/<cell>/<cell>.txt` for URL, connectivity and cookies; `config/<cell>/<cell>.json` for viewport, iterations and mobile emulation) and `machines.csv` for the runner location. Reuse that cell's viewport class, connectivity, cookies and location so the diagnosis speaks about the monitored cell.

Run and fully export the affected production page before building a candidate. Analyze that series to prove the symptom, trace its cause, and admit hypotheses. For candidate verification, repeat the same profile against the public `https://preprod14.mostbet-ssr.com` and `https://preprod15.mostbet-ssr.com` routes after validating their deployed revisions. Do not compare production timing directly with preprod timing.

| Page scenario | WPT Performance | WPT Lighthouse |
| --- | --- | --- |
| Public, anonymous | On | On |
| Private or authenticated | On | Off |
| Public but cookie-gated | On | Off |

Determine authentication from the route contract and canonical synthetic suite before configuring WPT. An available token, authenticated sibling test, or reusable account does not make a public route authenticated. For a public route, use the anonymous suite unless the task explicitly targets personalized state; record authentication as a controlled dimension rather than an assumed prerequisite.

Lighthouse runs a separate navigation that does not inherit the script's cookies. A Mostbet route needing `design=new` answers 404 without it, so a Lighthouse run on such a route is invalid by construction: set `lighthouse: false` and record that reason. Confirm the gate with one `curl` before deciding. Keep simulated Lighthouse metrics, observed Lighthouse metrics, and WPT measurements separate.

## API access

The REST API key lives at `op://Dats.Team/Catchpoint/API key`. Acquire it once through [1password-handoff](../../1password-handoff/SKILL.md) and read it from that snapshot for every call. It authorizes Catchpoint operations only; a Mostbet `user_token` authorizes the measured page and is a different credential. Never print either value.

Base URL `https://io.catchpoint.com/api/v3.4/webpagetest`, header `Authorization: Bearer <key>`, header `Accept: application/json`.

Two properties of this host decide whether calls work at all:

- **Send a browser-like `User-Agent`.** Cloudflare fronts `io.catchpoint.com` and answers a default library signature (for example Python's `urllib`) with HTTP 403, body `error_code 1010`, `browser_signature_banned`. `curl/8.7.1` passes. The 403 says nothing about the key.
- **Pace requests.** Limits are per originating IP: 7/second, 10/minute, 500/hour, 2000/day. Space calls by ~7 seconds; a burst of probes costs the minute budget for the whole task.

Every response wraps its payload as `{"data": ..., "messages": [], "errors": [], "completed": true, "traceId": "..."}`.

## Sequence

### 1. Resolve IDs

Known values, current as of 2026-09:

| Dimension | Values |
| --- | --- |
| `nodeId` | Mumbai 4806, Bangkok 4807, Frankfurt 8343 |
| `connectionType` | 3G Fast 5, 4G 6, Native 11 |
| `deviceType` | Galaxy S23 50, iPhone 15 26, Desktop Chrome 22 (needs `deviceResolution`, 1920x1080 = 8) |

For anything else: `GET /enumerations?includeConnectionType=true&includeDeviceType=true&includeDeviceResolution=true`. Without those parameters the endpoint returns an empty `sections` array, which means the parameters were omitted, not that the catalog is empty.

### 2. Submit

`POST /test` with this body shape:

```json
{
  "url": "https://<host>/<locale>/<route>",
  "nodeId": 4806,
  "connectionType": 5,
  "deviceType": 50,
  "runs": 3,
  "firstViewOnly": true,
  "performance": true,
  "lighthouse": false,
  "labels": [{ "name": "<JIRA-KEY>", "color": "#DBFFAD", "values": ["<phase>-<route>-<half>"] }],
  "chromiumParameters": { "captureDevToolsTimeline": true },
  "script": {
    "body": "setCookie\thttps://<host>\tdesign=new\nsetCookie\thttps://<host>\ttheme=mobile\nnavigate\thttps://<host>/<locale>/<route>",
    "containsSensitiveData": false
  }
}
```

`\t` is a literal tab and `\n` a literal newline inside the JSON string. Match cookie and navigation hosts. Add experiment cookies only when the measurement design requires them, and record their state; disabling notifications changes the measured workload.

For an authenticated route, add `setCookie user_token=<JWT>` and `setCookie multi_auth_blocked=1` (it stops the injected session logging itself out during rendering), and set `"containsSensitiveData": true`. Check the JWT's `exp` without printing its payload and require at least 24 hours remaining; expiry alone does not prove the account can reach the route, so validate the rendered page and feature flags. Background: [Запуск WebPageTest с авторизацией](https://confluence.dats.tech/pages/viewpage.action?pageId=915928641), read through Confluence MCP.

The label carries the Jira key and a value identifying phase, candidate, stand and comparison half, such as `production-promo-js-html` or `preprod14-c1-baseline-a`. Submit once and keep `data.id` from the response; that integer is the test id every later call takes.

**Capture flags the schema accepts:** `chromiumParameters.captureDevToolsTimeline` plus the `script` fields above. Response bodies, network packet trace, netlog, Chrome trace, trace categories and the V8 profiler are not in the v3.4 schema, are not echoed back, and a 200 does not mean they applied. Treat them as unavailable: state that in the evidence record and recover the missing material by fetching the documents and chunks directly from production or the stand, which gives exact decoded and transferred sizes for JS, CSS and HTML.

### 3. Wait

`GET /history?search=<JIRA-KEY>&pageSize=5` returns the matching tests newest first, each with `id`, `status.name`, `url`, `runTime`, `runs`, `types`, `node.name` and `labels`. Use it for both jobs: confirm the saved configuration right after submitting, and poll `status.name` until `Completed`.

Poll every 30–60 seconds against a bounded deadline and continue independent source/MR work between checks. Report the actual queue or failure state rather than abandoning the run silently. If a submission appears to time out, check history for the route and label before resubmitting; a duplicate is a chargeable run.

### 4. Download

`GET /results/{testId}?run=N&includeWaterfall=true&includeFilmstrip=true&includeLighthouse=true`, once per run. Nothing requests all runs at once, and a single-run download cannot establish completeness for a multi-run test.

`data` carries the configuration readback (`deviceName`, `connectionName`, `locationName`, `screenWidth`, `screenHeight`, `isFvOnly`, `isLighthouse`, `hasScript`, `runs`, `labels`, `testUrl`, `medians`) and `data.runs[0]` the measured run:

| Need | Field |
| --- | --- |
| Metrics | `timeToFirstByte`, `render`, `firstContentfulPaint`, `largestContentfulPaint`, `speedIndex`, `cumulativeLayoutShift`, `visualComplete`, `fullyLoaded`, `bytesIn`, `fullyLoadedCPUms`, `docTime`, `domContentLoadedEventStart` |
| LCP attribution | `largestContentfulPaintType`, `largestContentfulPaintNodeType`, `largestContentfulPaintImageURL`, `largestPaints[]` (`time`, `type`, `size`, `url`) |
| Layout shifts | `layoutShifts[]` (`time`, `score`) |
| Waterfall | `requests[]` (`fullUrl`, `contentType.name`, `requestType`, `priority`, `startTime`, `endTime`, `ttfbStart`, `ttfbEnd`, `bytesIn`, `objectSizeUncompressed`, `responseCode`, `cdnProvider`, `initiator`) |
| Filmstrip | `videoFrames[]` (`time`, `visuallyComplete`, `image` as base64 JPEG) |

`cpuTimes.breakDown` comes back zeroed, so main-thread attribution rests on `fullyLoadedCPUms`, `mainThreadBlockingTimes` and request-level timing.

### 5. Validate before interpreting

Check on every run: final route and `initialUrl`, document response code, authenticated or public state, locale, `deviceName`/viewport against the requested profile, first-party resource success, and a page-specific marker in the filmstrip or fetched HTML. Reject redirects, error pages, guest shells and unresolved skeletons; mark such a series `invalid` and keep it only as diagnostic evidence. A `notFound()` from a route's layout answers HTTP 200 and paints «Page not found» only after hydration, so take identity from the last filmstrip frame and the LCP element, never from the status code.

Then connect loaded bytes, request timing, main-thread work, LCP and layout shifts to the route's source, separating shared work from route-specific work and from already tracked optimizations.

## Store the evidence

Keep exports in task-owned storage under `performance-synthetic-monitoring-tests/sitespeed-result/<JIRA-KEY>/` (git-ignored). Store a manifest with test id and results URL, phase, stand, deployed revision, sanitized configuration, run coverage, filenames and sizes, and every artifact that was unavailable with its reason. Validate contents rather than status codes: a 200 or a `.json` extension can hold an error page. Protect raw bodies, HAR and captures as sensitive.

The result page for a test is `https://portal.catchpoint.com/ui/Symphony/InstantTest/Webpage/{testId}/Details` — record it as a link for humans; the agent reads the API.

## Profile-language redirects

An authenticated user's saved language can trigger a client-side redirect, such as `/en/store` to `/ru/store`, even when the initial document returns HTTP 200. Check every run's final document URL and language, not just the submitted URL or first response.

Such a run is **invalid** for the requested locale. Exclude it from conclusions and baseline/candidate comparisons. Ask the user to change the measured account's profile language to the requested locale; leave the account and the destination locale alone. After the user confirms the correction, launch a fresh test with the same capture settings and task label, and verify that every run stays on the intended locale.
