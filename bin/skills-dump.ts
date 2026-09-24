/**
 * Records the effect of the last `skills` command in the tracked manifest.
 *
 * Only skills that the command added, removed, or re-sourced are applied, so a
 * machine with a partial lockfile never drops skills from the manifest. A
 * lockfile that is missing or unreadable after the command leaves the manifest
 * alone instead of reading as "every skill was removed".
 *
 * Usage: `bun skills-dump.ts <lockfile> <manifest> < lockfile-before-command`
 * (called by the `skills` zsh wrapper in `.config/zsh/functions.zsh`).
 */
import { readText } from "./lib/fs";
import { formatJson } from "./lib/json";
import { ok, runMain } from "./lib/log";
import { parseSkills, type Skills } from "./lib/skills";

/** A Skills CLI lockfile or the manifest: a `skills` map at the top level. */
interface SkillsFile {
  skills?: unknown;
}

/**
 * Serializes the manifest with skills sorted by name, so diffs stay small.
 *
 * @param skills - Skill name to source.
 */
function formatManifest(skills: Skills): string {
  return formatJson({ skills: Object.fromEntries(Object.entries(skills).sort(([a], [b]) => a.localeCompare(b))) });
}

/**
 * Reads the lockfile the command left behind, strictly.
 *
 * @param path - CLI lockfile.
 * @throws When the lockfile is missing, is not JSON, or has no `skills` map.
 */
async function readLockfile(path: string): Promise<Skills> {
  const text = await readText(path);
  const parsed: SkillsFile | undefined = text === undefined ? undefined : JSON.parse(text);
  if (!parsed || typeof parsed.skills !== "object" || parsed.skills === null) {
    throw new Error(`${path} is missing or has no skills; the manifest is left as is`);
  }
  return parsed.skills as Skills;
}

/**
 * Applies the difference between two lockfile states to the manifest.
 *
 * @param manifest - Current manifest skills; updated in place.
 * @param before - Lockfile skills before the command.
 * @param after - Lockfile skills after the command.
 */
export function applyChanges(manifest: Skills, before: Skills, after: Skills): void {
  for (const name of Object.keys(before)) {
    if (!(name in after)) delete manifest[name];
  }

  for (const [name, { source }] of Object.entries(after)) {
    if (before[name]?.source !== source) manifest[name] = { source };
  }
}

/**
 * Updates the manifest from the lockfile states before (stdin) and after the
 * last command.
 *
 * @param lockPath - CLI lockfile after the command.
 * @param manifestPath - Tracked manifest to update.
 */
async function main(lockPath: string | undefined, manifestPath: string | undefined): Promise<void> {
  if (!lockPath || !manifestPath) throw new Error("Usage: bun skills-dump.ts <lockfile> <manifest> < before");
  const after = await readLockfile(lockPath);
  const manifestText = (await readText(manifestPath)) ?? "";
  const manifest = parseSkills(manifestText);
  applyChanges(manifest, parseSkills(await Bun.stdin.text()), after);

  const next = formatManifest(manifest);
  if (next === manifestText) return;

  await Bun.write(manifestPath, next);
  ok("Updated skills manifest", manifestPath);
}

// Tests import applyChanges; only a direct run reads stdin and writes the manifest.
if (import.meta.main) await runMain(() => main(Bun.argv[2], Bun.argv[3]));
