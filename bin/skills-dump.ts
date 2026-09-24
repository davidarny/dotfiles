/**
 * Records the effect of the last `skills` command in the tracked manifest.
 *
 * Only skills that the command added, removed, or re-sourced are applied, so a
 * machine with a partial lockfile never drops skills from the manifest.
 *
 * Usage: `bun skills-dump.ts <lockfile> <manifest> < lockfile-before-command`
 * (called by the `skills` zsh wrapper in `.config/zsh/functions.zsh`).
 */
import { ok } from "./lib/log";
import type { SkillSource } from "./lib/skills";
import { readSkills } from "./lib/skills";

const [lockPath, manifestPath] = Bun.argv.slice(2);

if (!lockPath || !manifestPath) {
  throw new Error("Usage: bun skills-dump.ts <lockfile> <manifest> < before");
}

/**
 * Parses a lockfile snapshot passed as text.
 *
 * @param text - Lockfile content; empty when the lockfile did not exist yet.
 * @returns Skill name to source.
 */
function parseSkills(text: string): Record<string, SkillSource> {
  return text.trim() ? (JSON.parse(text).skills ?? {}) : {};
}

/**
 * Serializes the manifest with skills sorted by name, so diffs stay small.
 *
 * @param skills - Skill name to source.
 */
function formatManifest(skills: Record<string, SkillSource>): string {
  const sorted = Object.fromEntries(Object.entries(skills).sort(([a], [b]) => a.localeCompare(b)));
  return `${JSON.stringify({ skills: sorted }, null, 2)}\n`;
}

const before = parseSkills(await Bun.stdin.text());
const after = await readSkills(lockPath);
const manifestFile = Bun.file(manifestPath);
const manifestText = (await manifestFile.exists()) ? await manifestFile.text() : "";
const skills = parseSkills(manifestText);

for (const name of Object.keys(before)) {
  if (!(name in after)) delete skills[name];
}

for (const [name, skill] of Object.entries(after)) {
  if (before[name]?.source !== skill.source) skills[name] = { source: skill.source };
}

const next = formatManifest(skills);
if (next !== manifestText) {
  await Bun.write(manifestPath, next);
  ok("Updated skills manifest", manifestPath);
}
