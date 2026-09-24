import { afterEach, beforeEach, expect, test } from "bun:test";
import { chmod, lstat, mkdtemp, readlink, rm, stat, symlink } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { link, writeAtomic } from "./fs";

let dir: string;

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "fs-"));
});

afterEach(async () => {
  await rm(dir, { recursive: true });
});

test("writeAtomic creates new files private and keeps an existing file's mode", async () => {
  const fresh = join(dir, "nested", "fresh.json");
  await writeAtomic(fresh, "{}");
  expect((await stat(fresh)).mode & 0o777).toBe(0o600);

  const shared = join(dir, "shared.json");
  await Bun.write(shared, "old");
  await chmod(shared, 0o644);
  await writeAtomic(shared, "new");
  expect((await stat(shared)).mode & 0o777).toBe(0o644);
  expect(await Bun.file(shared).text()).toBe("new");
});

test("link creates a relative symlink and leaves an up-to-date one alone", async () => {
  const target = join(dir, "repo", "skill");
  await Bun.write(join(target, "SKILL.md"), "");
  const linkPath = join(dir, "home", "skill");

  await link(linkPath, target);
  await link(linkPath, target);

  expect(await readlink(linkPath)).toBe("../repo/skill");
});

test("link replaces a symlink pointing elsewhere", async () => {
  const target = join(dir, "repo");
  const linkPath = join(dir, "link");
  await symlink("somewhere-else", linkPath);

  await link(linkPath, target);

  expect(await readlink(linkPath)).toBe("repo");
});

test("link refuses to replace a real file or directory", async () => {
  const linkPath = join(dir, "user-data");
  await Bun.write(join(linkPath, "notes.md"), "keep me");

  expect(link(linkPath, join(dir, "repo"))).rejects.toThrow("not a symlink");
  expect((await lstat(linkPath)).isDirectory()).toBe(true);
});
