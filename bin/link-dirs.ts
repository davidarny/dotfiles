/**
 * Links whole repo directories into the home directory, for apps that replace
 * their config files instead of writing through the per-file symlinks stow
 * creates (Karabiner-Elements, Zed). The list is `DIRECTORY_LINKS`.
 *
 * A home directory that holds only per-file links into the repo, as left by
 * `stow --no-folding`, or nothing at all is replaced; any other content stops
 * that link so no user file is lost.
 *
 * Usage: `bun link-dirs.ts` (run from `just link`).
 */
import { lstat, readdir, realpath, rmdir, unlink } from "node:fs/promises";
import { join } from "node:path";
import { isSymlink, link } from "./lib/fs";
import { fail, ok, runMain } from "./lib/log";
import { DIRECTORY_LINKS, HOME, REPO, tilde } from "./lib/paths";

/**
 * Removes a real directory that contains only symlinks into `source`.
 *
 * @param target - Home directory to clear.
 * @param source - Repo directory the per-file links point into.
 * @returns Names of entries that are not such links; the directory is kept
 *   untouched when there are any.
 */
async function removeStowFileLinks(target: string, source: string): Promise<string[]> {
  const entries = await readdir(target);
  const others: string[] = [];

  for (const name of entries) {
    const path = join(target, name);
    const resolved = await realpath(path).catch(() => "");
    if (!(await isSymlink(path)) || !resolved.startsWith(`${source}/`)) others.push(name);
  }
  if (others.length) return others;

  for (const name of entries) await unlink(join(target, name));
  await rmdir(target);
  return [];
}

/**
 * Links `$HOME/<relativePath>` to `<repo>/<relativePath>`.
 *
 * @param relativePath - Directory path, the same relative to the repo and to `$HOME`.
 * @returns Whether the link is in place.
 */
async function linkDirectory(relativePath: string): Promise<boolean> {
  const source = join(REPO, relativePath);
  const target = join(HOME, relativePath);

  // lstat does not follow symlinks, so this is true only for a real directory.
  if ((await lstat(target).catch(() => null))?.isDirectory()) {
    const others = await removeStowFileLinks(target, source);
    if (others.length) {
      fail(`${tilde(target)} has files that are not repo links`, [...others, "move them away and rerun just link"]);
      return false;
    }
  }

  await link(target, source);
  ok("Linked", tilde(target));
  return true;
}

/** Links every directory in `DIRECTORY_LINKS`; fails when any stays unlinked. */
async function main(): Promise<void> {
  let failures = 0;
  for (const path of DIRECTORY_LINKS) {
    if (!(await linkDirectory(path))) failures++;
  }
  process.exitCode = failures ? 1 : 0;
}

await runMain(main);
