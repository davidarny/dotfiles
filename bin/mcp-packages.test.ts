import { expect, test } from "bun:test";
import { packageSpec, type Pin, replaceSpec, status } from "./mcp-packages";

test("the package argument skips options and their values", () => {
  expect(packageSpec(["-y", "@scope/pkg@1.0.0"])).toBe("@scope/pkg@1.0.0");
  expect(packageSpec(["--python", "3.12", "pkg@2.1.3"])).toBe("pkg@2.1.3");
  expect(packageSpec(["--bun", "pkg@1.0.0", "serve"])).toBe("pkg@1.0.0");
  expect(packageSpec(["--from", "git+https://x/repo", "r-mcp"])).toBe("git+https://x/repo");
  expect(packageSpec(["-y"])).toBeUndefined();
});

/**
 * Builds a pin with the given versions.
 *
 * @param version - Pinned version.
 * @param latest - Latest release.
 */
function pin(version: string | undefined, latest: string | undefined): Pin {
  return { server: "s", spec: "pkg", name: "pkg", version, latest };
}

test("status compares versions as semver", () => {
  expect(status(pin("1.2.3", "1.2.3"))).toBe("current");
  expect(status(pin("1.2.3", "1.10.0"))).toBe("outdated");
  expect(status(pin("2.0.0-beta.1", "1.9.0"))).toBe("current");
  expect(status(pin("latest", "1.0.0"))).toBe("unpinned");
  expect(status(pin(undefined, "1.0.0"))).toBe("unpinned");
  expect(status(pin("1.0.0", undefined))).toBe("unknown");
});

test("replaceSpec changes only the named server's args line", () => {
  const text = `[codegraph]
command = "codegraph"
args = ["serve", "--mcp"]

[other]
command = "uvx"
args = ["serve"]
`;

  expect(replaceSpec(text, "other", "serve", "serve@2")).toBe(text.replace('args = ["serve"]', 'args = ["serve@2"]'));
  expect(replaceSpec(text, "missing", "serve", "serve@2")).toBeUndefined();
});
