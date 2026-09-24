/**
 * Records the effect of the last `skills` command in the tracked manifest.
 *
 * Only skills that the command added, removed, or re-sourced are applied, so a
 * machine with a partial lockfile never drops skills from the manifest.
 *
 * Usage: `bun skills-dump.ts <lockfile> <manifest> < lockfile-before-command`
 * (called by the `skills` zsh wrapper in `.config/zsh/functions.zsh`).
 */
import { readText } from "./lib/fs";
import { ok, runMain } from "./lib/log";
import { parseSkills, readSkills, type Skills } from "./lib/skills";

/**
 * Serializes the manifest with skills sorted by name, so diffs stay small.
 *
 * @param skills - Skill name to source.
 */
function formatManifest(skills: Skills): string {
  const sorted = Object.fromEntries(Object.entries(skills).sort(([a], [b]) => a.localeCompare(b)));
  return `${JSON.stringify({ skills: sorted }, null, 2)}\n`;
}

/**
 * Applies the difference between two lockfile states to the manifest.
 *
 * @param manifest - Current manifest skills; updated in place.
 * @param before - Lockfile skills before the command.
 * @param after - Lockfile skills after the command.
 */
function applyChanges(manifest: Skills, before: Skills, after: Skills): void {
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
async function main(lockPath: string, manifestPath: string): Promise<void> {
  const manifestText = (await readText(manifestPath)) ?? "";
  const manifest = parseSkills(manifestText);
  applyChanges(manifest, parseSkills(await Bun.stdin.text()), await readSkills(lockPath));

  const next = formatManifest(manifest);
  if (next === manifestText) return;

  await Bun.write(manifestPath, next);
  ok("Updated skills manifest", manifestPath);
}

await runMain(async () => {
  const [lockPath, manifestPath] = Bun.argv.slice(2);
  if (!lockPath || !manifestPath) throw new Error("Usage: bun skills-dump.ts <lockfile> <manifest> < before");
  await main(lockPath, manifestPath);
});
