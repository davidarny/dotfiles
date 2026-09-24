/**
 * Checks and upgrades the MCP server packages pinned in `mcp/servers.toml`.
 * bunx packages are checked against npm, uvx packages against PyPI; `github:`
 * sources and binaries are skipped.
 *
 * - `outdated` lists packages with a newer release and packages that are not
 *   pinned.
 * - `upgrade` pins every package to its latest release in `mcp/servers.toml`,
 *   keeping the rest of the file as written.
 *
 * Usage: `bun mcp-packages.ts outdated|upgrade` (run from `just mcp-outdated`
 * and `just mcp-upgrade`).
 */
import { fail, ok, runMain, step, summary } from "./lib/log";
import { readServers, SERVERS_PATH, type Servers } from "./lib/mcp";

/** Registry that answers the latest version of a package, per runner. */
const LATEST_VERSION: Record<string, (name: string) => Promise<string>> = {
  bunx: async (name) => (await (await fetch(`https://registry.npmjs.org/${name}/latest`)).json()).version,
  uvx: async (name) => (await (await fetch(`https://pypi.org/pypi/${name}/json`)).json()).info.version,
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
  /** Latest release; empty when the registry did not answer. */
  latest: string;
}

/**
 * Finds the package each bunx or uvx server runs, the first argument that is
 * neither an option nor an option's value, and looks up its latest release.
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
        .catch(() => "")
        .then((latest) => ({ server, spec, name, version, latest })),
    );
  }
  return Promise.all(pins);
}

/**
 * Whether a package needs attention: not pinned, or behind its latest release.
 *
 * @param pin - Package to check.
 */
function isStale({ version, latest }: Pin): boolean {
  return !version || version === "latest" || (latest !== "" && latest !== version);
}

/**
 * Reports every package and how many need attention.
 *
 * @param pins - Packages to report.
 */
function outdated(pins: Pin[]): void {
  for (const pin of pins) {
    if (!isStale(pin)) ok(pin.server, `${pin.name}@${pin.version}`);
    else fail(`${pin.server}: ${pin.spec}`, [`${pin.latest || "unknown"} is the latest; run just mcp-upgrade`]);
  }
  const stale = pins.filter(isStale).length;
  const noun = stale === 1 ? "package" : "packages";
  summary(stale ? `${stale} ${noun} to upgrade` : "All MCP packages are pinned and current", stale === 0);
}

/**
 * Rewrites each stale package argument in `mcp/servers.toml` to its latest
 * release, as a text replacement so comments and layout stay.
 *
 * @param pins - Packages to upgrade.
 */
async function upgrade(pins: Pin[]): Promise<void> {
  let text = await Bun.file(SERVERS_PATH).text();
  for (const pin of pins.filter(isStale)) {
    if (!pin.latest) {
      fail(`${pin.server}: ${pin.name}`, ["the registry did not answer; left as is"]);
      continue;
    }
    text = text.replaceAll(JSON.stringify(pin.spec), JSON.stringify(`${pin.name}@${pin.latest}`));
    ok(pin.server, `${pin.version ?? "unpinned"} → ${pin.latest}`);
  }
  await Bun.write(SERVERS_PATH, text);
}

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
