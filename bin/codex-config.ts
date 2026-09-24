/**
 * Splits `~/.codex/config.toml` into tracked snapshots and machine-local entries.
 *
 * - `dump` writes the portable settings to `settings.toml`, with the home
 *   prefix replaced by `${HOME}/`. MCP servers come from `mcp/servers.toml`
 *   instead (`just mcp-sync` renders `mcp-servers.toml`).
 * - `restore` rebuilds the live config from `settings.toml`,
 *   `mcp-servers.toml`, and the entries that stay on this machine.
 *
 * The file is split into text blocks instead of parsed and re-serialized, so
 * comments, key order, and formatting survive a round trip.
 *
 * Usage: `bun codex-config.ts dump|restore <config.toml> <snapshot dir>`
 */
import { readText, writeAtomic } from "./lib/fs";
import { ok, runMain } from "./lib/log";
import { fromPortable, toPortable } from "./lib/paths";

/**
 * A top-level key or a table of the TOML file, kept as its original lines
 * together with the comments right above it.
 */
interface Block {
  /** Table name without brackets and quotes, e.g. `mcp_servers.fff.env`. */
  table?: string;
  /** Key name for a top-level assignment, e.g. `model`. */
  key?: string;
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

/**
 * Where a block belongs: the settings snapshot, the MCP snapshot, or this
 * machine only.
 */
type Kind = "settings" | "mcp" | "local";

/** Top-level keys with machine paths or local proxy URLs. */
const LOCAL_KEYS = new Set([
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

/**
 * Decides which snapshot a block belongs to.
 *
 * @param block - A top-level key or a table.
 */
function kind(block: Block): Kind {
  if (!block.table) {
    return block.key && LOCAL_KEYS.has(block.key) ? "local" : "settings";
  }
  if (APP_MCP_SERVERS.test(block.table) || LOCAL_TABLES.test(block.table)) return "local";
  return MCP_SERVERS.test(block.table) ? "mcp" : "settings";
}

/**
 * Splits TOML text into blocks. Comments and blank lines attach to the block
 * that follows them; lines of a multi-line value stay with their key.
 *
 * @param text - TOML source.
 */
function parse(text: string): Config {
  const config: Config = { top: [], tables: [] };
  let pending: string[] = [];
  let current: Block | undefined;

  for (const line of text.split("\n")) {
    const header = line.match(/^\s*\[\[?\s*(.+?)\s*\]\]?\s*(#.*)?$/);
    const isComment = !line.trim() || line.trimStart().startsWith("#");

    if (header) {
      current = { table: header[1].replaceAll('"', ""), lines: [...pending, line] };
      config.tables.push(current);
      pending = [];
    } else if (current?.table) {
      current.lines.push(line);
    } else if (isComment) {
      pending.push(line);
    } else {
      const key = line.match(/^\s*([A-Za-z0-9_-]+)\s*=/)?.[1];
      if (key || !current) {
        current = { key, lines: [...pending, line] };
        config.top.push(current);
        pending = [];
      } else {
        current.lines.push(line);
      }
    }
  }

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
 * Keeps only the blocks of one kind.
 *
 * @param blocks - Blocks to filter.
 * @param wanted - Kind to keep.
 */
function only(blocks: Block[], wanted: Kind): Block[] {
  return blocks.filter((block) => kind(block) === wanted);
}

/**
 * Reads and parses a TOML file, expanding the `${HOME}/` placeholder.
 *
 * @param path - File to read; a missing file parses as an empty config.
 */
async function load(path: string): Promise<Config> {
  return parse(fromPortable((await readText(path)) ?? ""));
}

/**
 * Writes a snapshot with the home prefix replaced by `${HOME}/`.
 *
 * @param path - Snapshot file.
 * @param text - TOML to write.
 */
async function writeSnapshot(path: string, text: string): Promise<void> {
  await Bun.write(path, `${toPortable(text)}\n`);
  ok("Dumped", path);
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
  ok("Restored", path);
}

/**
 * Saves the portable parts of the live config into the snapshot directory.
 *
 * @param configPath - Live `config.toml`.
 * @param snapshotDir - Directory for `settings.toml`.
 */
export async function dump(configPath: string, snapshotDir: string): Promise<void> {
  const live = await load(configPath);
  const settings = [render(only(live.top, "settings"), "\n"), render(only(live.tables, "settings"))];

  await writeSnapshot(`${snapshotDir}/settings.toml`, settings.join("\n\n"));
}

/**
 * Rebuilds the live config from the snapshots, keeping the machine-local
 * entries of the current config.
 *
 * @param configPath - Live `config.toml`.
 * @param snapshotDir - Directory with `settings.toml` and `mcp-servers.toml`.
 */
export async function restore(configPath: string, snapshotDir: string): Promise<void> {
  const live = await load(configPath);
  const settings = await load(`${snapshotDir}/settings.toml`);
  const servers = await load(`${snapshotDir}/mcp-servers.toml`);

  // TOML needs every top-level key before the first table.
  const sections = [
    render(only(live.top, "local"), "\n"),
    render(settings.top, "\n"),
    render(only(live.tables, "local")),
    render(settings.tables),
    render(servers.tables),
  ];

  await writeConfig(configPath, sections.filter(Boolean).join("\n\n"));
}

// Tests import dump and restore; only a direct run parses arguments.
if (import.meta.main) await runMain(async () => {
  const [command, configPath, snapshotDir] = Bun.argv.slice(2);
  if (command === "dump" && configPath && snapshotDir) await dump(configPath, snapshotDir);
  else if (command === "restore" && configPath && snapshotDir) await restore(configPath, snapshotDir);
  else throw new Error("Usage: bun codex-config.ts dump|restore <config.toml> <snapshot dir>");
});
