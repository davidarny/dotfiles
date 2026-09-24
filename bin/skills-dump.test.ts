import { afterEach, beforeEach, expect, test } from "bun:test";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { Skills } from "./lib/skills";
import { applyChanges } from "./skills-dump";

let dir: string;

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "skills-dump-"));
});

afterEach(async () => {
  await rm(dir, { recursive: true });
});

test("applies only what the command added, removed, or re-sourced", () => {
  const manifest: Skills = { kept: { source: "a/b" }, removed: { source: "a/b" }, elsewhere: { source: "c/d" } };

  applyChanges(manifest, { kept: { source: "a/b" }, removed: { source: "a/b" } }, { kept: { source: "a/b" }, added: { source: "e/f" } });

  expect(manifest).toEqual({ kept: { source: "a/b" }, elsewhere: { source: "c/d" }, added: { source: "e/f" } });
});

test("a missing lockfile after the command leaves the manifest alone", async () => {
  const manifestPath = join(dir, "skills.json");
  const manifest = '{\n  "skills": {\n    "kept": {\n      "source": "a/b"\n    }\n  }\n}\n';
  await Bun.write(manifestPath, manifest);

  const run = Bun.spawn(["bun", join(import.meta.dir, "skills-dump.ts"), join(dir, "missing.json"), manifestPath], {
    stdin: new Blob(['{"skills":{"kept":{"source":"a/b"}}}']),
    stdout: "pipe",
  });

  expect(await run.exited).toBe(1);
  expect(await Bun.file(manifestPath).text()).toBe(manifest);
});
