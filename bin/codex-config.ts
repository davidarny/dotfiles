import { rename } from "node:fs/promises";

// Usage: bun codex-config.ts dump|restore <config.toml> <snapshot dir>
// Splits ~/.codex/config.toml into the tracked MCP snapshot and machine-local
// entries. Restore keeps the local entries and replaces everything tracked.

interface Block {
  table?: string;
  key?: string;
  lines: string[];
}

type Kind = "mcp" | "local";

const home = `${process.env.HOME}/`;
const placeholder = "${HOME}/";

// Servers the Codex app writes itself, with app versions and home paths inside.
const appMcp = /^mcp_servers\.(node_repl|computer-use)(\.|$)/;
const mcp = /^mcp_servers(\.|$)/;

function kind(block: Block): Kind {
  if (block.table && mcp.test(block.table) && !appMcp.test(block.table)) return "mcp";
  return "local";
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

function render(blocks: Block[]) {
  return blocks
    .map((block) => block.lines.join("\n").trim())
    .filter(Boolean)
    .join("\n\n");
}

async function readText(path: string) {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : "";
}

const [command, configPath, snapshotDir] = process.argv.slice(2);

if (!["dump", "restore"].includes(command) || !configPath || !snapshotDir) {
  throw new Error("Usage: bun codex-config.ts dump|restore <config.toml> <snapshot dir>");
}

const mcpPath = `${snapshotDir}/mcp-servers.toml`;
const live = parse(await readText(configPath));

if (command === "dump") {
  const text = render(live.tables.filter((block) => kind(block) === "mcp"));
  await Bun.write(mcpPath, `${text.replaceAll(home, placeholder)}\n`);
  console.log(`✓ Dumped ${mcpPath}`);
} else {
  const snapshot = parse((await readText(mcpPath)).replaceAll(placeholder, home));
  const text = [
    render(live.top),
    render(live.tables.filter((block) => kind(block) === "local")),
    render(snapshot.tables),
  ]
    .filter(Boolean)
    .join("\n\n");

  Bun.TOML.parse(text);
  const tmp = `${configPath}.tmp-${process.pid}`;
  await Bun.write(tmp, `${text}\n`);
  await rename(tmp, configPath);
  console.log(`✓ Restored ${configPath}`);
}
