import { afterEach, beforeEach, expect, spyOn, test } from "bun:test";
import { chmod, mkdtemp, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { dump, restore } from "./codex-config";

/** A live config with machine-local entries, settings, and MCP servers. */
const LIVE = `notify = ["/Applications/Some.app/client", "turn-ended"]
# Comments stay with the key below them.
model = "gpt"

[projects."/tmp/repo"]
trust_level = "trusted"

[features]
memories = true

[mcp_servers.node_repl]
command = "node_repl"

[mcp_servers.stale]
command = "stale-mcp"
`;

let dir: string;
let configPath: string;

beforeEach(async () => {
  // dump and restore report each file they write; keep test output clean.
  spyOn(console, "log").mockImplementation(() => {});
  dir = await mkdtemp(join(tmpdir(), "codex-config-"));
  configPath = join(dir, "config.toml");
  await Bun.write(configPath, LIVE);
});

afterEach(async () => {
  await rm(dir, { recursive: true });
});

test("dump keeps portable settings and leaves out machine-local entries and MCP servers", async () => {
  await dump(configPath, dir);
  const settings = await Bun.file(join(dir, "settings.toml")).text();

  expect(settings).toContain("# Comments stay with the key below them.\nmodel = \"gpt\"");
  expect(settings).toContain("[features]");
  expect(settings).not.toContain("notify");
  expect(settings).not.toContain("projects");
  expect(settings).not.toContain("mcp_servers");
});

test("restore merges snapshots with machine-local entries and keeps the file private", async () => {
  await Bun.write(join(dir, "settings.toml"), 'model = "new"\n\n[features]\nmemories = false\n');
  await Bun.write(join(dir, "mcp-servers.toml"), '[mcp_servers.fff]\ncommand = "fff-mcp"\n');
  await chmod(configPath, 0o600);

  await restore(configPath, dir);
  const config = Bun.TOML.parse(await Bun.file(configPath).text()) as Record<string, any>;

  expect(config.notify).toEqual(["/Applications/Some.app/client", "turn-ended"]);
  expect(config.model).toBe("new");
  expect(config.features.memories).toBe(false);
  expect(config.projects["/tmp/repo"].trust_level).toBe("trusted");
  expect(Object.keys(config.mcp_servers).sort()).toEqual(["fff", "node_repl"]);
  expect((await stat(configPath)).mode & 0o777).toBe(0o600);
});

test("restore followed by dump reproduces the settings snapshot", async () => {
  await dump(configPath, dir);
  const before = await Bun.file(join(dir, "settings.toml")).text();
  await Bun.write(join(dir, "mcp-servers.toml"), "");

  await restore(configPath, dir);
  await dump(configPath, dir);

  expect(await Bun.file(join(dir, "settings.toml")).text()).toBe(before);
});
