import { afterEach, beforeEach, expect, test } from "bun:test";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { dumpSettings, restoreSettings, type SettingsFile } from "./settings";

let dir: string;
let file: SettingsFile;

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "settings-"));
  file = { live: join(dir, "live.json"), snapshot: join(dir, "snapshot.json"), localKeys: ["model"] };
});

afterEach(async () => {
  await rm(dir, { recursive: true });
});

test("dump leaves local keys out of the snapshot", async () => {
  await Bun.write(file.live, JSON.stringify({ theme: "dark", model: "big" }));

  await dumpSettings(file);

  expect(await Bun.file(file.snapshot).json()).toEqual({ theme: "dark" });
});

test("restore applies the snapshot and keeps the live local keys", async () => {
  await Bun.write(file.live, JSON.stringify({ theme: "light", model: "small", stale: true }));
  await Bun.write(file.snapshot, JSON.stringify({ theme: "dark" }));

  await restoreSettings(file);

  expect(await Bun.file(file.live).json()).toEqual({ theme: "dark", model: "small" });
});
