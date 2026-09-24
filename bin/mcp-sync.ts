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
import { REPO, tilde } from "./lib/paths";
import { formatJson } from "./lib/settings";

/** Agents that get MCP servers. */
type Agent = "claude" | "codex" | "opencode" | "pi";

/** One server in `mcp/servers.toml`; the file header documents each field. */
interface Server {
  agents?: Agent[];
  command?: string;
  args?: string[];
  url?: string;
  env?: Record<string, string>;
  headers?: Record<string, string>;
  /** Startup and tool timeout in seconds. */
  timeout?: number;
  enabled?: boolean;
}

/** Server name to server, in source order. */
type Servers = Record<string, Server>;

/** Every agent, the default for a server without `agents`. */
const ALL_AGENTS: Agent[] = ["claude", "codex", "opencode", "pi"];

/** The source file. */
const SOURCE = join(REPO, "mcp/servers.toml");

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
function serversFor(servers: Servers, agent: Agent): [string, Server][] {
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
  transform: (value: string) => string = (value) => value,
): Record<string, string> | undefined {
  const entries = Object.entries(record ?? {});
  return entries.length ? Object.fromEntries(entries.map(([key, value]) => [key, transform(value)])) : undefined;
}

/**
 * Renders the Claude Code `mcpServers` snapshot.
 *
 * @param servers - All servers.
 */
function renderClaude(servers: Servers): string {
  const config = Object.fromEntries(
    serversFor(servers, "claude").map(([name, server]) => {
      const timeout = server.timeout && server.timeout * 1000;
      return [
        name,
        server.url
          ? { type: "http", url: server.url, headers: mapValues(server.headers), timeout }
          : { type: "stdio", command: server.command, args: server.args, env: mapValues(server.env), timeout },
      ];
    }),
  );
  return formatJson(config);
}

/**
 * Formats a TOML key, quoting it when it is not a bare key.
 *
 * @param key - Key to format.
 */
function tomlKey(key: string): string {
  return /^[A-Za-z0-9_-]+$/.test(key) ? key : JSON.stringify(key);
}

/**
 * Formats a TOML value. JSON strings are valid TOML basic strings.
 *
 * @param value - String, number, boolean, string array, or string table.
 */
function tomlValue(value: string | number | boolean | string[] | Record<string, string>): string {
  if (Array.isArray(value)) return `[${value.map((item) => JSON.stringify(item)).join(", ")}]`;
  if (typeof value === "object") {
    return `{ ${Object.entries(value)
      .map(([key, item]) => `${tomlKey(key)} = ${JSON.stringify(item)}`)
      .join(", ")} }`;
  }
  // Codex reads timeouts as floats.
  if (typeof value === "number") return Number.isInteger(value) ? `${value}.0` : `${value}`;
  return JSON.stringify(value);
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

  const bearer: string[] = [];
  const envHeaders: Record<string, string> = {};
  const headers: Record<string, string> = {};
  for (const [key, value] of Object.entries(server.headers ?? {})) {
    const token = key === "Authorization" ? value.match(BEARER_REFERENCE)?.[1] : undefined;
    const reference = value.match(WHOLE_REFERENCE)?.[1];
    if (token) bearer.push(token);
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

  const fields: [string, Parameters<typeof tomlValue>[0] | undefined][] = [
    ["url", server.url],
    ["bearer_token_env_var", bearer[0]],
    ["env_http_headers", Object.keys(envHeaders).length ? envHeaders : undefined],
    ["http_headers", Object.keys(headers).length ? headers : undefined],
    ["command", command],
    ["args", args.length ? args : undefined],
    ["env_vars", envVars.length ? envVars : undefined],
    ["startup_timeout_sec", server.timeout],
    ["enabled", server.enabled === false ? false : undefined],
  ];
  const table = `mcp_servers.${tomlKey(name)}`;
  const lines = [`[${table}]`];
  for (const [key, value] of fields) if (value !== undefined) lines.push(`${key} = ${tomlValue(value)}`);
  if (Object.keys(env).length) {
    lines.push("", `[${table}.env]`, ...Object.entries(env).map(([key, value]) => `${tomlKey(key)} = ${tomlValue(value)}`));
  }
  return lines.join("\n");
}

/**
 * Renders the Codex `mcp_servers` snapshot and checks that it parses.
 *
 * @param servers - All servers.
 */
function renderCodex(servers: Servers): string {
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
function renderOpencode(servers: Servers, current: string): string {
  const toEnv = (value: string) => value.replaceAll(REFERENCES, "{env:$1}");
  const mcp = Object.fromEntries(
    serversFor(servers, "opencode").map(([name, server]) => {
      const common = { enabled: server.enabled ?? true, timeout: server.timeout && server.timeout * 1000 };
      return [
        name,
        server.url
          ? { type: "remote", url: server.url, headers: mapValues(server.headers, toEnv), oauth: server.headers ? false : undefined, ...common }
          : { type: "local", command: [server.command, ...(server.args ?? [])], environment: mapValues(server.env, toEnv), ...common },
      ];
    }),
  );
  return formatJson({ ...JSON.parse(current), mcp });
}

/**
 * Renders Pi's shared MCP config.
 *
 * @param servers - All servers.
 */
function renderPi(servers: Servers): string {
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

async function main(check: boolean): Promise<void> {
  const servers = Bun.TOML.parse(await Bun.file(SOURCE).text()) as Servers;
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

await runMain(() => main(Bun.argv.includes("--check")));
