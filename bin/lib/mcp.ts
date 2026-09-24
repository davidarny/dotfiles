/**
 * MCP servers as defined in `mcp/servers.toml`, the single source every
 * agent's MCP config is rendered from.
 */
import { join } from "node:path";
import { REPO } from "./paths";

/** Agents that get MCP servers. */
export type Agent = "claude" | "codex" | "opencode" | "pi";

/** Every agent, the default for a server without `agents`. */
export const ALL_AGENTS: Agent[] = ["claude", "codex", "opencode", "pi"];

/** One server in `mcp/servers.toml`; the file header documents each field. */
export interface Server {
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
export type Servers = Record<string, Server>;

/** The source file. */
export const SERVERS_PATH = join(REPO, "mcp/servers.toml");

/** Fields a server may have, so a misspelled key fails instead of being ignored. */
const FIELDS = new Set(["agents", "command", "args", "url", "env", "headers", "timeout", "enabled"]);

/** Fields that only a local (`command`) server may have. */
const LOCAL_FIELDS = ["args", "env"];

/** Fields that only a remote (`url`) server may have. */
const REMOTE_FIELDS = ["headers"];

/** Fields whose values may reference secrets as `${VAR}`; every agent resolves them. */
const SECRET_FIELDS = new Set(["env", "headers"]);

/**
 * Checks that a value is a table of strings.
 *
 * @param value - Value to check.
 */
function isStringTable(value: unknown): boolean {
  return typeof value === "object" && value !== null && !Array.isArray(value) && Object.values(value).every((item) => typeof item === "string");
}

/**
 * Checks that a value is a list of strings.
 *
 * @param value - Value to check.
 */
function isStringList(value: unknown): boolean {
  return Array.isArray(value) && value.every((item) => typeof item === "string");
}

/**
 * Lists the field names that hold a `${VAR}` reference outside `env` and
 * `headers`, where Codex and OpenCode would pass it through literally.
 *
 * @param server - Parsed entry.
 */
function misplacedReferences(server: Record<string, unknown>): string[] {
  return Object.entries(server)
    .filter(([key, value]) => !SECRET_FIELDS.has(key) && JSON.stringify(value).includes("${"))
    .map(([key]) => key);
}

/**
 * Lists what is wrong with one server entry.
 *
 * @param server - Parsed entry.
 * @returns One message per problem; empty when the entry is valid.
 */
function serverProblems(server: Record<string, unknown>): string[] {
  const problems = Object.keys(server)
    .filter((key) => !FIELDS.has(key))
    .map((key) => `unknown field ${key}`);

  /**
   * Records a problem when a condition does not hold.
   *
   * @param valid - The condition.
   * @param message - Problem to record otherwise.
   */
  function check(valid: boolean, message: string): void {
    if (!valid) problems.push(message);
  }

  const isLocal = typeof server.command === "string" && server.command !== "";
  const isRemote = typeof server.url === "string" && server.url !== "";
  check(isLocal !== isRemote, "needs exactly one of command or url, as a non-empty string");
  for (const field of isRemote ? LOCAL_FIELDS : isLocal ? REMOTE_FIELDS : []) {
    check(server[field] === undefined, `${field} does not apply to a ${isRemote ? "url" : "command"} server`);
  }

  const { args, env, headers, timeout, enabled, agents } = server;
  check(args === undefined || isStringList(args), "args must be a list of strings");
  check(env === undefined || isStringTable(env), "env values must be strings");
  check(headers === undefined || isStringTable(headers), "headers values must be strings");
  check(timeout === undefined || (typeof timeout === "number" && timeout > 0), "timeout must be a positive number of seconds");
  check(enabled === undefined || typeof enabled === "boolean", "enabled must be true or false");
  const validAgents = Array.isArray(agents) && agents.length > 0 && agents.every((agent) => ALL_AGENTS.includes(agent));
  check(agents === undefined || validAgents, `agents must be a non-empty list of ${ALL_AGENTS.join(", ")}`);

  const references = misplacedReferences(server);
  check(!references.length, `\${VAR} works only in env and headers, not in ${references.join(", ")}`);
  return problems;
}

/**
 * Parses and validates `mcp/servers.toml` content.
 *
 * @param text - TOML source.
 * @throws When an entry has an unknown field or a field of the wrong type, no
 *   or both of `command` and `url`, a field that does not apply to its kind of
 *   server, an empty or unknown agent list, or a `${VAR}` outside `env` and
 *   `headers`.
 */
export function parseServers(text: string): Servers {
  const servers = Bun.TOML.parse(text) as Record<string, Record<string, unknown>>;
  const problems = Object.entries(servers).flatMap(([name, server]) =>
    serverProblems(server).map((problem) => `${name}: ${problem}`),
  );
  if (problems.length) throw new Error(`Invalid mcp/servers.toml: ${problems.join("; ")}`);
  return servers as Servers;
}

/** Reads, parses, and validates `mcp/servers.toml`. */
export async function readServers(): Promise<Servers> {
  return parseServers(await Bun.file(SERVERS_PATH).text());
}
