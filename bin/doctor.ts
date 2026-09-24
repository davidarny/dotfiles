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
import { readdir, readlink, realpath } from "node:fs/promises";
import { basename, dirname, join } from "node:path";
import { isSymlink, readText } from "./lib/fs";
import { fail, ok, runMain, step, summary } from "./lib/log";
import { DIRECTORY_LINKS, HOME, REPO, tilde } from "./lib/paths";
import { CANONICAL_SKILLS_DIR, HARNESS_SKILL_DIRS, listLocalSkills, readSkills } from "./lib/skills";

/** Label of the LaunchAgent that publishes MCP secrets to GUI apps (see the justfile). */
const LAUNCH_AGENT = "local.dotfiles.mcp-secrets-env";

/** The 1Password SSH agent socket that `env.zsh` and `~/.ssh/config` use. */
const SSH_AGENT_SOCKET = join(HOME, "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock");

/** A skill link in the global instructions, e.g. `skills/caveman/SKILL.md`. */
const SKILL_LINK = /skills\/([a-z0-9-]+)\/SKILL\.md/g;

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

/** The part of Claude Code's `~/.claude.json` that holds user-scope MCP servers. */
interface ClaudeState {
  mcpServers?: Record<string, McpServer>;
}

/** The part of Codex's `~/.codex/config.toml` that holds MCP servers. */
interface CodexConfig {
  mcp_servers?: Record<string, McpServer>;
}

/** The global Bun manifest, `~/.bun/install/global/package.json`. */
interface BunManifest {
  dependencies?: Record<string, string>;
}

/** yazi's `package.toml`. */
interface YaziPackage {
  plugin?: YaziPlugins;
}

/** The `[plugin]` table of yazi's `package.toml`. */
interface YaziPlugins {
  deps?: YaziDependency[];
}

/** One pinned yazi plugin, e.g. `use = "yazi-rs/plugins:git"`. */
interface YaziDependency {
  use: string;
}

/**
 * Reads and parses a JSON file.
 *
 * @param path - File to read.
 * @returns The parsed value, or `undefined` when the file does not exist.
 */
async function readJson<T>(path: string): Promise<T | undefined> {
  const text = await readText(path);
  return text === undefined ? undefined : (JSON.parse(text) as T);
}

/**
 * Reads and parses a TOML file.
 *
 * @param path - File to read.
 * @returns The parsed value, or `undefined` when the file does not exist.
 */
async function readToml<T>(path: string): Promise<T | undefined> {
  const text = await readText(path);
  return text === undefined ? undefined : (Bun.TOML.parse(text) as T);
}

/**
 * Lists every directory of the repo that holds tracked files, with all of its
 * ancestors. Stow only creates links in the matching home directories, so
 * these are the only places a stale repo link can be.
 */
async function trackedDirs(): Promise<string[]> {
  const dirs = new Set<string>(["."]);
  for (const file of (await $`git ls-files`.cwd(REPO).text()).split("\n")) {
    for (let dir = dirname(file); dir !== "."; dir = dirname(dir)) dirs.add(dir);
  }
  return [...dirs];
}

/**
 * Stow links from the repo are all in place and none are blocked by existing
 * files. A dry run of `stow` lists each missing link as `LINK:`.
 */
async function checkStowLinks(): Promise<CheckResult> {
  const { stdout, stderr } = await $`stow --no --verbose --no-folding --target=${HOME} .`.cwd(REPO).quiet().nothrow();
  const problems = `${stdout}${stderr}`
    .split("\n")
    .filter((line) => /^LINK|conflict|existing target/.test(line))
    .map((line) => `${line.trim()} → run just link`);

  return { label: "Stow links in place", problems };
}

/** No symlink into the repo points at a file that no longer exists. */
async function checkBrokenLinks(): Promise<CheckResult> {
  const repoName = `${basename(REPO)}/`;
  const problems: string[] = [];

  for (const dir of await trackedDirs()) {
    const entries = await readdir(join(HOME, dir), { withFileTypes: true }).catch(() => []);
    for (const entry of entries.filter((entry) => entry.isSymbolicLink())) {
      const path = join(HOME, dir, entry.name);
      // existsSync follows the link and, unlike Bun.file(), also accepts directories.
      if ((await readlink(path)).includes(repoName) && !existsSync(path)) {
        problems.push(`${tilde(path)} is broken → remove it or run just link`);
      }
    }
  }

  return { label: "No broken repo symlinks", problems };
}

/** Every directory in `DIRECTORY_LINKS` links to the repo as a whole. */
async function checkDirectoryLinks(): Promise<CheckResult> {
  const problems: string[] = [];
  for (const relativePath of DIRECTORY_LINKS) {
    const path = join(HOME, relativePath);
    const target = await realpath(path).catch(() => "");
    if (!(await isSymlink(path)) || target !== join(REPO, relativePath)) {
      problems.push(`${tilde(path)} is not a directory symlink → run just link`);
    }
  }

  return { label: "Config directories linked", problems };
}

/** Every variable from the secrets template has a non-empty resolved value. */
async function checkMcpSecrets(): Promise<CheckResult> {
  const label = "MCP secrets resolved";
  const secretsPath = join(HOME, ".config/mcp/mcp-secrets.env");
  const secrets = Bun.file(secretsPath);
  if (!(await secrets.exists())) {
    return { label, problems: [`${tilde(secretsPath)} is missing → run just mcp-secrets`] };
  }

  const exported = /^export ([A-Za-z_][A-Za-z0-9_]*)=(.*)$/gm;
  const template = await Bun.file(join(REPO, ".config/mcp/mcp-secrets.env.tpl")).text();
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
  const output = await $`brew bundle check --file=Brewfile --verbose --no-upgrade`.cwd(REPO).quiet().nothrow().text();
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
    readJson<ClaudeState>(join(HOME, ".claude.json")),
    readToml<CodexConfig>(join(HOME, ".codex/config.toml")),
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
 * Every skill that the global instructions (`AGENTS.md` and its
 * `references/`) link, the manifest lists, or the repo authors has a
 * `SKILL.md` in the canonical directory and in all harnesses.
 */
async function checkSkills(): Promise<CheckResult> {
  const referenced: string[] = [];
  for await (const path of new Bun.Glob("{AGENTS.md,references/*.md}").scan(join(REPO, ".agents"))) {
    const doc = await Bun.file(join(REPO, ".agents", path)).text();
    referenced.push(...[...doc.matchAll(SKILL_LINK)].map(([, name]) => name));
  }
  const listed = Object.keys(await readSkills(join(REPO, ".agents/skills.json")));
  const local = await listLocalSkills(join(REPO, ".agents/skills"));
  const skills = [...new Set([...referenced, ...listed, ...local])];

  const problems: string[] = [];
  for (const skill of skills) {
    for (const dir of [CANONICAL_SKILLS_DIR, ...HARNESS_SKILL_DIRS]) {
      if (!(await Bun.file(join(HOME, dir, skill, "SKILL.md")).exists())) {
        problems.push(`~/${dir}/${skill} is missing → run just skills-sync`);
      }
    }
  }

  return { label: `${skills.length} skills in all harnesses`, problems };
}

/**
 * Reads the tool names from `mise ls --json` output, an object keyed by tool.
 *
 * @param json - Command output; empty output means no tools.
 * @returns Tool names, or `undefined` when the output is not JSON.
 */
function miseToolNames(json: string): string[] | undefined {
  try {
    return Object.keys(JSON.parse(json || "{}"));
  } catch {
    return undefined;
  }
}

/** Every runtime pinned in the mise config is installed. */
async function checkMiseRuntimes(): Promise<CheckResult> {
  const label = "mise runtimes installed";
  const { stdout, exitCode } = await $`mise ls --missing --json`.cwd(HOME).quiet().nothrow();
  const missing = exitCode === 0 ? miseToolNames(stdout.toString()) : undefined;
  if (!missing) return { label, problems: ["mise ls --missing failed → run it to see why"] };
  return { label, problems: missing.map((tool) => `${tool} is missing → run just mise-install`) };
}

/** Every global Bun package in the stowed manifest is installed. */
async function checkBunPackages(): Promise<CheckResult> {
  const globalDir = join(HOME, ".bun/install/global");
  const manifest = await readJson<BunManifest>(join(globalDir, "package.json"));
  const problems: string[] = [];
  for (const name of Object.keys(manifest?.dependencies ?? {})) {
    if (!(await Bun.file(join(globalDir, "node_modules", name, "package.json")).exists())) {
      problems.push(`${name} is missing → run just bun-sync`);
    }
  }
  return { label: "Global Bun packages installed", problems };
}

/** The LaunchAgent that publishes MCP secrets to GUI apps is loaded. */
async function checkLaunchAgent(): Promise<CheckResult> {
  const { exitCode } = await $`launchctl print gui/${process.getuid!()}/${LAUNCH_AGENT}`.quiet().nothrow();
  return {
    label: "MCP secrets LaunchAgent loaded",
    problems: exitCode === 0 ? [] : [`${LAUNCH_AGENT} is not loaded → run just mcp-launchagent`],
  };
}

/** The 1Password SSH agent answers and offers keys. */
async function checkSshAgent(): Promise<CheckResult> {
  const label = "1Password SSH agent ready";
  // ssh-add -l exits 1 when the agent has no keys and 2 when it cannot reach the agent.
  const { exitCode } = await $`ssh-add -l`.env({ ...Bun.env, SSH_AUTH_SOCK: SSH_AGENT_SOCKET }).quiet().nothrow();
  if (exitCode === 0) return { label, problems: [] };
  if (exitCode === 1) {
    return { label, problems: ["the agent offers no keys → add keys to the vaults in ~/.config/1Password/ssh/agent.toml"] };
  }
  return { label, problems: ["the agent does not answer → enable it in 1Password, Settings, Developer"] };
}

/** gh is signed in, so it can clone and call the GitHub API. */
async function checkGhAuth(): Promise<CheckResult> {
  const { exitCode } = await $`gh auth status`.quiet().nothrow();
  return { label: "gh signed in", problems: exitCode === 0 ? [] : ["gh is not signed in → run gh auth login"] };
}

/** TPM is cloned, so tmux can load its plugins. */
async function checkTpm(): Promise<CheckResult> {
  const installed = await Bun.file(join(HOME, ".tmux/plugins/tpm/tpm")).exists();
  return {
    label: "TPM installed",
    problems: installed ? [] : ["~/.tmux/plugins/tpm is missing → start tmux once; tmux.conf installs it"],
  };
}

/** Every yazi plugin pinned in package.toml or authored in the repo is installed. */
async function checkYaziPlugins(): Promise<CheckResult> {
  const pkg = await readToml<YaziPackage>(join(REPO, ".config/yazi/package.toml"));
  const pinned = (pkg?.plugin?.deps ?? []).map(({ use }) => `${use.split(":").at(-1)}.yazi`);
  const authored = (await readdir(join(REPO, ".config/yazi/plugins"), { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);

  const problems: string[] = [];
  for (const plugin of [...pinned, ...authored]) {
    if (!existsSync(join(HOME, ".config/yazi/plugins", plugin))) {
      problems.push(`${plugin} is missing → run just yazi-plugins`);
    }
  }

  return { label: "yazi plugins installed", problems };
}

/** Every check, in report order. */
const CHECKS = [
  checkStowLinks,
  checkBrokenLinks,
  checkDirectoryLinks,
  checkMcpSecrets,
  checkLaunchAgent,
  checkBrewfile,
  checkMiseRuntimes,
  checkBunPackages,
  checkMcpCommands,
  checkSkills,
  checkSshAgent,
  checkGhAuth,
  checkTpm,
  checkYaziPlugins,
];

async function main(): Promise<void> {
  step("Dotfiles doctor");

  const results = await Promise.all(CHECKS.map((check) => check()));
  for (const { label, problems } of results) {
    if (problems.length) fail(label, problems);
    else ok(label);
  }

  const failed = results.filter(({ problems }) => problems.length).length;
  summary(failed ? `${failed} of ${results.length} checks failed` : `All ${results.length} checks passed`, failed === 0);
  process.exitCode = failed ? 1 : 0;
}

await runMain(main);
