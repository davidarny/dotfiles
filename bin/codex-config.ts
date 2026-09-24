/**
 * Splits `~/.codex/config.toml` into tracked snapshots and machine-local entries.
 *
 * - `dump` writes the portable settings to `settings.toml`, with the home
 *   prefix replaced by `${HOME}/`. MCP servers come from `mcp/servers.toml`
 *   instead (`just mcp-sync` renders `mcp-servers.toml`).
 * - `restore` rebuilds the live config from `settings.toml`,
 *   `mcp-servers.toml`, and the entries that stay on this machine, and lists
 *   live settings the snapshot removed.
 * - `restore-mcp` replaces only the MCP servers, keeping every other entry.
 *
 * The file is split into text blocks instead of parsed and re-serialized, so
 * comments, key order, and formatting survive a round trip. `dump` refuses to
 * write a snapshot when the blocks do not add up to the same data as the live
 * file.
 *
 * Usage: `bun codex-config.ts dump|restore|restore-mcp <config.toml> <snapshot dir>`
 */
import { readText, writeAtomic } from "./lib/fs";
import { canonicalJson } from "./lib/json";
import { ok, runMain, warn } from "./lib/log";
import { fromPortable, tilde, toPortable } from "./lib/paths";

/**
 * A top-level key or a table of the TOML file, kept as its original lines
 * together with the comments right above it.
 */
interface Block {
  /** Dotted path of the table or key with quotes removed, e.g. `mcp_servers.fff.env` or `model`. */
  path: string;
  /** Whether the block is a table (`[...]` or `[[...]]`) rather than a top-level key. */
  isTable: boolean;
  /** Source lines, including leading comments and blank lines. */
  lines: string[];
}

/** A config parsed into blocks, split the way TOML requires them ordered. */
interface Config {
  /** Top-level assignments; TOML needs them before the first table. */
  top: Block[];
  /** Tables, including array tables. */
  tables: Block[];
}

/** Where a line leaves off: an open multi-line string or open brackets carry over to the next line. */
interface ScanState {
  /** Delimiter that closes an open multi-line string (`"""` or `'''`), or empty. */
  string: string;
  /** Open `[` and `{` outside strings, e.g. inside a multi-line array. */
  depth: number;
}

/**
 * Where a block belongs: the settings snapshot, the MCP snapshot, or this
 * machine only.
 */
type Kind = "settings" | "mcp" | "local";

/**
 * Top-level keys that stay on the machine: machine paths, local proxy URLs,
 * and the model and effort, which the user switches often (as for Claude Code
 * and Pi).
 */
const LOCAL_KEYS = new Set([
  "model",
  "model_reasoning_effort",
  "notify",
  "model_catalog_json",
  "openai_base_url",
  "experimental_realtime_ws_base_url",
]);

/** Tables with machine paths, trust lists, account ids, or UI state. */
const LOCAL_TABLES =
  /^(marketplaces|projects|shell_environment_policy|desktop\.daybreak-enabled|tui\.model_availability_nux)(\.|$)/;

/** MCP servers the Codex app writes itself, with app versions and home paths inside. */
const APP_MCP_SERVERS = /^mcp_servers\.(node_repl|computer-use)(\.|$)/;

/** All MCP server tables. */
const MCP_SERVERS = /^mcp_servers(\.|$)/;

/** A table header line, capturing what is between the brackets. */
const HEADER = /^\s*\[\[?(.+?)\]\]?\s*(#.*)?$/;

/**
 * Decides which snapshot a block belongs to. A dotted top-level key such as
 * `projects."/repo".trust_level` belongs where its table would.
 *
 * @param block - A top-level key or a table.
 */
function kind({ path, isTable }: Block): Kind {
  if (!isTable && LOCAL_KEYS.has(path)) return "local";
  if (APP_MCP_SERVERS.test(path) || LOCAL_TABLES.test(path)) return "local";
  return MCP_SERVERS.test(path) ? "mcp" : "settings";
}

/**
 * Reads a TOML key or table name into its dotted path, removing quotes of
 * either kind: `mcp_servers.'node_repl'` and `mcp_servers."node_repl"` both
 * become `mcp_servers.node_repl`.
 *
 * @param source - Key text before `=`, or the text between table brackets.
 */
function keyPath(source: string): string {
  const segments: string[] = [];
  let segment = "";
  for (let i = 0; i < source.length; i++) {
    const char = source[i];
    if (char === '"' || char === "'") {
      const end = source.indexOf(char, i + 1);
      segment += source.slice(i + 1, end === -1 ? undefined : end);
      i = end === -1 ? source.length : end;
    } else if (char === ".") {
      segments.push(segment.trim());
      segment = "";
    } else {
      segment += char;
    }
  }
  segments.push(segment.trim());
  return segments.join(".");
}

/**
 * Finds the `=` of a key line, outside quoted key segments.
 *
 * @param line - A line that starts a key assignment.
 * @returns The index of `=`, or -1 when the line has none.
 */
function assignmentIndex(line: string): number {
  let quote = "";
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (quote) {
      if (char === quote) quote = "";
    } else if (char === '"' || char === "'") {
      quote = char;
    } else if (char === "=") {
      return i;
    }
  }
  return -1;
}

/**
 * Advances the scan state over one line: tracks strings (so brackets, `#`,
 * and `=` inside them do not count), multi-line strings, and bracket depth.
 *
 * @param line - Source line.
 * @param state - State before the line; updated in place.
 */
function scanLine(line: string, state: ScanState): void {
  for (let i = 0; i < line.length; i++) {
    if (state.string) {
      if (state.string === '"""' && line[i] === "\\") i++;
      else if (line.startsWith(state.string, i)) {
        i += 2;
        state.string = "";
      }
      continue;
    }
    const char = line[i];
    if (char === "#") return;
    if (line.startsWith('"""', i) || line.startsWith("'''", i)) {
      state.string = line.slice(i, i + 3);
      i += 2;
    } else if (char === '"' || char === "'") {
      for (i++; i < line.length && line[i] !== char; i++) if (char === '"' && line[i] === "\\") i++;
    } else if (char === "[" || char === "{") {
      state.depth++;
    } else if (char === "]" || char === "}") {
      state.depth--;
    }
  }
}

/**
 * Splits TOML text into blocks. Comments and blank lines attach to the block
 * that follows them; lines of a multi-line string, array, or inline table stay
 * with their key.
 *
 * @param text - TOML source.
 */
function parse(text: string): Config {
  const config: Config = { top: [], tables: [] };
  const state: ScanState = { string: "", depth: 0 };
  let pending: string[] = [];
  let current: Block | undefined;

  for (const line of text.split("\n")) {
    const continues = state.string !== "" || state.depth > 0;
    scanLine(line, state);

    if (continues && current) {
      current.lines.push(line);
      continue;
    }
    if (!line.trim() || line.trimStart().startsWith("#")) {
      pending.push(line);
      continue;
    }

    const header = line.match(HEADER);
    if (header) {
      current = { path: keyPath(header[1]), isTable: true, lines: [...pending, line] };
      config.tables.push(current);
    } else if (current?.isTable) {
      current.lines.push(...pending, line);
    } else {
      const equals = assignmentIndex(line);
      current = { path: keyPath(equals === -1 ? line : line.slice(0, equals)), isTable: false, lines: [...pending, line] };
      config.top.push(current);
    }
    pending = [];
  }

  // Trailing comments stay with the last block.
  if (current) current.lines.push(...pending);
  return config;
}

/**
 * Joins blocks back into TOML text.
 *
 * @param blocks - Blocks to render, in order.
 * @param separator - Text between blocks: consecutive lines for top-level
 *   keys, a blank line between tables.
 */
function render(blocks: Block[], separator = "\n\n"): string {
  return blocks
    .map((block) => block.lines.join("\n").trim())
    .filter(Boolean)
    .join(separator);
}

/**
 * Renders a whole config: top-level keys, then tables, as TOML requires.
 *
 * @param top - Top-level key blocks.
 * @param tables - Table blocks.
 */
function renderConfig(top: Block[], tables: Block[]): string {
  return [render(top, "\n"), render(tables)].filter(Boolean).join("\n\n");
}

/**
 * Keeps only the blocks of one kind.
 *
 * @param blocks - Blocks to filter.
 * @param wanted - Kind to keep.
 */
function only(blocks: Block[], wanted: Kind): Block[] {
  return blocks.filter((block) => kind(block) === wanted);
}

/**
 * Checks that two TOML texts hold the same data, ignoring layout and order.
 *
 * @param a - First TOML text.
 * @param b - Second TOML text.
 */
function sameData(a: string, b: string): boolean {
  return canonicalJson(Bun.TOML.parse(a)) === canonicalJson(Bun.TOML.parse(b));
}

/**
 * Reads a TOML file and splits it, expanding the `${HOME}/` placeholder.
 *
 * @param path - File to read; a missing file parses as an empty config.
 */
async function load(path: string): Promise<Config> {
  return parse(fromPortable((await readText(path)) ?? ""));
}

/**
 * Replaces the live config atomically after checking that the result is valid
 * TOML, so a bad merge never leaves Codex with a broken config.
 *
 * @param path - Live config file.
 * @param text - New config content.
 */
async function writeConfig(path: string, text: string): Promise<void> {
  Bun.TOML.parse(text);
  await writeAtomic(path, `${text}\n`);
}

/**
 * Saves the portable parts of the live config into the snapshot directory.
 *
 * @param configPath - Live `config.toml`.
 * @param snapshotDir - Directory for `settings.toml`.
 * @throws When the live config is missing, or when its blocks do not add up
 *   to the same data, so an unusual layout never corrupts the snapshot.
 */
export async function dump(configPath: string, snapshotDir: string): Promise<void> {
  const text = await readText(configPath);
  if (text === undefined) throw new Error(`${configPath} does not exist; nothing to dump`);
  const live = parse(text);
  if (!sameData(text, renderConfig(live.top, live.tables))) {
    throw new Error(`Cannot split ${configPath} into blocks safely; simplify its layout and rerun`);
  }

  const path = `${snapshotDir}/settings.toml`;
  await Bun.write(path, `${toPortable(renderConfig(only(live.top, "settings"), only(live.tables, "settings")))}\n`);
  ok("Dumped", tilde(path));
}

/**
 * Rebuilds the live config from the snapshots, keeping the machine-local
 * entries of the current config. Only settings blocks are taken from the
 * settings snapshot and only MCP blocks from the MCP snapshot, so an entry
 * that became machine-local is never copied from another machine.
 *
 * @param configPath - Live `config.toml`.
 * @param snapshotDir - Directory with `settings.toml` and `mcp-servers.toml`.
 * @returns Live settings entries the snapshot does not have, which the restore removed.
 */
export async function restore(configPath: string, snapshotDir: string): Promise<string[]> {
  const live = await load(configPath);
  const settings = await load(`${snapshotDir}/settings.toml`);
  const servers = await load(`${snapshotDir}/mcp-servers.toml`);

  const kept = new Set([...settings.top, ...settings.tables].map(({ path }) => path));
  const dropped = [...only(live.top, "settings"), ...only(live.tables, "settings")]
    .map(({ path }) => path)
    .filter((path) => !kept.has(path));

  await writeConfig(
    configPath,
    renderConfig(
      [...only(live.top, "local"), ...only(settings.top, "settings")],
      [...only(live.tables, "local"), ...only(settings.tables, "settings"), ...only(servers.tables, "mcp")],
    ),
  );
  return dropped;
}

/**
 * Replaces only the MCP servers of the live config with the MCP snapshot,
 * keeping every other entry, including the Codex app's own servers.
 *
 * @param configPath - Live `config.toml`.
 * @param snapshotDir - Directory with `mcp-servers.toml`.
 */
export async function restoreMcp(configPath: string, snapshotDir: string): Promise<void> {
  const live = await load(configPath);
  const servers = await load(`${snapshotDir}/mcp-servers.toml`);
  const tables = [...live.tables.filter((block) => kind(block) !== "mcp"), ...only(servers.tables, "mcp")];
  await writeConfig(configPath, renderConfig(live.top, tables));
}

/**
 * Runs `dump`, `restore`, or `restore-mcp`.
 *
 * @param command - Subcommand from the command line.
 * @param configPath - Live `config.toml`.
 * @param snapshotDir - Directory with the tracked snapshots.
 */
async function main(command: string | undefined, configPath: string | undefined, snapshotDir: string | undefined): Promise<void> {
  if (!configPath || !snapshotDir) {
    throw new Error("Usage: bun codex-config.ts dump|restore|restore-mcp <config.toml> <snapshot dir>");
  }
  if (command === "dump") {
    await dump(configPath, snapshotDir);
  } else if (command === "restore") {
    const dropped = await restore(configPath, snapshotDir);
    ok("Restored", tilde(configPath));
    if (dropped.length) warn("Removed live settings the snapshot does not have; dump first to keep them", dropped);
  } else if (command === "restore-mcp") {
    await restoreMcp(configPath, snapshotDir);
    ok("Restored MCP servers", tilde(configPath));
  } else {
    throw new Error("Usage: bun codex-config.ts dump|restore|restore-mcp <config.toml> <snapshot dir>");
  }
}

// Tests import the dump and restore functions; only a direct run parses arguments.
if (import.meta.main) await runMain(() => main(Bun.argv[2], Bun.argv[3], Bun.argv[4]));
