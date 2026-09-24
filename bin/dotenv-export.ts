/**
 * Parses dotenv files and prints their variables as NUL-separated
 * `name\0value\0` pairs for the zsh `dotenv` function to import.
 *
 * Values are parsed with the `dotenv` package and never evaluated as shell
 * code. Errors name the file and the error code but never print contents or
 * values.
 *
 * Usage: `bun dotenv-export.ts [file...]` (defaults to `.env` and `.env.local`).
 */
import { readFileSync, statSync } from "node:fs";
import { parse } from "dotenv@16.6.1";

/** Files read when none are passed on the command line. */
const defaultFiles = [".env", ".env.local"];

/** Environment variable names the shell can export. */
const validName = /^[A-Za-z_][A-Za-z0-9_]*$/;

/**
 * Checks whether a file exists, treating only "not found" as absence.
 *
 * @param file - Path to check.
 */
function exists(file: string): boolean {
  try {
    statSync(file);
    return true;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
    throw error;
  }
}

/**
 * Reads one dotenv file into `values`; later files override earlier ones.
 * FIFOs are accepted so 1Password-managed env pipes work; they are read with
 * `node:fs` because `Bun.file()` blocks on a FIFO.
 *
 * @param file - Regular file or FIFO to read.
 * @param values - Accumulated variables, updated in place.
 */
function readInto(file: string, values: Map<string, string>): void {
  const label = JSON.stringify(file);
  const stat = statSync(file);
  if (!stat.isFile() && !stat.isFIFO()) {
    throw new Error(`${label}: expected a regular file or FIFO`);
  }

  const content = readFileSync(file, "utf8");
  if (content.includes("\0")) throw new Error(`${label}: NUL bytes are not supported`);

  const parsed: Record<string, string> = parse(content);
  for (const [key, value] of Object.entries(parsed)) {
    if (!validName.test(key)) throw new Error(`${label}: invalid environment variable name`);
    values.set(key, value);
  }
}

try {
  let files = Bun.argv.slice(2);
  if (files.length === 0) {
    files = defaultFiles.filter(exists);
    if (files.length === 0) throw new Error("no .env or .env.local found");
  }

  const values = new Map<string, string>();
  for (const file of files) readInto(file, values);

  process.stdout.write([...values].map(([key, value]) => `${key}\0${value}\0`).join(""));
} catch (error) {
  // Quote paths to escape control characters; never print file contents or values.
  const { path, code, message } = error as NodeJS.ErrnoException;
  const prefix = path ? `${JSON.stringify(path)}: ` : "";
  console.error(`dotenv: ${prefix}${code || message}`);
  process.exitCode = 1;
}
