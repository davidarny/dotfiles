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
  expect(() => parseServers('[a]\ncommand = "x"\nagents = ["claud"]\n')).toThrow("agents must be a non-empty list of");
});

test("env and header values must be strings", () => {
  expect(() => parseServers('[a]\ncommand = "x"\nenv = { PORT = 1 }\n')).toThrow("a: env values must be strings");
});

test("field types that Codex would refuse to load fail here", () => {
  expect(() => parseServers('[a]\ncommand = "x"\ntimeout = "120"\n')).toThrow("timeout must be a positive number");
  expect(() => parseServers('[a]\ncommand = "x"\nargs = "serve"\n')).toThrow("args must be a list of strings");
  expect(() => parseServers('[a]\ncommand = "x"\nenabled = "false"\n')).toThrow("enabled must be true or false");
  expect(() => parseServers('[a]\ncommand = "x"\nagents = []\n')).toThrow("agents must be a non-empty list");
});

test("fields must match the kind of server", () => {
  expect(() => parseServers('[a]\nurl = "https://x"\nenv = { A = "1" }\n')).toThrow("env does not apply to a url server");
  expect(() => parseServers('[a]\ncommand = "x"\nheaders = { A = "1" }\n')).toThrow("headers does not apply to a command server");
});

test("a secret reference outside env and headers fails", () => {
  expect(() => parseServers('[a]\ncommand = "x"\nargs = ["--token", "${TOKEN}"]\n')).toThrow("not in args");
});
