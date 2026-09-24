import { afterEach, beforeEach, expect, spyOn, test } from "bun:test";
import { chmod, mkdtemp, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { dump, restore, restoreMcp } from "./codex-config";

/** A live config with machine-local entries, settings, and MCP servers. */
const LIVE = `notify = ["/Applications/Some.app/client", "turn-ended"]
model = "gpt"
# Comments stay with the key below them.
personality = "pragmatic"

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

  expect(settings).toContain("# Comments stay with the key below them.\npersonality = \"pragmatic\"");
  expect(settings).not.toContain("model");
  expect(settings).toContain("[features]");
  expect(settings).not.toContain("notify");
  expect(settings).not.toContain("projects");
  expect(settings).not.toContain("mcp_servers");
});

test("restore merges snapshots with machine-local entries and keeps the file private", async () => {
  await Bun.write(join(dir, "settings.toml"), 'personality = "friendly"\n\n[features]\nmemories = false\n');
  await Bun.write(join(dir, "mcp-servers.toml"), '[mcp_servers.fff]\ncommand = "fff-mcp"\n');
  await chmod(configPath, 0o600);

  await restore(configPath, dir);
  const config = Bun.TOML.parse(await Bun.file(configPath).text()) as Record<string, any>;

  expect(config.notify).toEqual(["/Applications/Some.app/client", "turn-ended"]);
  expect(config.personality).toBe("friendly");
  expect(config.model).toBe("gpt");
  expect(config.features.memories).toBe(false);
  expect(config.projects["/tmp/repo"].trust_level).toBe("trusted");
  expect(Object.keys(config.mcp_servers).sort()).toEqual(["fff", "node_repl"]);
  expect((await stat(configPath)).mode & 0o777).toBe(0o600);
});

test("restore reports live settings the snapshot removes", async () => {
  await Bun.write(join(dir, "settings.toml"), 'personality = "pragmatic"\n');
  await Bun.write(join(dir, "mcp-servers.toml"), "");

  expect(await restore(configPath, dir)).toEqual(["features"]);
});

test("restore-mcp replaces only MCP servers and keeps the app's own", async () => {
  await Bun.write(join(dir, "mcp-servers.toml"), '[mcp_servers.fff]\ncommand = "fff-mcp"\n');

  await restoreMcp(configPath, dir);
  const config = Bun.TOML.parse(await Bun.file(configPath).text()) as Record<string, any>;

  expect(config.personality).toBe("pragmatic");
  expect(config.features.memories).toBe(true);
  expect(config.projects["/tmp/repo"].trust_level).toBe("trusted");
  expect(Object.keys(config.mcp_servers).sort()).toEqual(["fff", "node_repl"]);
});

test("multi-line strings keep blank lines, comments, and bracket lines", async () => {
  const text = `instructions = """
Line one

# Heading
[NOTE] kept
"""

[features]
prompt = '''
[mcp_servers.fake]
# not a comment
'''
`;
  await Bun.write(configPath, text);

  await dump(configPath, dir);

  expect(Bun.TOML.parse(await Bun.file(join(dir, "settings.toml")).text())).toEqual(Bun.TOML.parse(text));
});

test("dotted top-level keys and multi-line arrays land where their table would", async () => {
  await Bun.write(
    configPath,
    `notify = [
  "client",
  # the event
  "turn-ended",
]
features.memories = true
projects."/tmp/repo".trust_level = "trusted"
`,
  );

  await dump(configPath, dir);
  const settings = Bun.TOML.parse(await Bun.file(join(dir, "settings.toml")).text());

  expect(settings).toEqual({ features: { memories: true } });
});

test("comments above a machine-local table stay out of the settings snapshot", async () => {
  await Bun.write(configPath, '[features]\nmemories = true\n\n# trusted on this machine only\n[projects."/tmp/repo"]\ntrust_level = "trusted"\n');

  await dump(configPath, dir);

  expect(await Bun.file(join(dir, "settings.toml")).text()).not.toContain("this machine only");
});

test("a single-quoted Codex app server survives restore", async () => {
  await Bun.write(configPath, "[mcp_servers.'node_repl']\ncommand = \"node_repl\"\n");
  await Bun.write(join(dir, "settings.toml"), "");
  await Bun.write(join(dir, "mcp-servers.toml"), "");

  await restore(configPath, dir);

  expect(await Bun.file(configPath).text()).toContain("node_repl");
});

test("dump refuses a missing live config instead of blanking the snapshot", async () => {
  expect(dump(join(dir, "missing.toml"), dir)).rejects.toThrow("does not exist");
});

test("restore followed by dump reproduces the settings snapshot", async () => {
  await dump(configPath, dir);
  const before = await Bun.file(join(dir, "settings.toml")).text();
  await Bun.write(join(dir, "mcp-servers.toml"), "");

  await restore(configPath, dir);
  await dump(configPath, dir);

  expect(await Bun.file(join(dir, "settings.toml")).text()).toBe(before);
});
