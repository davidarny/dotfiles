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
import { lstat, mkdir, readlink, symlink, unlink } from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";
import { fail, ok, step, summary } from "./lib/log";
import type { SkillSource } from "./lib/skills";
import { canonicalSkillsDir, harnessSkillDirs, listLocalSkills, readSkills } from "./lib/skills";

/** Agents passed to `skills add --agent`. */
const agents = ["claude-code", "codex", "opencode", "pi"];

const home = Bun.env.HOME!;
const manifestPath = Bun.argv[2];

if (!manifestPath) {
  throw new Error("Usage: bun skills-sync.ts <manifest>");
}

/**
 * Makes `linkPath` a relative symlink to `target`.
 *
 * An up-to-date link is left alone and a symlink pointing elsewhere is
 * replaced. Anything that is not a symlink is user data, so the sync stops
 * instead of overwriting it.
 *
 * @param linkPath - Where the symlink should live.
 * @param target - Absolute path the symlink should resolve to.
 */
async function link(linkPath: string, target: string): Promise<void> {
  const expected = relative(dirname(linkPath), target);
  const current = await lstat(linkPath).catch(() => null);

  if (current?.isSymbolicLink()) {
    if ((await readlink(linkPath)) === expected) return;
    await unlink(linkPath);
  } else if (current) {
    throw new Error(`Refusing to replace ${linkPath}: not a symlink; move it away and rerun`);
  }

  await mkdir(dirname(linkPath), { recursive: true });
  await symlink(expected, linkPath);
}

/**
 * Checks whether a skill is already installed from the expected source: the
 * CLI lockfile records that source and the skill's files are on disk.
 *
 * @param name - Skill name.
 * @param source - Source the manifest expects.
 * @param lock - Skills recorded in the CLI lockfile.
 */
async function isInstalled(name: string, source: string, lock: Record<string, SkillSource>): Promise<boolean> {
  if (lock[name]?.source !== source) return false;
  return Bun.file(join(home, canonicalSkillsDir, name, "SKILL.md")).exists();
}

/**
 * Groups skills by the repository they come from.
 *
 * @param skills - Skill name to source.
 * @returns Source repository to the skill names it provides.
 */
function groupBySource(skills: Record<string, SkillSource>): Map<string, string[]> {
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
  const result = await $`skills add ${source} --global --agent ${agents} --skill ${names} --yes`.quiet().nothrow();
  if (result.exitCode === 0) {
    ok(source, names.length > 3 ? `${names.length} skills` : names.join(", "));
    return true;
  }

  const output = Bun.stripANSI(`${result.stdout}${result.stderr}`).trim().split("\n");
  fail(`${names.join(", ")} from ${source}`, output.slice(-5));
  return false;
}

/** Machine-local lockfile the Skills CLI keeps of installed skills. */
const cliLockfile = join(home, ".agents/.skill-lock.json");

/**
 * The CLI lockfile used to be a stow symlink into the repo. Drop such a link
 * so the CLI writes a machine-local file instead.
 */
async function detachCliLockfile(): Promise<void> {
  if ((await lstat(cliLockfile).catch(() => null))?.isSymbolicLink()) {
    await unlink(cliLockfile);
  }
}

const external = await readSkills(manifestPath);
const localDir = join(dirname(resolve(manifestPath)), "skills");
const local = await listLocalSkills(localDir);

for (const name of local) {
  if (name in external) {
    throw new Error(`Skill ${name} is both local and listed in ${manifestPath}`);
  }
}

await detachCliLockfile();

const lock = await readSkills(cliLockfile);
const installed: string[] = [];
const missing: Record<string, SkillSource> = {};
for (const [name, skill] of Object.entries(external)) {
  if (await isInstalled(name, skill.source, lock)) installed.push(name);
  else missing[name] = skill;
}

const sources = groupBySource(missing);
step(`External skills (${Object.keys(external).length})`);
if (installed.length) ok(`${installed.length} already installed`, "update them with skills update");

// One at a time: the Skills CLI rewrites a shared lockfile on every install.
let failures = 0;
for (const [source, names] of sources) {
  if (await install(source, names)) installed.push(...names);
  else failures++;
}

step(`Local skills (${local.length})`);
for (const name of local) {
  await link(join(home, canonicalSkillsDir, name), join(localDir, name));
  ok(name, `~/${canonicalSkillsDir}/${name}`);
}

// The Skills CLI skips harness links for agents that read ~/.agents/skills
// themselves (Codex, OpenCode); keep all four so every harness sees every skill.
const linked = [...installed, ...local];
for (const name of linked) {
  for (const dir of harnessSkillDirs) {
    await link(join(home, dir, name), join(home, canonicalSkillsDir, name));
  }
}

summary(
  failures ? `${failures} repositories failed to install` : `${linked.length} skills linked into ${harnessSkillDirs.length} harnesses`,
  failures === 0,
);
process.exitCode = failures ? 1 : 0;
