import { expect, test } from "bun:test";
import type { Servers } from "./lib/mcp";
import { renderClaude, renderCodex, renderOpencode, renderPi } from "./mcp-sync";

const SERVERS: Servers = {
  local: {
    command: "bunx",
    args: ["-y", "pkg@1.0.0"],
    env: { HOST: "example.com", TOKEN: "${TOKEN}", AWS_KEY: "${OTHER_KEY}" },
    timeout: 120,
  },
  remote: {
    url: "https://example.com/mcp",
    headers: { Authorization: "Bearer ${BEARER}", "x-api-key": "${API_KEY}" },
  },
  codexOnly: { agents: ["codex"], url: "https://codex.example.com/mcp" },
  disabled: { command: "off", enabled: false },
};

test("each agent gets only its servers, and only Codex keeps disabled ones", () => {
  expect(Object.keys(JSON.parse(renderClaude(SERVERS)))).toEqual(["local", "remote"]);
  expect(Object.keys(JSON.parse(renderPi(SERVERS)).mcpServers)).toEqual(["local", "remote"]);

  const codex = Bun.TOML.parse(renderCodex(SERVERS)) as Record<string, any>;
  expect(Object.keys(codex.mcp_servers)).toEqual(["local", "remote", "codexOnly", "disabled"]);
  expect(codex.mcp_servers.disabled.enabled).toBe(false);
});

test("Codex forwards secrets by name and maps renamed ones through /bin/sh", () => {
  const { local, remote } = (Bun.TOML.parse(renderCodex(SERVERS)) as Record<string, any>).mcp_servers;

  expect(local.command).toBe("/bin/sh");
  expect(local.args).toEqual(["-c", 'AWS_KEY="$OTHER_KEY" exec "$0" "$@"', "bunx", "-y", "pkg@1.0.0"]);
  expect(local.env_vars).toEqual(["TOKEN", "OTHER_KEY"]);
  expect(local.env).toEqual({ HOST: "example.com" });
  expect(local.startup_timeout_sec).toBe(120);

  expect(remote.bearer_token_env_var).toBe("BEARER");
  expect(remote.env_http_headers).toEqual({ "x-api-key": "API_KEY" });
});

test("Codex rejects a secret embedded in a longer value", () => {
  expect(() => renderCodex({ bad: { command: "x", env: { URL: "https://${HOST}/api" } } })).toThrow();
});

test("Claude keeps ${VAR} references and converts the timeout to milliseconds", () => {
  const { local, remote } = JSON.parse(renderClaude(SERVERS));

  expect(local).toMatchObject({ type: "stdio", timeout: 120_000 });
  expect(local.env.AWS_KEY).toBe("${OTHER_KEY}");
  expect(remote).toMatchObject({ type: "http", headers: { Authorization: "Bearer ${BEARER}" } });
});

test("OpenCode uses {env:VAR} and keeps the rest of its config", () => {
  const config = JSON.parse(renderOpencode(SERVERS, JSON.stringify({ $schema: "s", provider: { p: {} } })));

  expect(config.provider).toEqual({ p: {} });
  expect(config.mcp.local.environment.TOKEN).toBe("{env:TOKEN}");
  expect(config.mcp.local.command).toEqual(["bunx", "-y", "pkg@1.0.0"]);
  expect(config.mcp.remote).toMatchObject({ type: "remote", oauth: false, headers: { "x-api-key": "{env:API_KEY}" } });
});
