/**
 * Snapshots of JSON settings files that agents rewrite themselves.
 *
 * Keys the user toggles often (effort, current model) stay on the machine: a
 * dump leaves them out, so switching them never changes the tracked snapshot,
 * and a restore keeps their live values.
 */
import { readText, writeAtomic } from "./fs";
import { fromPortable, toPortable } from "./paths";

/** A live JSON settings file and its tracked snapshot. */
export interface SettingsFile {
  /** Live file the agent reads, e.g. `~/.claude/settings.json`. */
  live: string;
  /** Tracked snapshot in the repo. */
  snapshot: string;
  /** Top-level keys toggled often; they never enter the snapshot. */
  localKeys: string[];
}

type Settings = Record<string, unknown>;

/**
 * Formats a value as JSON the way the agents write it.
 *
 * @param value - Value to serialize.
 */
export function formatJson(value: unknown): string {
  return `${JSON.stringify(value, null, 2)}\n`;
}

/**
 * Reads a JSON object from a file that may not exist.
 *
 * @param path - File to read; a missing file yields an empty object.
 */
export async function readJsonObject(path: string): Promise<Settings> {
  return JSON.parse((await readText(path)) ?? "{}");
}

/**
 * Writes the live settings into the snapshot without the local keys.
 *
 * @param file - Settings file to snapshot.
 */
export async function dumpSettings({ live, snapshot, localKeys }: SettingsFile): Promise<void> {
  const settings = await readJsonObject(live);
  for (const key of localKeys) delete settings[key];
  await Bun.write(snapshot, toPortable(formatJson(settings)));
}

/**
 * Replaces the live settings with the snapshot, keeping the live values of
 * the local keys.
 *
 * @param file - Settings file to restore.
 */
export async function restoreSettings({ live, snapshot, localKeys }: SettingsFile): Promise<void> {
  const settings: Settings = JSON.parse(fromPortable(await Bun.file(snapshot).text()));
  const current = await readJsonObject(live);
  for (const key of localKeys) {
    if (key in current) settings[key] = current[key];
  }
  await writeAtomic(live, formatJson(settings));
}
