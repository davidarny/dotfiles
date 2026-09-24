import { expect, test } from "bun:test";
import { parsePlist, samePlist, toPlistXml } from "./lib/plist";
import { parseSettings, readSettings } from "./macos-defaults";

test("the tracked macos/defaults.toml is valid and every value serializes", async () => {
  const settings = await readSettings();

  expect(settings.length).toBeGreaterThan(0);
  for (const { value } of settings) {
    expect(samePlist(parsePlist(`<plist>${toPlistXml(value)}</plist>`), value)).toBe(true);
  }
});

test("settings flatten per scope and domain, keeping nested tables whole", () => {
  const settings = parseSettings(`
[user."com.apple.dock"]
autohide = true

[user."com.apple.symbolichotkeys".AppleSymbolicHotKeys]
60 = { enabled = true }

[currentHost.NSGlobalDomain]
"com.apple.trackpad.scrollBehavior" = 2
`);

  expect(settings).toEqual([
    { scope: "user", domain: "com.apple.dock", key: "autohide", value: true },
    { scope: "user", domain: "com.apple.symbolichotkeys", key: "AppleSymbolicHotKeys", value: { "60": { enabled: true } } },
    { scope: "currentHost", domain: "NSGlobalDomain", key: "com.apple.trackpad.scrollBehavior", value: 2 },
  ]);
});

test("an unknown scope or a domain that is not a table fails", () => {
  expect(() => parseSettings('[host."com.apple.dock"]\nautohide = true\n')).toThrow("unknown scope host");
  expect(() => parseSettings("[user]\nNSGlobalDomain = 1\n")).toThrow("NSGlobalDomain is not a table");
});
