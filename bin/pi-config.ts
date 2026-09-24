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
import { ok, runMain } from "./lib/log";
import { HOME } from "./lib/paths";
import { dumpSettings, restoreSettings, type SettingsFile } from "./lib/settings";

/** Keys that stay on the machine. */
const LOCAL_KEYS = ["defaultProvider", "defaultModel", "defaultThinkingLevel", "lastChangelogVersion"];

await runMain(async () => {
  const [command, snapshot] = Bun.argv.slice(2);
  if (!snapshot || (command !== "dump" && command !== "restore")) {
    throw new Error("Usage: bun pi-config.ts dump|restore <snapshot>");
  }

  const settings: SettingsFile = { live: join(HOME, ".pi/agent/settings.json"), snapshot, localKeys: LOCAL_KEYS };
  if (command === "dump") {
    await dumpSettings(settings);
    ok("Dumped", snapshot);
  } else {
    await restoreSettings(settings);
    ok("Restored", settings.live);
  }
});
