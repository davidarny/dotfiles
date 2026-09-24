/**
 * Lists MCP server packages in `mcp/servers.toml` that have a newer release,
 * and packages that are not pinned. bunx packages are checked against npm,
 * uvx packages against PyPI; `github:` sources and binaries are skipped.
 *
 * Usage: `bun mcp-outdated.ts` (run from `just mcp-outdated`).
 */
import { fail, ok, runMain, step, summary } from "./lib/log";
import { readServers } from "./lib/mcp";

/** Registry that answers the latest version of a package, per runner. */
const LATEST_VERSION: Record<string, (name: string) => Promise<string>> = {
  bunx: async (name) => (await (await fetch(`https://registry.npmjs.org/${name}/latest`)).json()).version,
  uvx: async (name) => (await (await fetch(`https://pypi.org/pypi/${name}/json`)).json()).info.version,
};

/** A package argument: `name` or `name@version`, npm scopes included. */
const PACKAGE = /^(@?[^@\s:]+)(?:@(\S+))?$/;

/** A package pinned in the source. */
interface Pin {
  server: string;
  runner: string;
  name: string;
  version?: string;
}

/**
 * Finds the package each bunx or uvx server runs: the first argument that is
 * not an option or an option's value.
 *
 * @param servers - Parsed `mcp/servers.toml`.
 */
function findPins(servers: Awaited<ReturnType<typeof readServers>>): Pin[] {
  const pins: Pin[] = [];
  for (const [server, { command, args = [] }] of Object.entries(servers)) {
    if (!command || !(command in LATEST_VERSION)) continue;
    // uvx takes `--python <version>` before the package.
    const spec = args.find((arg, index) => !arg.startsWith("-") && !args[index - 1]?.startsWith("--"));
    const match = spec?.match(PACKAGE);
    if (match) pins.push({ server, runner: command, name: match[1], version: match[2] });
  }
  return pins;
}

async function main(): Promise<void> {
  const pins = findPins(await readServers());
  step(`MCP packages (${pins.length})`);

  const latest = await Promise.all(pins.map(({ runner, name }) => LATEST_VERSION[runner](name).catch(() => "")));
  let stale = 0;
  pins.forEach(({ server, name, version }, index) => {
    const newest = latest[index];
    if (!version || version === "latest") {
      fail(`${server}: ${name} is not pinned`, [`pin it as ${name}@${newest || "<version>"}`]);
      stale++;
    } else if (newest && newest !== version) {
      fail(`${server}: ${name} ${version}`, [`${newest} is available`]);
      stale++;
    } else {
      ok(`${server}`, `${name}@${version}`);
    }
  });

  summary(stale ? `${stale} packages to review` : "All MCP packages are pinned and current", stale === 0);
}

await runMain(main);
