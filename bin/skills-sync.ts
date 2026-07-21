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

const lock = (await Bun.file(path).json()) as SkillLock;
const skills = Object.entries(lock.skills);

function status(message: string) {
  Bun.spawnSync(["gum", "style", "--bold", message], {
    stdout: "inherit",
    stderr: "inherit",
  });
}

status(`Syncing ${skills.length} global skills`);

for (const [name, skill] of skills) {
  const task = Bun.spawn(
    [
      "gum",
      "spin",
      "--title",
      `Installing ${name}`,
      "--show-error",
      "--",
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

status("✓ Global skills synced");
