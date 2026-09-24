import { expect, test } from "bun:test";
import { parseServers, readServers } from "./mcp";

test("the tracked mcp/servers.toml is valid", async () => {
  expect(Object.keys(await readServers()).length).toBeGreaterThan(0);
});

test("a server needs exactly one of command and url", () => {
  expect(() => parseServers('[a]\nargs = ["x"]\n')).toThrow("a: needs exactly one of command or url");
  expect(() => parseServers('[a]\ncommand = "x"\nurl = "https://x"\n')).toThrow("needs exactly one");
});

test("a misspelled field or agent fails instead of being ignored", () => {
  expect(() => parseServers('[a]\ncommand = "x"\nevn = { A = "1" }\n')).toThrow("a: unknown field evn");
  expect(() => parseServers('[a]\ncommand = "x"\nagents = ["claud"]\n')).toThrow("agents must be a list of");
});

test("env and header values must be strings", () => {
  expect(() => parseServers('[a]\ncommand = "x"\nenv = { PORT = 1 }\n')).toThrow("a: env values must be strings");
});
