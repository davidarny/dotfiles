/**
 * Snapshots Pi's settings (`~/.pi/agent/settings.json`: packages, subagents,
 * theme, shell prefix) into the repo and restores them.
 *
 * The default provider, model, and thinking level are toggled often and the
 * changelog version is Pi's own state, so they stay on the machine.
 *
 * Usage: `bun pi-config.ts dump|restore <snapshot>`
 */
import { join } from "node:path";
import { ok, runMain, warn } from "./lib/log";
import { HOME, tilde } from "./lib/paths";
import { dumpSettings, restoreSettings, type SettingsFile } from "./lib/settings";

/** Keys that stay on the machine. */
const LOCAL_KEYS = ["defaultProvider", "defaultModel", "defaultThinkingLevel", "lastChangelogVersion"];

/**
 * Runs `dump` or `restore`.
 *
 * @param command - Subcommand from the command line.
 * @param snapshot - Tracked snapshot file.
 */
async function main(command: string | undefined, snapshot: string | undefined): Promise<void> {
  if (!snapshot || (command !== "dump" && command !== "restore")) {
    throw new Error("Usage: bun pi-config.ts dump|restore <snapshot>");
  }

  const settings: SettingsFile = { live: join(HOME, ".pi/agent/settings.json"), snapshot, localKeys: LOCAL_KEYS };
  if (command === "dump") {
    await dumpSettings(settings);
    ok("Dumped", tilde(snapshot));
    return;
  }
  const dropped = await restoreSettings(settings);
  ok("Restored", tilde(settings.live));
  if (dropped.length) warn("Removed live settings the snapshot does not have; dump first to keep them", dropped);
}

await runMain(() => main(Bun.argv[2], Bun.argv[3]));
