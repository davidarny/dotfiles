/**
 * Well-known paths, and the `${HOME}/` placeholder that keeps
 * machine-specific home paths out of tracked snapshots.
 */
import { resolve } from "node:path";

/** The current user's home directory, without a trailing slash. */
export const HOME = Bun.env.HOME!;

/** The dotfiles repo root (this file lives in `bin/lib`). */
export const REPO = resolve(import.meta.dir, "../..");

/**
 * Directories linked as a whole instead of stowed file by file, for apps that
 * replace their config files rather than writing through a symlink. Paths
 * are the same relative to the repo and to `$HOME`; `.stow-local-ignore`
 * excludes them from stow.
 */
export const DIRECTORY_LINKS = [".config/karabiner", ".config/zed"];

const HOME_PREFIX = `${HOME}/`;
const PLACEHOLDER = "${HOME}/";

/**
 * Replaces this machine's home prefix with the `${HOME}/` placeholder.
 *
 * @param text - Snapshot content about to be written to the repo.
 */
export function toPortable(text: string): string {
  return text.replaceAll(HOME_PREFIX, PLACEHOLDER);
}

/**
 * Expands the `${HOME}/` placeholder to this machine's home prefix.
 *
 * @param text - Snapshot content read from the repo.
 */
export function fromPortable(text: string): string {
  return text.replaceAll(PLACEHOLDER, HOME_PREFIX);
}

/**
 * Shortens a path under the home directory to `~/...` for display.
 *
 * @param path - Absolute path.
 */
export function tilde(path: string): string {
  return path.startsWith(HOME_PREFIX) ? `~/${path.slice(HOME_PREFIX.length)}` : path;
}
