/**
 * Snapshots Claude Code's user settings and MCP servers into the repo and
 * restores them.
 *
 * - `dump` writes `~/.claude/settings.json` to `settings.json` and the
 *   `mcpServers` of `~/.claude.json` to `mcp-servers.json`, with the home
 *   prefix replaced by `${HOME}/`.
 * - `restore` writes both back; the rest of `~/.claude.json` (projects,
 *   caches, account state) stays untouched.
 *
 * Usage: `bun claude-config.ts dump|restore <snapshot dir>`
 */
import { join } from "node:path";
import { readText, writeAtomic } from "./lib/fs";
import { ok, runMain } from "./lib/log";
import { fromPortable, HOME, toPortable } from "./lib/paths";

/** Claude Code's global state, which holds the user-scope `mcpServers`. */
const STATE_PATH = join(HOME, ".claude.json");

/** Claude Code's user settings: hooks, permissions, plugins, env. */
const SETTINGS_PATH = join(HOME, ".claude/settings.json");

/**
 * Formats a value as JSON the way Claude Code writes it.
 *
 * @param value - Value to serialize.
 */
function formatJson(value: unknown): string {
  return `${JSON.stringify(value, null, 2)}\n`;
}

/**
 * Saves the live settings and MCP servers into the snapshot directory.
 *
 * @param snapshotDir - Directory for `settings.json` and `mcp-servers.json`.
 */
async function dump(snapshotDir: string): Promise<void> {
  const state = JSON.parse((await readText(STATE_PATH)) ?? "{}");
  const snapshots = {
    "mcp-servers.json": formatJson(state.mcpServers ?? {}),
    "settings.json": (await readText(SETTINGS_PATH)) ?? formatJson({}),
  };

  for (const [name, text] of Object.entries(snapshots)) {
    const path = join(snapshotDir, name);
    await Bun.write(path, toPortable(text));
    ok("Dumped", path);
  }
}

/**
 * Writes the snapshots back into the live files, replacing only
 * `mcpServers` inside `~/.claude.json`.
 *
 * @param snapshotDir - Directory with `settings.json` and `mcp-servers.json`.
 */
async function restore(snapshotDir: string): Promise<void> {
  const servers = JSON.parse(fromPortable(await Bun.file(join(snapshotDir, "mcp-servers.json")).text()));
  const state = JSON.parse((await readText(STATE_PATH)) ?? "{}");
  await writeAtomic(STATE_PATH, formatJson({ ...state, mcpServers: servers }));
  ok("Restored", STATE_PATH);

  const settings = fromPortable(await Bun.file(join(snapshotDir, "settings.json")).text());
  JSON.parse(settings); // Never leave Claude Code with invalid settings.
  await writeAtomic(SETTINGS_PATH, settings);
  ok("Restored", SETTINGS_PATH);
}

await runMain(async () => {
  const [command, snapshotDir] = Bun.argv.slice(2);
  if (command === "dump" && snapshotDir) await dump(snapshotDir);
  else if (command === "restore" && snapshotDir) await restore(snapshotDir);
  else throw new Error("Usage: bun claude-config.ts dump|restore <snapshot dir>");
});
