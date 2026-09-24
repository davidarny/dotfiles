/**
 * MCP servers as defined in `mcp/servers.toml`, the single source every
 * agent's MCP config is rendered from.
 */
import { join } from "node:path";
import { REPO } from "./paths";

/** Agents that get MCP servers. */
export type Agent = "claude" | "codex" | "opencode" | "pi";

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

/** Reads and parses `mcp/servers.toml`. */
export async function readServers(): Promise<Servers> {
  return Bun.TOML.parse(await Bun.file(SERVERS_PATH).text()) as Servers;
}
