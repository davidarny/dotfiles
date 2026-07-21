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

for (const [name, skill] of Object.entries(lock.skills)) {
  console.log(`Installing ${name}`);

  const task = Bun.spawn(
    ["skills", "add", skill.source, "--global", "--agent", ...agents, "--skill", name, "--yes"],
    { stdout: "ignore", stderr: "inherit" },
  );

  if (await task.exited) {
    throw new Error(`Failed to install skill: ${name}`);
  }
}
