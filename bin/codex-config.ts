import { rename } from "node:fs/promises";

// Usage: bun codex-config.ts dump|restore <config.toml> <snapshot dir>
// Splits ~/.codex/config.toml into tracked snapshots (settings.toml,
// mcp-servers.toml) and machine-local entries. Restore keeps the local
// entries and replaces everything tracked.

interface Block {
  table?: string;
  key?: string;
  lines: string[];
}

type Kind = "settings" | "mcp" | "local";

const home = `${process.env.HOME}/`;
const placeholder = "${HOME}/";

// Machine paths, local proxies, account ids, trust lists, and UI state.
const localKeys = new Set([
  "notify",
  "model_catalog_json",
  "openai_base_url",
  "experimental_realtime_ws_base_url",
]);
const localTables =
  /^(marketplaces|projects|shell_environment_policy|desktop\.daybreak-enabled|tui\.model_availability_nux)(\.|$)/;
// Servers the Codex app writes itself, with app versions and home paths inside.
const appMcp = /^mcp_servers\.(node_repl|computer-use)(\.|$)/;
const mcp = /^mcp_servers(\.|$)/;

function kind(block: Block): Kind {
  if (!block.table) return block.key && localKeys.has(block.key) ? "local" : "settings";
  if (appMcp.test(block.table) || localTables.test(block.table)) return "local";
  return mcp.test(block.table) ? "mcp" : "settings";
}

function parse(text: string) {
  const top: Block[] = [];
  const tables: Block[] = [];
  let pending: string[] = [];
  let current: Block | undefined;

  for (const line of text.split("\n")) {
    const header = line.match(/^\s*\[\[?\s*(.+?)\s*\]\]?\s*(#.*)?$/);
    if (header) {
      current = { table: header[1].replaceAll('"', ""), lines: [...pending, line] };
      pending = [];
      tables.push(current);
    } else if (current?.table) {
      current.lines.push(line);
    } else if (!line.trim() || line.trimStart().startsWith("#")) {
      pending.push(line);
    } else {
      const key = line.match(/^\s*([A-Za-z0-9_-]+)\s*=/)?.[1];
      if (key || !current) {
        current = { key, lines: [...pending, line] };
        pending = [];
        top.push(current);
      } else {
        current.lines.push(line);
      }
    }
  }

  return { top, tables };
}

// Top-level keys stay on consecutive lines; tables are separated by a blank line.
function render(blocks: Block[], separator = "\n\n") {
  return blocks
    .map((block) => block.lines.join("\n").trim())
    .filter(Boolean)
    .join(separator);
}

async function readText(path: string) {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : "";
}

const [command, configPath, snapshotDir] = process.argv.slice(2);

if (!["dump", "restore"].includes(command) || !configPath || !snapshotDir) {
  throw new Error("Usage: bun codex-config.ts dump|restore <config.toml> <snapshot dir>");
}

const settingsPath = `${snapshotDir}/settings.toml`;
const mcpPath = `${snapshotDir}/mcp-servers.toml`;
const live = parse(await readText(configPath));
const only = (blocks: Block[], wanted: Kind) => blocks.filter((block) => kind(block) === wanted);

async function dump(path: string, text: string) {
  await Bun.write(path, `${text.replaceAll(home, placeholder)}\n`);
  console.log(`✓ Dumped ${path}`);
}

async function load(path: string) {
  return parse((await readText(path)).replaceAll(placeholder, home));
}

if (command === "dump") {
  await dump(settingsPath, [render(only(live.top, "settings"), "\n"), render(only(live.tables, "settings"))].join("\n\n"));
  await dump(mcpPath, render(only(live.tables, "mcp")));
} else {
  const settings = await load(settingsPath);
  const servers = await load(mcpPath);
  // TOML needs every top-level key before the first table.
  const text = [
    render(only(live.top, "local"), "\n"),
    render(settings.top, "\n"),
    render(only(live.tables, "local")),
    render(settings.tables),
    render(servers.tables),
  ]
    .filter(Boolean)
    .join("\n\n");

  Bun.TOML.parse(text);
  const tmp = `${configPath}.tmp-${process.pid}`;
  await Bun.write(tmp, `${text}\n`);
  await rename(tmp, configPath);
  console.log(`✓ Restored ${configPath}`);
}
