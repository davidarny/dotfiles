---
name: claude-agent-broker
description: Orchestrate durable work and native session dialogue between Codex and Claude through the local Claude Agent Broker MCP server. Use when the user asks Claude to execute work, wants Codex and Claude to communicate, or wants to list, read, connect, continue, rename, or delete native Claude or Codex sessions without operating either Desktop UI. Do not use for ordinary Codex subagents or one-shot prompt suggestions.
---

# Claude Agent Broker

Use the `claude-agent-broker` MCP server. Do not operate the Claude Desktop UI directly;
use `handoff_task_to_claude_desktop` for the supported handoff.

## Roles

- The user is the leader. They own the goal, scope, and final decisions.
- Codex is the orchestrator. It delegates bounded work, monitors progress, answers routine
  questions from known context, requests leader decisions when necessary, and verifies the
  result.
- Claude is the executor. It knows all three roles from the broker-injected contract, works
  with Claude Code tools in bypass-permissions mode, and reports to Codex.

Do not blur these roles. Do not present Claude's output as verified until Codex has checked
the relevant files, tests, or external state.

## Usage monitoring

- Before the first delegation, connection, or continuation in a turn, run both checks. Run
  them in parallel when the host supports it:

  ```text
  codexbar usage --provider claude --json
  codexbar usage --provider codex --all-accounts --json
  ```

- While a broker task is active, run both provider checks together exactly once every five
  minutes, measured from the previous completed usage check. Do not check more often. Keep
  bounded `wait_task` calls running normally between checks and do not narrate unchanged
  usage. Before starting another executor turn, use the latest result when it is less than
  five minutes old; otherwise run the scheduled pair first.
- The Codex command returns one record per visible account. Evaluate every record, not only
  the first or currently active account. Read each account's `usage.primary`,
  `usage.secondary`, `usage.extraRateWindows`, reset times, and any available
  `pace.*.willLastToReset` or `pace.*.etaSeconds` fields. Read the corresponding fields from
  the Claude record. Summarize percentages, reset times, and material cost-cap risk for the
  leader, identifying a constrained Codex account by its `account` label when needed. Do not
  paste the raw JSON unless requested; it can contain account email and organization metadata.
- Apply warning thresholds separately to every account and rate window. Warn the leader when
  any record reports `willLastToReset: false`, a usage window is at least 80% consumed, or a
  provider cost cap is at least 90% consumed. Before an optional correction or follow-up turn,
  ask the leader when the account intended for that work has a current window at least 90%
  consumed or projected exhaustion within 30 minutes. Do not interrupt an already-running
  turn solely because of this check unless the leader set a hard limit.
- Treat a missing `codexbar`, malformed output, or provider error as a monitoring failure,
  not as zero usage. Report it once and continue the broker workflow unless the leader made
  usage monitoring a completion requirement. Never redeem a Codex reset credit without the
  leader's explicit authorization.

## Start or resume

1. Call `runtime_status` before the first delegation in a turn. If Claude authentication is
   missing, report the exact remediation from the tool and do not create a substitute
   one-shot session.
2. Before sending anything to an existing Claude session, read it first. Resolve its native
   session ID with `list_claude_sessions`, then call `read_claude_session` repeatedly with
   pagination until the full visible transcript has been read. Reconstruct the current goal,
   prior authorizations, completed work, open questions, and external actions from that
   transcript. Do not call `connect_claude_session`, `continue_task`, or `send_to_executor`
   until this read is complete. A task title, broker event summary, screenshot, or Claude's
   retained context is not a substitute for the transcript.
3. For new work, call `delegate_task` with an absolute working directory and a fresh UUID
   idempotency key. Put the complete objective, constraints, known context, definition of
   done, and required verification in the objective. Do not assume Claude can read the
   current Codex conversation.
4. For existing work, use `list_tasks` or the known task ID, then `get_task`. Read the linked
   native Claude transcript as required above, then continue that task with `continue_task`;
   never create a replacement merely because the Codex client or conversation restarted.
5. Reuse an idempotency key only when retrying the exact same mutating call. Generate a new
   UUID for every genuinely new task or follow-up turn.

## Native sessions

- `list_claude_sessions` and `read_claude_session` inspect native Claude transcripts. Agent
  SDK sessions need a handoff before Claude Desktop adds them to its sidebar.
- Before creating work, search for a relevant existing native session. If one exists, call
  `connect_claude_session` and then use `continue_task` on its returned broker task. Connecting
  does not create a Claude turn or copy history.
- `rename_claude_session` updates the native title and linked broker task. New delegated
  sessions receive their broker task title automatically.
- `delete_claude_session` is a permanent native delete. Call it only when the leader has
  explicitly authorized deletion in the current request. Pass the exact session ID as both
  `session_id` and `confirm_session_id`; active broker turns cannot be deleted.
- `handoff_task_to_claude_desktop` is a separate operation that preserves the task's existing
  native Claude SDK session (`cliSessionId`). Do not call explicit handoff on your own initiative
  during task creation or ordinary intermediate turns. Call it immediately when the leader
  directly requests handoff, with `trigger=user_request`. At the end of orchestration, after
  Codex has independently verified a successful final `completed` result and no correction turn
  remains, Codex must call this same operation with `trigger=orchestration_completed`. An executor
  or SDK `completed` outcome alone is not a final handoff trigger.
- Do not create a replacement session, copy a transcript, or add a broker-owned handoff lock.
  Native Claude Desktop/SDK ownership and contention rules are authoritative. Handoff success
  confirms that Desktop received the deep link and persisted a visible descriptor for the same
  `cliSessionId`; it does not claim native session ownership.
- Claude has symmetrical `*_codex_session` tools in its orchestrator MCP. It can list, read,
  connect, continue, wait for, rename, and delete native Codex threads that Codex Desktop
  displays. Before Claude connects to or continues an existing Codex session, it must call
  `read_codex_session` and read the relevant history first. Codex deletion also requires the
  exact ID twice and refuses active threads.
- Treat native session IDs as the cross-agent identity. Broker task IDs are durable routing
  records for Claude work, not replacement conversation IDs.

## Orchestrate

1. Track the latest event sequence and call `wait_task` with `after_seq` set to that value.
   Prefer bounded waits. Do not busy-poll or narrate unchanged snapshots.
2. When an `executor_message` event arrives, read its `request_id` and answer with
   `reply_to_executor`. This returns the answer to Claude's waiting broker tool without
   ending Claude's current turn. Answer from known instructions or evidence; ask the leader
   first when the request contains a material product, scope, risk, cost, or external-action
   decision.
3. Use `send_to_executor` to steer or correct Claude while its turn is running. The broker
   injects the message into the active SDK stream. If Claude is offline, the message is
   retained and injected into its next turn.
4. Use `continue_task` only for a new turn after the previous turn has completed, failed,
   become blocked, or returned `needs_input` after live dialogue could not resolve a
   leader-owned decision.
5. When Claude reports `completed`, verify the result independently and inspect warnings and
   artifacts. Send corrections through `continue_task` so the same Claude session retains
   context; do not hand off merely because this executor turn completed.
6. After verification succeeds and no correction turn remains, invoke
   `handoff_task_to_claude_desktop` with `trigger=orchestration_completed` as the final
   orchestration step. A direct leader request is the other trigger and requires an immediate
   `trigger=user_request` call, as described above. Leave ownership/contention to Claude.
7. Treat `blocked`, `failed`, and `interrupted` as durable states. Read the recorded error and
   events. Continue the same task after fixing the cause when appropriate.
8. If the leader asks to stop, call `cancel_task` and report the final recorded status.

The broker cannot execute Codex while no Codex process is running. Keep a bounded
`wait_task` call active while orchestrating. If Codex exits, Claude's messages remain durable
and are visible when Codex resumes the task.

The executor has bypass permissions. Scope is governed by the leader's request and the role
contract, not a technical sandbox. Do not authorize publishing, pushing, deploying, sending
messages, or other external mutations unless the leader's request includes that authority.
