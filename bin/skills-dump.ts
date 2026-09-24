interface InstalledSkill {
  source: string;
}

interface SkillLock {
  skills: Record<string, InstalledSkill>;
}

// Usage: bun skills-dump.ts <lockfile> <manifest> < lockfile-before-command
// Applies only the skills added, removed, or re-sourced by the last command,
// so a machine with a partial lockfile never drops skills from the manifest.
const [lockPath, manifestPath] = process.argv.slice(2);

if (!lockPath || !manifestPath) {
  throw new Error("Usage: bun skills-dump.ts <lockfile> <manifest> < before");
}

async function readSkills(text: string) {
  return text.trim() ? ((JSON.parse(text) as SkillLock).skills ?? {}) : {};
}

async function readFile(path: string) {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : "";
}

const before = await readSkills(await Bun.stdin.text());
const after = await readSkills(await readFile(lockPath));
const manifestText = await readFile(manifestPath);
const skills = await readSkills(manifestText);

for (const name of Object.keys(before)) {
  if (!(name in after)) delete skills[name];
}

for (const [name, skill] of Object.entries(after)) {
  if (before[name]?.source !== skill.source) skills[name] = { source: skill.source };
}

const sorted = Object.fromEntries(
  Object.entries(skills).sort(([a], [b]) => a.localeCompare(b)),
);
const next = `${JSON.stringify({ skills: sorted }, null, 2)}\n`;

if (next !== manifestText) {
  await Bun.write(manifestPath, next);
  console.log(`✓ Updated ${manifestPath}`);
}
