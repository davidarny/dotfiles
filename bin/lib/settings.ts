/**
 * Snapshots of JSON settings files that agents rewrite themselves.
 *
 * Keys the user toggles often (effort, current model) stay on the machine: a
 * dump leaves them out, so switching them never changes the tracked snapshot,
 * and a restore keeps their live values.
 */
import { writeAtomic } from "./fs";
import { formatJson, readJson } from "./json";
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

/** Top-level settings keys and their values. */
type Settings = Record<string, unknown>;

/**
 * Reads a live settings file.
 *
 * @param path - File to read; a missing file yields no settings.
 */
async function readSettings(path: string): Promise<Settings> {
  return (await readJson<Settings>(path)) ?? {};
}

/**
 * Writes the live settings into the snapshot without the local keys.
 *
 * @param file - Settings file to snapshot.
 * @throws When the live file does not exist, so a fresh machine never blanks
 *   the tracked snapshot.
 */
export async function dumpSettings({ live, snapshot, localKeys }: SettingsFile): Promise<void> {
  const settings = await readJson<Settings>(live);
  if (!settings) throw new Error(`${live} does not exist; nothing to dump`);
  for (const key of localKeys) delete settings[key];
  await Bun.write(snapshot, toPortable(formatJson(settings)));
}

/**
 * Builds the live settings from the snapshot, keeping the live values of the
 * local keys. Separate from writing so a caller can validate every file
 * before it changes any.
 *
 * @param file - Settings file to restore.
 * @returns The new live content and the top-level keys it drops.
 */
export async function buildRestoredSettings({ live, snapshot, localKeys }: SettingsFile): Promise<RestoredSettings> {
  const settings = JSON.parse(fromPortable(await Bun.file(snapshot).text())) as Settings;
  const current = await readSettings(live);
  for (const key of localKeys) {
    if (key in current) settings[key] = current[key];
  }
  const dropped = Object.keys(current).filter((key) => !(key in settings));
  return { text: formatJson(settings), dropped };
}

/** Live settings rebuilt from a snapshot, ready to write. */
export interface RestoredSettings {
  /** New content of the live file. */
  text: string;
  /** Live top-level keys the snapshot does not have; restoring removes them. */
  dropped: string[];
}

/**
 * Replaces the live settings with the snapshot, keeping the live values of
 * the local keys.
 *
 * @param file - Settings file to restore.
 * @returns Top-level keys the restore removed, for the caller to report.
 */
export async function restoreSettings(file: SettingsFile): Promise<string[]> {
  const { text, dropped } = await buildRestoredSettings(file);
  await writeAtomic(file.live, text);
  return dropped;
}
