import { readdir } from "node:fs/promises";

/** Where a skill comes from, as the Skills CLI records it. */
export interface SkillSource {
  /** GitHub `owner/repo` that `skills add` installs the skill from. */
  source: string;
}

/**
 * Shape shared by the tracked manifest (`.agents/skills.json`) and the Skills
 * CLI lockfile (`~/.agents/.skill-lock.json`): skill name to its source.
 */
export interface SkillManifest {
  skills: Record<string, SkillSource>;
}

/** Canonical skills directory, relative to `$HOME`. Every harness links here. */
export const canonicalSkillsDir = ".agents/skills";

/** Skill directories of the four harnesses, relative to `$HOME`. */
export const harnessSkillDirs = [
  ".claude/skills",
  ".codex/skills",
  ".pi/agent/skills",
  ".config/opencode/skills",
];

/**
 * Reads the skill map from a manifest or lockfile.
 *
 * @param path - JSON file to read; a missing or empty file yields no skills.
 * @returns Skill name to source.
 */
export async function readSkills(path: string): Promise<Record<string, SkillSource>> {
  const file = Bun.file(path);
  if (!(await file.exists())) return {};

  const text = await file.text();
  return text.trim() ? ((JSON.parse(text) as SkillManifest).skills ?? {}) : {};
}

/**
 * Lists locally authored skills: the subdirectories of the repo's
 * `.agents/skills`, which have no external source.
 *
 * @param dir - Directory that holds the local skills.
 * @returns Skill names, sorted.
 */
export async function listLocalSkills(dir: string): Promise<string[]> {
  const entries = await readdir(dir, { withFileTypes: true }).catch(() => []);
  return entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}
