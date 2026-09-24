import { readdir } from "node:fs/promises";
import { readText } from "./fs";

/** Where a skill comes from, as the Skills CLI records it. */
export interface SkillSource {
  /** GitHub `owner/repo` that `skills add` installs the skill from. */
  source: string;
}

/** Skill name to its source. */
export type Skills = Record<string, SkillSource>;

/** Canonical skills directory, relative to `$HOME`. Every harness links here. */
export const CANONICAL_SKILLS_DIR = ".agents/skills";

/** Skill directories of the four harnesses, relative to `$HOME`. */
export const HARNESS_SKILL_DIRS = [
  ".claude/skills",
  ".codex/skills",
  ".pi/agent/skills",
  ".config/opencode/skills",
];

/**
 * Parses the skill map shared by the tracked manifest (`.agents/skills.json`)
 * and the Skills CLI lockfile (`~/.agents/.skill-lock.json`).
 *
 * @param text - JSON content; empty text yields no skills.
 */
export function parseSkills(text: string): Skills {
  return text.trim() ? (JSON.parse(text).skills ?? {}) : {};
}

/**
 * Reads the skill map from a manifest or lockfile.
 *
 * @param path - JSON file to read; a missing file yields no skills.
 */
export async function readSkills(path: string): Promise<Skills> {
  return parseSkills((await readText(path)) ?? "");
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
