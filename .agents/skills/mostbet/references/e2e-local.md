# Local E2E in mostbet-next

Use when running, comparing, or diagnosing `mostbet-next` Playwright E2E outside CI. The repository guides `code-style/8.2-e2e-testing.md` and `code-style/8.3-e2e-mocking.md` own the commands; this file records how to reproduce the CI verdict locally.

## Baseline assumption

`master` E2E is green in CI. A local failure is an environment or change defect until a same-condition baseline run proves otherwise. Compare before diagnosing product behavior.

## Run shape

- Next.js and Playwright run on the host with the Node from `.nvmrc`; Docker runs only WireMock through `npm run mock-server:start` / `mock-server:stop`.
- Build once with `npm run build:mocks`. The build is independent of Playwright, Allure, and `@core/testing` versions, so a baseline checkout with identical app source can reuse a copy of `build/`.
- Install the browsers of the Playwright version in `node_modules`: `npx playwright install chromium webkit`. The `mobile` project is `iPhone 15` (WebKit).
- Provide `E2E_AUTH_TOKEN` from the main checkout's `.env.local` 1Password FIFO through `1password-handoff`; the task worktree has no `.env.local`.

## CI parity

- `CI=true`: CI retries, worker count, and `forbidOnly`. Without it the HTML reporter's `open: 'on-failure'` serves the report and the process never exits after a failure.
- `MOCK_TARGET_URL=` (empty): the tracked `.env.test` sets it, which makes WireMock proxy unmatched requests to the real API. CI writes its own `.env.test` without it.
- `MOCK_SERVER_URL=http://localhost:8080 NODE_ENV=test`, then `npx playwright test`.
- One run per spec. All workers share one WireMock, so `--repeat-each` with parallel workers races on mapping import and fails with `Failed to import mappings: Not Found`.

## Comparison

Run baseline (`origin/master` dependencies) and candidate with the identical command, sequentially (both use ports 3000 and 8080). Report passed, failed, flaky, and skipped for each. Record Node through Allure `environment.properties` (`NODE_VERSION`).

## Watching the run

Start the run in the background and arm a monitor on the log whose filter matches every terminal outcome: `✘`, `Error:`, `BUILD MISMATCH`, the summary counts, and the run's end marker. Inspect each failure's `test-results/*/error-context.md` as soon as it appears and report it while the run continues. Truncating a log that a running process writes corrupts its head, so rotate by filename instead.

## CI browsers

`mr:e2e` runs in the image from the GitLab CI/CD variable `E2E_PLAYWRIGHT_IMAGE` and installs no browsers. A Playwright bump needs the matching `mcr.microsoft.com/playwright:v<version>-jammy`; the variable is outside every repository, so its change belongs to OPS and must land together with the merge, because `master` still uses the old version.

## Known CI flake

`src/services/sentry/__tests__/sentry-http-module.server.test.ts` (real 50 ms socket timeout) fails intermittently in `mr:test`. Confirm it in other MRs' failed jobs, then retry the job.
