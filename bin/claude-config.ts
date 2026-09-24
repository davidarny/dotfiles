/**
 * Snapshots Claude Code's user settings into the repo and restores them
 * together with the MCP servers.
 *
 * - `dump` writes `~/.claude/settings.json` to `settings.json` (without the
 *   often toggled effort and model keys), with the home prefix replaced by
 *   `${HOME}/`. MCP servers come from `mcp/servers.toml` instead
 *   (`just mcp-sync` renders `mcp-servers.json`).
 * - `restore` writes the settings and `mcp-servers.json` back, keeping the
 *   live effort and model and the rest of `~/.claude.json` (projects, caches,
 *   account state), and lists live settings keys the snapshot removed.
 * - `restore-mcp` replaces only the MCP servers, leaving settings alone.
 *
 * Usage: `bun claude-config.ts dump|restore|restore-mcp <snapshot dir>`
 */
import { join } from "node:path";
import { writeAtomic } from "./lib/fs";
import { formatJson, readJson } from "./lib/json";
import { ok, runMain, warn } from "./lib/log";
import { fromPortable, HOME, tilde } from "./lib/paths";
import { buildRestoredSettings, dumpSettings, type SettingsFile } from "./lib/settings";

/** Claude Code's global state: projects, caches, account, and user-scope MCP servers. */
type ClaudeState = Record<string, unknown>;

/** Claude Code's global state file, which holds the user-scope `mcpServers`. */
const STATE_PATH = join(HOME, ".claude.json");

/** Settings keys that `/effort` and `/model` switch; they stay on the machine. */
const LOCAL_KEYS = ["effortLevel", "modelSettings", "model"];

/**
 * Claude Code's user settings file: hooks, permissions, plugins, env.
 *
 * @param snapshotDir - Directory with the tracked snapshots.
 */
function settingsFile(snapshotDir: string): SettingsFile {
  return {
    live: join(HOME, ".claude/settings.json"),
    snapshot: join(snapshotDir, "settings.json"),
    localKeys: LOCAL_KEYS,
  };
}

/**
 * Builds `~/.claude.json` with its `mcpServers` replaced by the snapshot.
 *
 * @param snapshotDir - Directory with `mcp-servers.json`.
 * @returns The new content of `~/.claude.json`.
 */
async function buildState(snapshotDir: string): Promise<string> {
  const servers: unknown = JSON.parse(fromPortable(await Bun.file(join(snapshotDir, "mcp-servers.json")).text()));
  const state = (await readJson<ClaudeState>(STATE_PATH)) ?? {};
  return formatJson({ ...state, mcpServers: servers });
}

/**
 * Saves the live settings into the snapshot directory.
 *
 * @param snapshotDir - Directory for `settings.json`.
 */
async function dump(snapshotDir: string): Promise<void> {
  const settings = settingsFile(snapshotDir);
  await dumpSettings(settings);
  ok("Dumped", tilde(settings.snapshot));
}

/**
 * Replaces only the MCP servers in `~/.claude.json`.
 *
 * @param snapshotDir - Directory with `mcp-servers.json`.
 */
async function restoreMcp(snapshotDir: string): Promise<void> {
  await writeAtomic(STATE_PATH, await buildState(snapshotDir));
  ok("Restored MCP servers", tilde(STATE_PATH));
}

/**
 * Writes the settings and MCP snapshots back. Both are read and validated
 * before either live file changes.
 *
 * @param snapshotDir - Directory with `settings.json` and `mcp-servers.json`.
 */
async function restore(snapshotDir: string): Promise<void> {
  const state = await buildState(snapshotDir);
  const settings = settingsFile(snapshotDir);
  const { text, dropped } = await buildRestoredSettings(settings);

  await writeAtomic(STATE_PATH, state);
  ok("Restored MCP servers", tilde(STATE_PATH));
  await writeAtomic(settings.live, text);
  ok("Restored", tilde(settings.live));
  if (dropped.length) warn("Removed live settings the snapshot does not have; dump first to keep them", dropped);
}

/**
 * Runs `dump`, `restore`, or `restore-mcp`.
 *
 * @param command - Subcommand from the command line.
 * @param snapshotDir - Directory with the tracked snapshots.
 */
async function main(command: string | undefined, snapshotDir: string | undefined): Promise<void> {
  if (!snapshotDir) throw new Error("Usage: bun claude-config.ts dump|restore|restore-mcp <snapshot dir>");
  if (command === "dump") await dump(snapshotDir);
  else if (command === "restore") await restore(snapshotDir);
  else if (command === "restore-mcp") await restoreMcp(snapshotDir);
  else throw new Error("Usage: bun claude-config.ts dump|restore|restore-mcp <snapshot dir>");
}

await runMain(() => main(Bun.argv[2], Bun.argv[3]));
