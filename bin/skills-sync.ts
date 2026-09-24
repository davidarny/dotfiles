import { lstat, mkdir, readdir, readlink, symlink, unlink } from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";

interface InstalledSkill {
  source: string;
}

interface SkillLock {
  skills: Record<string, InstalledSkill>;
}

const agents = ["claude-code", "codex", "opencode", "pi"];
const path = process.argv[2];

if (!path) {
  throw new Error("Usage: bun skills-sync.ts <lockfile>");
}

const home = process.env.HOME!;
const canonicalDir = join(home, ".agents/skills");
const harnessDirs = [".claude/skills", ".codex/skills", ".pi/agent/skills", ".config/opencode/skills"];
// Locally authored skills live next to the manifest; external ones come from their source.
const localDir = join(dirname(resolve(path)), "skills");

// The CLI lockfile used to be a stow symlink into the repo; make it machine-local.
const cliLock = `${home}/.agents/.skill-lock.json`;
if ((await lstat(cliLock).catch(() => null))?.isSymbolicLink()) {
  await unlink(cliLock);
}

const lock = (await Bun.file(path).json()) as SkillLock;
const skills = Object.entries(lock.skills);
const localSkills = (await readdir(localDir, { withFileTypes: true }).catch(() => []))
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

function status(message: string) {
  console.log(message);
}

for (const name of localSkills) {
  if (name in lock.skills) {
    throw new Error(`Skill ${name} is both local and listed in ${path}`);
  }
}

// Point link at target with a relative symlink; refuse to replace anything but a symlink.
async function link(linkPath: string, target: string) {
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

status(`Syncing ${skills.length} global skills`);

for (const [name, skill] of skills) {
  const task = Bun.spawn(
    [
      "skills",
      "add",
      skill.source,
      "--global",
      "--agent",
      ...agents,
      "--skill",
      name,
      "--yes",
    ],
    { stdout: "inherit", stderr: "inherit" },
  );

  if (await task.exited) {
    throw new Error(`Failed to install skill: ${name}`);
  }

  status(`✓ ${name}`);
}

status(`Linking ${localSkills.length} local skills`);

for (const name of localSkills) {
  const canonical = join(canonicalDir, name);
  await link(canonical, join(localDir, name));

  for (const dir of harnessDirs) {
    await link(join(home, dir, name), canonical);
  }

  status(`✓ ${name}`);
}

status("✓ Global skills synced");
