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

/**
 * Checks that a value is a table of strings.
 *
 * @param value - Value to check.
 */
function isStringTable(value: unknown): boolean {
  return typeof value === "object" && value !== null && Object.values(value).every((item) => typeof item === "string");
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

  if (Boolean(server.command) === Boolean(server.url)) problems.push("needs exactly one of command or url");
  const agents = server.agents;
  if (agents !== undefined && !(Array.isArray(agents) && agents.every((agent) => ALL_AGENTS.includes(agent)))) {
    problems.push(`agents must be a list of ${ALL_AGENTS.join(", ")}`);
  }
  for (const key of ["env", "headers"]) {
    if (server[key] !== undefined && !isStringTable(server[key])) problems.push(`${key} values must be strings`);
  }
  return problems;
}

/**
 * Parses and validates `mcp/servers.toml` content.
 *
 * @param text - TOML source.
 * @throws When an entry has an unknown field, no or both of `command` and
 *   `url`, an unknown agent, or a non-string `env` or `headers` value.
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
