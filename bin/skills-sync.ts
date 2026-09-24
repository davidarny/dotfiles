/**
 * Restores global skills on this machine.
 *
 * - External skills listed in the manifest are installed with the Skills CLI,
 *   one call per source repository so each repository is cloned once. Skills
 *   already installed from the same source are skipped; `skills update`
 *   upgrades them.
 * - Locally authored skills in the repo are linked into `~/.agents/skills`.
 * - Every skill gets a symlink in all four harness skill directories.
 *
 * Usage: `bun skills-sync.ts <manifest>` (normally `.agents/skills.json`).
 */
import { $ } from "bun";
import { unlink } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { isSymlink, link } from "./lib/fs";
import { fail, ok, runMain, step, summary } from "./lib/log";
import { HOME, tilde } from "./lib/paths";
import { CANONICAL_SKILLS_DIR, HARNESS_SKILL_DIRS, listLocalSkills, readSkills, type Skills } from "./lib/skills";

/** Agents passed to `skills add --agent`. */
const AGENTS = ["claude-code", "codex", "opencode", "pi"];

/** Machine-local lockfile the Skills CLI keeps of installed skills. */
const CLI_LOCKFILE = join(HOME, ".agents/.skill-lock.json");

/** External skills split by whether they are already installed. */
interface Partition {
  /** Names installed from the expected source, with files on disk. */
  installed: string[];
  /** Skills still to install. */
  missing: Skills;
}

/** Outcome of installing the missing external skills. */
interface InstallResult {
  /** Names installed now. */
  installed: string[];
  /** Number of source repositories whose install failed. */
  failures: number;
}

/**
 * Path of a skill in the canonical directory.
 *
 * @param name - Skill name.
 */
function canonicalPath(name: string): string {
  return join(HOME, CANONICAL_SKILLS_DIR, name);
}

/**
 * Splits the manifest into skills already installed from the expected source
 * (the CLI lockfile records it and the files are on disk) and skills to install.
 *
 * @param external - Skills from the manifest.
 */
async function partitionInstalled(external: Skills): Promise<Partition> {
  const lock = await readSkills(CLI_LOCKFILE);
  const installed: string[] = [];
  const missing: Skills = {};

  for (const [name, skill] of Object.entries(external)) {
    const recorded = lock[name]?.source === skill.source;
    if (recorded && (await Bun.file(join(canonicalPath(name), "SKILL.md")).exists())) installed.push(name);
    else missing[name] = skill;
  }

  return { installed, missing };
}

/**
 * Groups skills by the repository they come from.
 *
 * @param skills - Skill name to source.
 * @returns Source repository to the skill names it provides.
 */
function groupBySource(skills: Skills): Map<string, string[]> {
  const groups = new Map<string, string[]>();
  for (const [name, { source }] of Object.entries(skills)) {
    groups.set(source, [...(groups.get(source) ?? []), name]);
  }
  return groups;
}

/**
 * Installs skills from one repository for all agents through the Skills CLI.
 * Its spinner output is hidden and shown only when the install fails.
 *
 * @param source - GitHub `owner/repo` to install from.
 * @param names - Skills to install from that repository.
 * @returns Whether the install succeeded.
 */
async function install(source: string, names: string[]): Promise<boolean> {
  const result = await $`skills add ${source} --global --agent ${AGENTS} --skill ${names} --yes`.quiet().nothrow();
  if (result.exitCode === 0) {
    ok(source, names.length > 3 ? `${names.length} skills` : names.join(", "));
    return true;
  }

  const output = Bun.stripANSI(`${result.stdout}${result.stderr}`).trim().split("\n");
  fail(`${names.join(", ")} from ${source}`, output.slice(-5));
  return false;
}

/**
 * Installs the missing external skills, one repository at a time: the Skills
 * CLI rewrites a shared lockfile on every install.
 *
 * @param missing - Skills to install.
 * @returns Names installed now, and how many repositories failed.
 */
async function installMissing(missing: Skills): Promise<InstallResult> {
  const installed: string[] = [];
  let failures = 0;

  for (const [source, names] of groupBySource(missing)) {
    if (await install(source, names)) installed.push(...names);
    else failures++;
  }

  return { installed, failures };
}

/**
 * Links every skill into all four harness directories. The Skills CLI skips
 * the links for agents that read `~/.agents/skills` themselves (Codex,
 * OpenCode); keeping all four lets every harness see every skill.
 *
 * @param names - Skills present in the canonical directory.
 */
async function linkHarnesses(names: string[]): Promise<void> {
  for (const name of names) {
    for (const dir of HARNESS_SKILL_DIRS) {
      await link(join(HOME, dir, name), canonicalPath(name));
    }
  }
}

async function main(manifestPath: string): Promise<void> {
  const external = await readSkills(manifestPath);
  const localDir = join(dirname(resolve(manifestPath)), "skills");
  const local = await listLocalSkills(localDir);

  const conflict = local.find((name) => name in external);
  if (conflict) throw new Error(`Skill ${conflict} is both local and listed in ${manifestPath}`);

  // The CLI lockfile used to be a stow symlink into the repo; make it machine-local.
  if (await isSymlink(CLI_LOCKFILE)) await unlink(CLI_LOCKFILE);

  step(`External skills (${Object.keys(external).length})`);
  const { installed: alreadyInstalled, missing } = await partitionInstalled(external);
  if (alreadyInstalled.length) ok(`${alreadyInstalled.length} already installed`, "update them with skills update");
  const { installed: newlyInstalled, failures } = await installMissing(missing);

  step(`Local skills (${local.length})`);
  for (const name of local) {
    await link(canonicalPath(name), join(localDir, name));
    ok(name, tilde(canonicalPath(name)));
  }

  const linked = [...alreadyInstalled, ...newlyInstalled, ...local];
  await linkHarnesses(linked);

  summary(
    failures ? `${failures} repositories failed to install` : `${linked.length} skills linked into ${HARNESS_SKILL_DIRS.length} harnesses`,
    failures === 0,
  );
  process.exitCode = failures ? 1 : 0;
}

await runMain(async () => {
  const manifestPath = Bun.argv[2];
  if (!manifestPath) throw new Error("Usage: bun skills-sync.ts <manifest>");
  await main(manifestPath);
});
