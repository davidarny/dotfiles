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
import { fail, ok, runMain, step, summary } from "./lib/log";
import { readServers, SERVERS_PATH, type Servers } from "./lib/mcp";

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

/** A package a server runs, with its pinned and latest versions. */
interface Pin {
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
 * Finds the package each bunx or uvx server runs, the first argument that is
 * neither an option nor the value of a `--` option, and looks up its latest
 * release.
 *
 * @param servers - Parsed `mcp/servers.toml`.
 */
async function findPins(servers: Servers): Promise<Pin[]> {
  const pins: Promise<Pin>[] = [];
  for (const [server, { command, args = [] }] of Object.entries(servers)) {
    if (!command || !(command in LATEST_VERSION)) continue;
    // uvx takes `--python <version>` before the package.
    const spec = args.find((arg, index) => !arg.startsWith("-") && !args[index - 1]?.startsWith("--"));
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
 * Compares a package's pin with its latest release.
 *
 * @param pin - Package to check.
 */
function status({ version, latest }: Pin): Status {
  if (!version || version === "latest") return "unpinned";
  if (!latest) return "unknown";
  return latest === version ? "current" : "outdated";
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
  const noun = attention === 1 ? "package needs" : "packages need";
  summary(attention ? `${attention} ${noun} attention` : "All MCP packages are pinned and current", attention === 0);
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
      text = text.replaceAll(JSON.stringify(pin.spec), JSON.stringify(`${pin.name}@${pin.latest}`));
      ok(pin.server, `${pin.version ?? "unpinned"} → ${pin.latest}`);
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

await runMain(() => main(Bun.argv[2]));
