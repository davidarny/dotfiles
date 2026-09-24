/**
 * Writes every agent's MCP server config from `mcp/servers.toml`, the single
 * source of truth for MCP servers:
 *
 * - Claude Code: `.claude/mcp-servers.json`, installed by `just claude-restore`.
 * - Codex: `.codex/mcp-servers.toml`, installed by `just codex-restore`.
 * - OpenCode: the `mcp` block of `.config/opencode/opencode.json` (stowed).
 * - Pi: `.agents/mcp.json` (stowed), the shared global config pi-mcp-adapter reads.
 *
 * Secrets stay references: `${VAR}` becomes `{env:VAR}` for OpenCode and
 * `env_vars` / header env references for Codex.
 *
 * Usage: `bun mcp-sync.ts [--check]`; `--check` writes nothing and fails when a
 * generated file is out of date.
 */
import { join } from "node:path";
import { readText } from "./lib/fs";
import { fail, ok, runMain } from "./lib/log";
import { type Agent, ALL_AGENTS, readServers, type Server, type Servers } from "./lib/mcp";
import { REPO, tilde } from "./lib/paths";
import { formatJson } from "./lib/json";
import { type TomlLiteral, tomlKey, tomlLiteral } from "./lib/toml";

/** A key of a Codex server table and its value; `undefined` leaves the key out. */
type TomlField = [key: string, value: TomlLiteral | undefined];

/** A server with its name, as `Object.entries` yields it. */
type NamedServer = [name: string, server: Server];

/** Rewrites one config value, e.g. a `${VAR}` reference into another syntax. */
type ValueTransform = (value: string) => string;

/** A value that is exactly one `${VAR}` reference. */
const WHOLE_REFERENCE = /^\$\{([A-Za-z_][A-Za-z0-9_]*)\}$/;

/** An `Authorization` value that is `Bearer ${VAR}`. */
const BEARER_REFERENCE = /^Bearer \$\{([A-Za-z_][A-Za-z0-9_]*)\}$/;

/** Every `${VAR}` reference in a value. */
const REFERENCES = /\$\{([A-Za-z_][A-Za-z0-9_]*)\}/g;

/**
 * Lists the enabled servers an agent gets. Codex also keeps disabled entries,
 * since its config has an `enabled` flag.
 *
 * @param servers - All servers.
 * @param agent - Agent to filter for.
 */
function serversFor(servers: Servers, agent: Agent): NamedServer[] {
  return Object.entries(servers).filter(
    ([, server]) =>
      (server.agents ?? ALL_AGENTS).includes(agent) && (agent === "codex" || server.enabled !== false),
  );
}

/**
 * Returns an object with each value transformed, or `undefined` for an empty
 * or missing object so JSON output omits the key.
 *
 * @param record - Object to transform.
 * @param transform - Value mapping.
 */
function mapValues(
  record: Record<string, string> | undefined,
  transform: ValueTransform = (value) => value,
): Record<string, string> | undefined {
  const entries = Object.entries(record ?? {});
  return entries.length ? Object.fromEntries(entries.map(([key, value]) => [key, transform(value)])) : undefined;
}

/**
 * Converts a server's timeout to milliseconds, the unit Claude Code and
 * OpenCode use.
 *
 * @param server - Server whose `timeout` is in seconds.
 */
function timeoutMs({ timeout }: Server): number | undefined {
  return timeout === undefined ? undefined : timeout * 1000;
}

/**
 * Renders the Claude Code `mcpServers` snapshot.
 *
 * @param servers - All servers.
 */
export function renderClaude(servers: Servers): string {
  const config = Object.fromEntries(
    serversFor(servers, "claude").map(([name, server]) => [
      name,
      server.url
        ? { type: "http", url: server.url, headers: mapValues(server.headers), timeout: timeoutMs(server) }
        : {
            type: "stdio",
            command: server.command,
            args: server.args,
            env: mapValues(server.env),
            timeout: timeoutMs(server),
          },
    ]),
  );
  return formatJson(config);
}

/**
 * Formats a value for Codex's TOML. Codex reads its numbers (timeouts) as
 * floats, so whole numbers get a `.0`.
 *
 * @param value - Value to format.
 */
function codexValue(value: TomlLiteral): string {
  return typeof value === "number" && Number.isInteger(value) ? `${value}.0` : tomlLiteral(value);
}

/**
 * Renders one Codex server table. Codex forwards environment variables only
 * under their own names, so a variable passed under another name is mapped by
 * wrapping the command in `/bin/sh`.
 *
 * @param name - Server name.
 * @param server - Server to render.
 */
function renderCodexServer(name: string, server: Server): string {
  const env: Record<string, string> = {};
  const envVars: string[] = [];
  const renamed: string[] = [];

  for (const [key, value] of Object.entries(server.env ?? {})) {
    const reference = value.match(WHOLE_REFERENCE)?.[1];
    if (!reference && value.includes("${")) throw new Error(`${name}: Codex cannot embed \${VAR} in env ${key}`);
    if (!reference) env[key] = value;
    else {
      envVars.push(reference);
      if (reference !== key) renamed.push(`${key}="$${reference}"`);
    }
  }

  let bearer: string | undefined;
  const envHeaders: Record<string, string> = {};
  const headers: Record<string, string> = {};
  for (const [key, value] of Object.entries(server.headers ?? {})) {
    const token = key === "Authorization" ? value.match(BEARER_REFERENCE)?.[1] : undefined;
    const reference = value.match(WHOLE_REFERENCE)?.[1];
    if (token) bearer = token;
    else if (reference) envHeaders[key] = reference;
    else if (value.includes("${")) throw new Error(`${name}: Codex cannot embed \${VAR} in header ${key}`);
    else headers[key] = value;
  }

  let command = server.command;
  let args = server.args ?? [];
  if (command && renamed.length) {
    args = ["-c", `${renamed.join(" ")} exec "$0" "$@"`, command, ...args];
    command = "/bin/sh";
  }

  const fields: TomlField[] = [
    ["url", server.url],
    ["bearer_token_env_var", bearer],
    ["env_http_headers", Object.keys(envHeaders).length ? envHeaders : undefined],
    ["http_headers", Object.keys(headers).length ? headers : undefined],
    ["command", command],
    ["args", args.length ? args : undefined],
    ["env_vars", envVars.length ? envVars : undefined],
    ["startup_timeout_sec", server.timeout],
    ["tool_timeout_sec", server.timeout],
    ["enabled", server.enabled === false ? false : undefined],
  ];
  const table = `mcp_servers.${tomlKey(name)}`;
  const lines = [`[${table}]`];
  for (const [key, value] of fields) if (value !== undefined) lines.push(`${key} = ${codexValue(value)}`);
  if (Object.keys(env).length) {
    lines.push("", `[${table}.env]`);
    for (const [key, value] of Object.entries(env)) lines.push(`${tomlKey(key)} = ${codexValue(value)}`);
  }
  return lines.join("\n");
}

/**
 * Renders the Codex `mcp_servers` snapshot and checks that it parses.
 *
 * @param servers - All servers.
 */
export function renderCodex(servers: Servers): string {
  const text = `${serversFor(servers, "codex")
    .map(([name, server]) => renderCodexServer(name, server))
    .join("\n\n")}\n`;
  Bun.TOML.parse(text);
  return text;
}

/**
 * Renders OpenCode's config with the `mcp` block replaced and every other key
 * kept.
 *
 * @param servers - All servers.
 * @param current - Current `opencode.json` content.
 */
export function renderOpencode(servers: Servers, current: string): string {
  const toEnv: ValueTransform = (value) => value.replaceAll(REFERENCES, "{env:$1}");
  const mcp = Object.fromEntries(
    serversFor(servers, "opencode").map(([name, server]) => {
      // serversFor already left out disabled servers.
      const common = { enabled: true, timeout: timeoutMs(server) };
      if (!server.url) {
        const command = [server.command, ...(server.args ?? [])];
        return [name, { type: "local", command, environment: mapValues(server.env, toEnv), ...common }];
      }
      // Headers carry the credentials, so OpenCode must not start an OAuth flow.
      const oauth = server.headers ? false : undefined;
      return [name, { type: "remote", url: server.url, headers: mapValues(server.headers, toEnv), oauth, ...common }];
    }),
  );
  return formatJson({ ...JSON.parse(current), mcp });
}

/**
 * Renders Pi's shared MCP config.
 *
 * @param servers - All servers.
 */
export function renderPi(servers: Servers): string {
  const mcpServers = Object.fromEntries(
    serversFor(servers, "pi").map(([name, server]) => [
      name,
      server.url
        ? { url: server.url, headers: mapValues(server.headers), directTools: true }
        : { command: server.command, args: server.args, env: mapValues(server.env), directTools: true },
    ]),
  );
  return formatJson({ mcpServers });
}

/**
 * Renders every agent's config and writes the ones that changed.
 *
 * @param check - Report stale files and fail instead of writing them.
 */
async function main(check: boolean): Promise<void> {
  const servers = await readServers();
  const opencodePath = join(REPO, ".config/opencode/opencode.json");

  const outputs: Record<string, string> = {
    [join(REPO, ".claude/mcp-servers.json")]: renderClaude(servers),
    [join(REPO, ".codex/mcp-servers.toml")]: renderCodex(servers),
    [opencodePath]: renderOpencode(servers, await Bun.file(opencodePath).text()),
    [join(REPO, ".agents/mcp.json")]: renderPi(servers),
  };

  const stale: string[] = [];
  for (const [path, text] of Object.entries(outputs)) {
    if ((await readText(path)) !== text) stale.push(path);
  }

  if (!stale.length) {
    ok("MCP configs match mcp/servers.toml");
  } else if (check) {
    fail("MCP configs differ from mcp/servers.toml", [...stale.map(tilde), "run just mcp-sync"]);
    process.exitCode = 1;
  } else {
    for (const path of stale) {
      await Bun.write(path, outputs[path]);
      ok("Wrote", tilde(path));
    }
  }
}

// Tests import the renderers; only a direct run writes files.
if (import.meta.main) await runMain(() => main(Bun.argv.includes("--check")));
