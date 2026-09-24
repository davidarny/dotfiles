/**
 * Read-only health report for this machine's dotfiles setup.
 *
 * Every check only reads the filesystem or asks a tool for its status, and
 * suggests what to run to fix a problem. Checks run concurrently and are
 * reported in a fixed order. Exits with 1 when any check fails.
 *
 * Usage: `bun doctor.ts` (run from `just doctor`).
 */
import { $ } from "bun";
import { existsSync } from "node:fs";
import { lstat, readdir, readlink, realpath } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { fail, ok, step, summary } from "./lib/log";
import { canonicalSkillsDir, harnessSkillDirs, listLocalSkills, readSkills } from "./lib/skills";

/** A named check and the problems it found; no problems means it passed. */
interface CheckResult {
  /** What was verified, phrased as the healthy state. */
  label: string;
  /** One line per problem, each with a hint how to fix it. */
  problems: string[];
}

/** An MCP server entry as Claude Code and Codex store it. */
interface McpServer {
  /** Executable name or path; absent for HTTP servers. */
  command?: string;
  /** Codex: `false` for a registered but disabled server. */
  enabled?: boolean;
  /** Codex: working directory that relative commands resolve against. */
  cwd?: string;
}

const home = Bun.env.HOME!;
const repo = resolve(import.meta.dir, "..");

/**
 * Shortens a path under the home directory to `~/...` for display.
 *
 * @param path - Absolute path.
 */
function tilde(path: string): string {
  return path.startsWith(`${home}/`) ? `~${path.slice(home.length)}` : path;
}

/**
 * Reads and parses a JSON file.
 *
 * @param path - File to read.
 * @returns The parsed value, or `undefined` when the file does not exist.
 */
async function readJson<T>(path: string): Promise<T | undefined> {
  const file = Bun.file(path);
  return (await file.exists()) ? ((await file.json()) as T) : undefined;
}

/**
 * Reads and parses a TOML file.
 *
 * @param path - File to read.
 * @returns The parsed value, or `undefined` when the file does not exist.
 */
async function readToml<T>(path: string): Promise<T | undefined> {
  const file = Bun.file(path);
  return (await file.exists()) ? (Bun.TOML.parse(await file.text()) as T) : undefined;
}

/**
 * Lists every directory of the repo that holds tracked files, with all of its
 * ancestors. Stow only creates links in the matching home directories, so
 * these are the only places a stale repo link can be.
 */
async function trackedDirs(): Promise<string[]> {
  const dirs = new Set<string>(["."]);
  for (const file of (await $`git ls-files`.cwd(repo).text()).split("\n")) {
    for (let dir = dirname(file); dir !== "."; dir = dirname(dir)) dirs.add(dir);
  }
  return [...dirs];
}

/**
 * Stow links from the repo are all in place and none are blocked by existing
 * files. A dry run of `stow` lists each missing link as `LINK:`.
 */
async function checkStowLinks(): Promise<CheckResult> {
  const { stdout, stderr } = await $`stow --no --verbose --no-folding --target=${home} .`.cwd(repo).quiet().nothrow();
  const problems = `${stdout}${stderr}`
    .split("\n")
    .filter((line) => /^LINK|conflict|existing target/.test(line))
    .map((line) => `${line.trim()} → run just link`);

  return { label: "Stow links in place", problems };
}

/** No symlink into the repo points at a file that no longer exists. */
async function checkBrokenLinks(): Promise<CheckResult> {
  const repoName = `${basename(repo)}/`;
  const problems: string[] = [];

  for (const dir of await trackedDirs()) {
    const entries = await readdir(join(home, dir), { withFileTypes: true }).catch(() => []);
    for (const entry of entries.filter((entry) => entry.isSymbolicLink())) {
      const path = join(home, dir, entry.name);
      // existsSync follows the link and, unlike Bun.file(), also accepts directories.
      if ((await readlink(path)).includes(repoName) && !existsSync(path)) {
        problems.push(`${tilde(path)} is broken → remove it or run just link`);
      }
    }
  }

  return { label: "No broken repo symlinks", problems };
}

/** `~/.config/karabiner` links to the repo directory as a whole. */
async function checkKarabiner(): Promise<CheckResult> {
  const path = join(home, ".config/karabiner");
  const isLink = (await lstat(path).catch(() => null))?.isSymbolicLink();
  const target = await realpath(path).catch(() => "");
  const linked = isLink && target === join(repo, ".config/karabiner");

  return {
    label: "Karabiner config directory linked",
    problems: linked ? [] : ["~/.config/karabiner is not a directory symlink → run just link"],
  };
}

/** Every variable from the secrets template has a non-empty resolved value. */
async function checkMcpSecrets(): Promise<CheckResult> {
  const label = "MCP secrets resolved";
  const secretsPath = join(home, ".config/mcp/mcp-secrets.env");
  const secrets = Bun.file(secretsPath);
  if (!(await secrets.exists())) {
    return { label, problems: [`${tilde(secretsPath)} is missing → run just mcp-secrets`] };
  }

  const exported = /^export ([A-Za-z_][A-Za-z0-9_]*)=(.*)$/gm;
  const template = await Bun.file(join(repo, ".config/mcp/mcp-secrets.env.tpl")).text();
  const values = new Map(
    [...(await secrets.text()).matchAll(exported)].map(([, name, value]) => [name, value.replace(/^['"]|['"]$/g, "")]),
  );
  const problems = [...template.matchAll(exported)]
    .map(([, name]) => name)
    .filter((name) => !values.get(name)?.trim())
    .map((name) => `${name} is empty → run just mcp-secrets`);

  return { label, problems };
}

/** Everything in the Brewfile is installed. */
async function checkBrewfile(): Promise<CheckResult> {
  const output = await $`brew bundle check --file=Brewfile --verbose --no-upgrade`.cwd(repo).quiet().nothrow().text();
  const problems = output
    .split("\n")
    .filter((line) => line.startsWith("→"))
    .map((line) => `${line.slice(1).trim()} → run just brew-install`);

  return { label: "Brewfile dependencies installed", problems };
}

/**
 * Reports an MCP server whose command is missing.
 *
 * @param agent - Agent the server is registered in, for the message.
 * @param name - Server name.
 * @param server - Server entry.
 * @returns A problem line, or `undefined` when the command exists.
 */
function missingCommand(agent: string, name: string, { command }: McpServer): string | undefined {
  if (!command) return undefined;

  const found = command.includes("/") ? existsSync(command) : Bun.which(command) !== null;
  return found ? undefined : `${agent} ${name}: ${command} not found → reinstall it or run just ${agent}-restore`;
}

/** The command of every enabled Claude Code and Codex MCP server exists. */
async function checkMcpCommands(): Promise<CheckResult> {
  const [claude, codex] = await Promise.all([
    readJson<{ mcpServers?: Record<string, McpServer> }>(join(home, ".claude.json")),
    readToml<{ mcp_servers?: Record<string, McpServer> }>(join(home, ".codex/config.toml")),
  ]);

  const problems = [
    ...Object.entries(claude?.mcpServers ?? {}).map(([name, server]) => missingCommand("claude", name, server)),
    ...Object.entries(codex?.mcp_servers ?? {})
      // Disabled servers and app-relative commands are not ours to check.
      .filter(([, server]) => server.enabled !== false && !server.cwd)
      .map(([name, server]) => missingCommand("codex", name, server)),
  ].filter((problem) => problem !== undefined);

  return { label: "MCP server commands exist", problems };
}

/**
 * Every skill that AGENTS.md references, the manifest lists, or the repo
 * authors has a `SKILL.md` in the canonical directory and in all harnesses.
 */
async function checkSkills(): Promise<CheckResult> {
  const agentsDoc = await Bun.file(join(repo, ".agents/AGENTS.md")).text();
  const referenced = [...agentsDoc.matchAll(/skills\/([a-z0-9-]+)\/SKILL\.md/g)].map(([, name]) => name);
  const listed = Object.keys(await readSkills(join(repo, ".agents/skills.json")));
  const local = await listLocalSkills(join(repo, ".agents/skills"));
  const skills = [...new Set([...referenced, ...listed, ...local])];

  const problems: string[] = [];
  for (const skill of skills) {
    for (const dir of [canonicalSkillsDir, ...harnessSkillDirs]) {
      if (!(await Bun.file(join(home, dir, skill, "SKILL.md")).exists())) {
        problems.push(`~/${dir}/${skill} is missing → run just skills-sync`);
      }
    }
  }

  return { label: `${skills.length} skills in all harnesses`, problems };
}

/** TPM is cloned, so tmux can load its plugins. */
async function checkTpm(): Promise<CheckResult> {
  const installed = await Bun.file(join(home, ".tmux/plugins/tpm/tpm")).exists();
  return {
    label: "TPM installed",
    problems: installed ? [] : ["~/.tmux/plugins/tpm is missing → start tmux once; tmux.conf installs it"],
  };
}

/** Every yazi plugin pinned in package.toml or authored in the repo is installed. */
async function checkYaziPlugins(): Promise<CheckResult> {
  const pkg = await readToml<{ plugin?: { deps?: { use: string }[] } }>(join(repo, ".config/yazi/package.toml"));
  const pinned = (pkg?.plugin?.deps ?? []).map(({ use }) => `${use.split(":").at(-1)}.yazi`);
  const authored = (await readdir(join(repo, ".config/yazi/plugins"), { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);

  const problems: string[] = [];
  for (const plugin of [...pinned, ...authored]) {
    if (!existsSync(join(home, ".config/yazi/plugins", plugin))) {
      problems.push(`${plugin} is missing → run just yazi-plugins`);
    }
  }

  return { label: "yazi plugins installed", problems };
}

step("Dotfiles doctor");

const results = await Promise.all([
  checkStowLinks(),
  checkBrokenLinks(),
  checkKarabiner(),
  checkMcpSecrets(),
  checkBrewfile(),
  checkMcpCommands(),
  checkSkills(),
  checkTpm(),
  checkYaziPlugins(),
]);

for (const { label, problems } of results) {
  if (problems.length) fail(label, problems);
  else ok(label);
}

const failed = results.filter(({ problems }) => problems.length).length;
summary(failed ? `${failed} of ${results.length} checks failed` : `All ${results.length} checks passed`, failed === 0);
process.exitCode = failed ? 1 : 0;
