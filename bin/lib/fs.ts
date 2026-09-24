/**
 * File helpers shared by the bin scripts: optional reads, atomic writes, and
 * symlinks that never overwrite user data.
 */
import { lstat, mkdir, readlink, rename, symlink, unlink } from "node:fs/promises";
import { dirname, relative } from "node:path";

/**
 * Reads a text file that may not exist.
 *
 * @param path - File to read.
 * @returns The content, or `undefined` when the file does not exist.
 */
export async function readText(path: string): Promise<string | undefined> {
  const file = Bun.file(path);
  return (await file.exists()) ? file.text() : undefined;
}

/**
 * Replaces a file through a temporary sibling and a rename, so a crash never
 * leaves it half written. Parent directories are created as needed.
 *
 * @param path - File to replace.
 * @param text - New content.
 */
export async function writeAtomic(path: string, text: string): Promise<void> {
  const tmp = `${path}.tmp-${process.pid}`;
  await Bun.write(tmp, text);
  await rename(tmp, path);
}

/**
 * Checks whether a path is a symlink, without following it.
 *
 * @param path - Path to check; a missing path is not a symlink.
 */
export async function isSymlink(path: string): Promise<boolean> {
  return (await lstat(path).catch(() => null))?.isSymbolicLink() ?? false;
}

/**
 * Makes `linkPath` a relative symlink to `target`.
 *
 * An up-to-date link is left alone and a symlink pointing elsewhere is
 * replaced. Anything that is not a symlink is user data, so this throws
 * instead of overwriting it.
 *
 * @param linkPath - Where the symlink should live.
 * @param target - Absolute path the symlink should resolve to.
 */
export async function link(linkPath: string, target: string): Promise<void> {
  const expected = relative(dirname(linkPath), target);
  const current = await lstat(linkPath).catch(() => null);

  if (current?.isSymbolicLink()) {
    if ((await readlink(linkPath)) === expected) return;
    await unlink(linkPath);
  } else if (current) {
    throw new Error(`Refusing to replace ${linkPath}: not a symlink; move it away and rerun`);
  }

  await mkdir(dirname(linkPath), { recursive: true });
  await symlink(expected, linkPath);
}
