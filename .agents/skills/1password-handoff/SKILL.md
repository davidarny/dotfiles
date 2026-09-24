---
name: 1password-handoff
description: Obtain task-required 1Password secrets once, including op:// references and managed FIFO env files, reuse a private temporary snapshot for autonomous work, and remove it when finished. Use when repeated CLI authorization prompts interrupt multi-step work with secrets.
---

# 1Password handoff

Complete one credential-acquisition phase while the user is available, then work from a private, task-owned temporary snapshot. This workflow is authorized by the shared instructions for secrets already needed by the user's task. It does not authorize reading unrelated items, sharing secrets with new destinations, or changing 1Password security settings.

Use [1password](../1password/SKILL.md) for CLI access. This skill owns temporary reuse and cleanup. Do not replace an existing task's working snapshot or stop its consumers merely because this skill has been installed.

## 1. Plan the acquisition

- Gather the known `op://` references, managed env/FIFO paths, and variable names the task will need before opening an authorization prompt. Reuse references already supplied or configured. Ask for a missing reference or source path, never for the secret value in chat.
- Limit the snapshot to those credentials and application variables. Do not export a vault or dump the full inherited environment. Do not copy CLI session tokens, account passwords, or recovery keys just to keep `op` unlocked.
- Prefer one `op run` invocation resolving a combined set of sources. Several requested items may still require separate prompts under 1Password policy; promise no repeated reads during work, not guaranteed suppression of all initial prompts.
- Inspect source metadata with `lstat` before reading. Preserve existing files, symlinks, FIFOs, permissions, and their producer processes.

## 2. Read references and FIFO files

### Individual secret references

Use named environment variables containing references, passed to one `op run` subprocess. The following illustrates the command shape; `CAPTURE_SCRIPT` is a task-local program prepared before this step, not a bundled command:

```sh
SERVICE_TOKEN='op://Vault/Service/token' \
DATABASE_PASSWORD='op://Vault/Database/password' \
op run -- python3 "$CAPTURE_SCRIPT"
```

The capture program reads only the explicitly selected variable names and writes them directly to the private snapshot. References are not secret values. Resolve values inside the subprocess; never substitute `$(op read ...)` into command arguments. For values that cannot be represented as environment variables, capture `op read` output in memory and write it directly to a private file without printing it.

### 1Password managed env/FIFO files

For an existing dotenv-format 1Password source, including a configured `.env.local` FIFO, use its supported consumer once:

```sh
op run --env-file="$PROJECT_ENV_SOURCE" -- python3 "$CAPTURE_SCRIPT"
```

The capture program selects application variables using an explicit allowlist derived from the env schema or documented runtime requirements. Do not `cat`, preview, hash, `cp`, or `source` the FIFO: an exploratory read can block, consume the stream, or cause another authorization prompt. Do not replace it with a regular file or copy it into a worktree.

References and FIFO sources can be acquired together by passing reference-valued environment variables plus `--env-file`. Check duplicate variable names first: env files take precedence over inherited variables, and the last `--env-file` takes precedence over earlier files. Rename temporary reference variables when necessary to avoid silently capturing the wrong credential.

A FIFO is a transport, not a format. If its contents are not dotenv, use the configured consumer or one bounded reader for that known format and write the result directly to the private snapshot. Do not guess a parser or read it repeatedly to discover its format.

Bound the acquisition process, including its children, so an unavailable FIFO producer or authorization timeout cannot hang indefinitely. On an actual unlock failure, ask the user to unlock/approve once, then retry the failed acquisition. Do not loop on prompts or disable authentication protections.

## 3. Store only for this task

Prepare the capture/launch code with the agent's native file editor. Programmatic writes are appropriate for the generated secret snapshot: values must travel directly from the authorized process into private storage, without entering a tool call or response.

- Use `mkdtemp` under the OS temporary directory, with an unpredictable task-specific name and directory mode `0700`. Use `umask 077` and exclusive file creation with mode `0600`; reject symlink destinations. Do not use a repository, Downloads, a synced folder, a shared fixed filename, or Trash.
- Use JSON for an env snapshot so quotes, dollar signs, backticks, and newlines remain data. Keep separate private files only when a consumer requires them, and record their exact paths for cleanup. Never execute the snapshot with shell `source` or `eval`.
- Record the task owner, creation time, selected variable names, and expiry alongside the snapshot. Default to eight hours or task completion, whichever comes first. Shorter credential lifetimes take precedence. Do not cache OTPs for later reuse.
- Validate required values are present without printing them. Report only success, variable count, permissions, and expiry. Keep the temporary path in current task state, never credential values in reports, memory, source, skills, or commits.
- If acquisition fails midway, delete partial task-owned secret files immediately. Preserve unrelated files and other tasks' caches.

## 4. Work without further prompts

Load the snapshot in the task's launcher, merge only required variables into each child process's environment, or read a required secret into the driver's memory. Pass file paths rather than secret values on command lines. Builds, tests, servers, API clients, and repeated measurements must use this same snapshot instead of calling `op` again.

Before reuse, check ownership, restrictive permissions, file type, snapshot expiry, and relevant credential expiry. Refuse expired snapshots; refresh only the required credentials when authorized. A 401/403 is not a reason to dump more secrets or automatically reauthorize every run.

`op run` normally masks stdout/stderr. A cached launcher must preserve that protection: redact captured secret values before forwarding logs, or capture logs in private files and inspect only a sanitized projection. Never run `printenv`, enable shell tracing, or log request authorization/cookie headers. Include generated credential files and browser profiles in the task-owned cleanup inventory.

Reuse is local to the authorized task. Keep other tasks' running processes and snapshots untouched. If work is interrupted, retain only the path, owner, expiry, and pending cleanup obligation in task state; validate them on resume.

## 5. Delete and verify

Cleanup is part of completion, not a suggested follow-up. Use a `finally`/exit handler for ordinary failures and cancellations, and an explicit final cleanup. Stop or await task-owned consumers first, then remove all exact recorded secret files through `rm -- "$secret_file"` and remove the empty temporary directory with `rmdir -- "$secret_dir"`.

This is an explicit exception to the shared trash convention: these temporary credentials must not remain in Trash. Never use recursive or wildcard deletion, `rm -rf`, or a broad `/tmp` sweep. Check that each path belongs to this task's created directory before deleting; unexpected contents require inspection, not broader deletion.

Verify every recorded secret path is absent before reporting cleanup. Delete an expired snapshot on discovery even if the task continues. Expiry metadata only prevents reuse; it does not delete files automatically. After a crash or forced termination, perform recorded cleanup on resume rather than assuming an exit handler ran. Do not claim secure disk erasure from `rm`.

Completion means the task used one bounded acquisition phase, reused its snapshot, and verified deletion. If cleanup is blocked, state the exact remaining private path and reason without exposing its contents.
