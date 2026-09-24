/**
 * Checks and upgrades the MCP server packages pinned in `mcp/servers.toml`.
 * bunx packages are checked against npm, uvx packages against PyPI; `github:`
 * sources and binaries are skipped.
 *
 * - `outdated` lists packages that are not pinned, have a newer release, or
 *   could not be checked.
 * - `upgrade` pins every package to its latest release in `mcp/servers.toml`,
 *   keeping the rest of the file as written.
 *
 * Usage: `bun mcp-packages.ts outdated|upgrade` (run from `just mcp-outdated`
 * and `just mcp-upgrade`).
 */
import { counted, fail, ok, runMain, step, summary } from "./lib/log";
import { readServers, SERVERS_PATH, type Servers } from "./lib/mcp";
import { tomlKey } from "./lib/toml";

/**
 * Asks a registry for the latest version of a package. The answer is whatever
 * the registry sent; `findPins` keeps it only when it is a string.
 */
type LatestVersionLookup = (name: string) => Promise<unknown>;

/** npm's answer for `/<package>/latest`. */
interface NpmRelease {
  version?: unknown;
}

/** PyPI's answer for `/pypi/<package>/json`. */
interface PypiProject {
  info?: PypiInfo;
}

/** The `info` object of a PyPI project. */
interface PypiInfo {
  version?: unknown;
}

/** Registry lookup per runner. */
const LATEST_VERSION: Record<string, LatestVersionLookup> = {
  bunx: async (name) => (await fetchJson<NpmRelease>(`https://registry.npmjs.org/${name}/latest`)).version,
  uvx: async (name) => (await fetchJson<PypiProject>(`https://pypi.org/pypi/${name}/json`)).info?.version,
};

/** A package argument: `name` or `name@version`, npm scopes included. */
const PACKAGE = /^(@?[^@\s:]+)(?:@(\S+))?$/;

/** Options whose value is the package itself (`uvx --from`, `bunx --package`). */
const PACKAGE_OPTIONS = new Set(["--from", "--package", "-p"]);

/** Options that take a value that is not the package, such as `uvx --python 3.12`. */
const VALUE_OPTIONS = new Set(["--python", "--with", "--with-editable", "--with-requirements", "--index", "--index-url", "--extra-index-url"]);

/** A package a server runs, with its pinned and latest versions. */
export interface Pin {
  server: string;
  /** The argument as written, e.g. `testrail-mcp@0.1.5`. */
  spec: string;
  name: string;
  /** Pinned version; missing or `latest` when not pinned. */
  version?: string;
  /** Latest release; missing when the registry did not answer. */
  latest?: string;
}

/** Where a package stands against its registry. */
type Status = "current" | "unpinned" | "outdated" | "unknown";

/**
 * Fetches JSON and throws on an HTTP error, so an error page is never read as
 * a version.
 *
 * @param url - Registry URL.
 */
async function fetchJson<T>(url: string): Promise<T> {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${url} answered HTTP ${response.status}`);
  return (await response.json()) as T;
}

/**
 * Finds the package argument of a bunx or uvx command line: the value of an
 * option that names the package, otherwise the first argument that is neither
 * an option nor an option's value.
 *
 * @param args - Arguments after `bunx` or `uvx`.
 */
export function packageSpec(args: string[]): string | undefined {
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (PACKAGE_OPTIONS.has(arg)) return args[i + 1];
    if (VALUE_OPTIONS.has(arg)) i++;
    else if (!arg.startsWith("-")) return arg;
  }
  return undefined;
}

/**
 * Finds the package each bunx or uvx server runs and looks up its latest
 * release.
 *
 * @param servers - Parsed `mcp/servers.toml`.
 */
async function findPins(servers: Servers): Promise<Pin[]> {
  const pins: Promise<Pin>[] = [];
  for (const [server, { command, args = [] }] of Object.entries(servers)) {
    if (!command || !(command in LATEST_VERSION)) continue;
    const spec = packageSpec(args);
    const match = spec?.match(PACKAGE);
    if (!spec || !match) continue;
    const [, name, version] = match;
    pins.push(
      LATEST_VERSION[command](name)
        .then((latest) => (typeof latest === "string" ? latest : undefined))
        .catch(() => undefined)
        .then((latest) => ({ server, spec, name, version, latest })),
    );
  }
  return Promise.all(pins);
}

/**
 * Compares a package's pin with its latest release. A pin newer than the
 * latest release (a prerelease) counts as current; versions that are not
 * semver compare as plain strings.
 *
 * @param pin - Package to check.
 */
export function status({ version, latest }: Pin): Status {
  if (!version || version === "latest") return "unpinned";
  if (!latest) return "unknown";
  try {
    return Bun.semver.order(latest, version) > 0 ? "outdated" : "current";
  } catch {
    return latest === version ? "current" : "outdated";
  }
}

/**
 * Replaces a package argument inside one server's table of
 * `mcp/servers.toml`, leaving the same text elsewhere in the file alone.
 *
 * @param text - `mcp/servers.toml` content.
 * @param server - Server whose `args` hold the argument.
 * @param from - Argument as written, e.g. `testrail-mcp@0.1.4`.
 * @param to - New argument.
 * @returns The new content, or `undefined` when the argument is not in that table.
 */
export function replaceSpec(text: string, server: string, from: string, to: string): string | undefined {
  const lines = text.split("\n");
  const start = lines.findIndex((line) => line.trim() === `[${tomlKey(server)}]`);
  if (start === -1) return undefined;
  for (let i = start + 1; i < lines.length && !lines[i].trimStart().startsWith("["); i++) {
    if (lines[i].trimStart().startsWith("args") && lines[i].includes(JSON.stringify(from))) {
      lines[i] = lines[i].replace(JSON.stringify(from), JSON.stringify(to));
      return lines.join("\n");
    }
  }
  return undefined;
}

/**
 * Reports every package and how many need attention.
 *
 * @param pins - Packages to report.
 */
function outdated(pins: Pin[]): void {
  for (const pin of pins) {
    const hint = `${pin.latest} is the latest; run just mcp-upgrade`;
    switch (status(pin)) {
      case "current":
        ok(pin.server, pin.spec);
        break;
      case "unpinned":
        fail(`${pin.server}: ${pin.spec} is not pinned`, [pin.latest ? hint : "the registry did not answer"]);
        break;
      case "outdated":
        fail(`${pin.server}: ${pin.spec}`, [hint]);
        break;
      case "unknown":
        fail(`${pin.server}: ${pin.spec}`, ["the registry did not answer"]);
        break;
    }
  }

  const attention = pins.filter((pin) => status(pin) !== "current").length;
  const needs = `${counted(attention, "package needs", "packages need")} attention`;
  summary(attention ? needs : "All MCP packages are pinned and current", attention === 0);
  process.exitCode = attention ? 1 : 0;
}

/**
 * Rewrites each unpinned or outdated package argument in `mcp/servers.toml` to
 * its latest release, as a text replacement so comments and layout stay.
 *
 * @param pins - Packages to upgrade.
 */
async function upgrade(pins: Pin[]): Promise<void> {
  const original = await Bun.file(SERVERS_PATH).text();
  let text = original;

  for (const pin of pins) {
    const state = status(pin);
    if (state === "unknown" || (state === "unpinned" && !pin.latest)) {
      fail(`${pin.server}: ${pin.spec}`, ["the registry did not answer; left as is"]);
    } else if (state !== "current") {
      const next = replaceSpec(text, pin.server, pin.spec, `${pin.name}@${pin.latest}`);
      if (next === undefined) {
        fail(`${pin.server}: ${pin.spec}`, ["not found in the server's args line; update it by hand"]);
      } else {
        text = next;
        ok(pin.server, `${pin.version ?? "unpinned"} → ${pin.latest}`);
      }
    }
  }

  if (text === original) ok("Nothing to upgrade");
  else await Bun.write(SERVERS_PATH, text);
}

/**
 * Runs `outdated` or `upgrade`.
 *
 * @param command - Subcommand from the command line.
 */
async function main(command: string | undefined): Promise<void> {
  if (command !== "outdated" && command !== "upgrade") {
    throw new Error("Usage: bun mcp-packages.ts outdated|upgrade");
  }
  const pins = await findPins(await readServers());
  step(`MCP packages (${pins.length})`);
  if (command === "outdated") outdated(pins);
  else await upgrade(pins);
}

// Tests import packageSpec, status, and replaceSpec; only a direct run checks the registries.
if (import.meta.main) await runMain(() => main(Bun.argv[2]));
