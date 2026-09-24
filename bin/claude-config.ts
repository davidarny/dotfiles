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
 *   account state).
 *
 * Usage: `bun claude-config.ts dump|restore <snapshot dir>`
 */
import { join } from "node:path";
import { writeAtomic } from "./lib/fs";
import { ok, runMain } from "./lib/log";
import { fromPortable, HOME } from "./lib/paths";
import { dumpSettings, formatJson, readJsonObject, restoreSettings, type SettingsFile } from "./lib/settings";

/** Claude Code's global state, which holds the user-scope `mcpServers`. */
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
 * Saves the live settings into the snapshot directory.
 *
 * @param snapshotDir - Directory for `settings.json`.
 */
async function dump(snapshotDir: string): Promise<void> {
  const settings = settingsFile(snapshotDir);
  await dumpSettings(settings);
  ok("Dumped", settings.snapshot);
}

/**
 * Writes the snapshots back into the live files, replacing only
 * `mcpServers` inside `~/.claude.json`.
 *
 * @param snapshotDir - Directory with `settings.json` and `mcp-servers.json`.
 */
async function restore(snapshotDir: string): Promise<void> {
  const servers = JSON.parse(fromPortable(await Bun.file(join(snapshotDir, "mcp-servers.json")).text()));
  const state = await readJsonObject(STATE_PATH);
  await writeAtomic(STATE_PATH, formatJson({ ...state, mcpServers: servers }));
  ok("Restored", STATE_PATH);

  const settings = settingsFile(snapshotDir);
  await restoreSettings(settings);
  ok("Restored", settings.live);
}

await runMain(async () => {
  const [command, snapshotDir] = Bun.argv.slice(2);
  if (command === "dump" && snapshotDir) await dump(snapshotDir);
  else if (command === "restore" && snapshotDir) await restore(snapshotDir);
  else throw new Error("Usage: bun claude-config.ts dump|restore <snapshot dir>");
});
