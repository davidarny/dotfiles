/**
 * Applies the macOS settings in `macos/defaults.toml` with `defaults write`,
 * reports drift, and helps find the keys behind a System Settings control.
 *
 * - `apply` writes every key whose value differs, then restarts the processes
 *   that read the changed domains and reloads input settings.
 * - `check` lists keys whose value differs; `just doctor` runs the same check.
 * - `diff` snapshots every preference domain on the first run; after you change
 *   a setting, the second run prints the changed keys as TOML to paste into
 *   `macos/defaults.toml`, and removes the snapshot.
 *
 * Symlinked plists are ignored by macOS since Sonoma, so settings are written
 * key by key instead of linking preference files.
 *
 * Usage: `bun macos-defaults.ts apply|check|diff` (run from `just macos`,
 * `just macos-check`, and `just macos-diff`).
 */
import { $ } from "bun";
import { chmod, mkdir, unlink } from "node:fs/promises";
import { dirname, join } from "node:path";
import { readText } from "./lib/fs";
import { counted, fail, ok, runMain, step, summary } from "./lib/log";
import { HOME, REPO } from "./lib/paths";
import { type PlistDict, type PlistValue, parsePlist, samePlist, toPlistXml } from "./lib/plist";
import { type TomlLiteral, type TomlTable, tomlKey, tomlLiteral } from "./lib/toml";

/** Where a setting lives: the user's domains, or this machine's (`defaults -currentHost`). */
type Scope = "user" | "currentHost";

/** Settings per domain in one scope, e.g. `com.apple.dock` → `{ autohide: true }`. */
type DomainSettings = Record<string, PlistDict>;

/** `macos/defaults.toml`, with a table per scope. */
interface DefaultsFile {
  user?: DomainSettings;
  currentHost?: DomainSettings;
}

/** One setting from `macos/defaults.toml`. */
interface Setting {
  scope: Scope;
  domain: string;
  key: string;
  value: PlistValue;
}

/** A setting whose value on this machine differs from `macos/defaults.toml`. */
interface Drift extends Setting {
  /** The machine's value; missing when the key is not set. */
  current?: PlistValue;
}

/** Every preference domain of both scopes as `defaults export` XML. */
interface Snapshot {
  user: Record<string, string>;
  currentHost: Record<string, string>;
}

/** A preference domain in a scope. */
interface DomainRef {
  scope: Scope;
  domain: string;
}

/** The settings file. */
const DEFAULTS_PATH = join(REPO, "macos/defaults.toml");

/** Both scopes, in the order they are applied. */
const SCOPES: Scope[] = ["user", "currentHost"];

/** Process to restart after a domain changes, so the new value takes effect. */
const RESTART: Record<string, string> = {
  "com.apple.dock": "Dock",
  "com.apple.finder": "Finder",
  "com.apple.controlcenter": "ControlCenter",
  "com.apple.menuextra.clock": "ControlCenter",
  "com.apple.WindowManager": "WindowManager",
  "com.apple.Spotlight": "Spotlight",
  "com.apple.screencapture": "SystemUIServer",
};

/** Reloads keyboard, trackpad, mouse, and shortcut settings without logging out. */
const ACTIVATE_SETTINGS = "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings";

/** Domains whose changes `activateSettings -u` applies to the running session. */
const ACTIVATED_DOMAINS = /^(NSGlobalDomain|com\.apple\.(symbolichotkeys|HIToolbox|AppleMultitouch|driver\.Apple|universalaccess|Accessibility))/;

/** Snapshot taken by the first `diff` run; private, since preferences may hold personal data. */
const BASELINE_PATH = join(HOME, ".cache/dotfiles/macos-defaults-baseline.json");

/**
 * Keys that change on their own (analytics, window frames, recents), hidden
 * from `diff`. Kept narrow on purpose: a hidden real setting is worse than a
 * visible timestamp, so words like "date" or "window" that also name settings
 * (`ShowDate`, `AppWindowGroupingBehavior`) are not on the list.
 */
const NOISE = /analytics|stamp|heartbeat|^last|frame|recent|history|uuid|cache|migrat|token|^version$/i;

/** How many `defaults export` processes `diff` runs at once. */
const EXPORT_CONCURRENCY = 16;

/**
 * Builds the `defaults` arguments that select a scope.
 *
 * @param scope - Scope to select.
 */
function scopeArgs(scope: Scope): string[] {
  return scope === "currentHost" ? ["-currentHost"] : [];
}

/**
 * Exports one domain as XML.
 *
 * @param ref - Domain and scope to export.
 * @returns The XML, or `undefined` when the domain does not exist yet.
 */
async function exportDomain({ scope, domain }: DomainRef): Promise<string | undefined> {
  const { stdout, exitCode } = await $`defaults ${scopeArgs(scope)} export ${domain} -`.quiet().nothrow();
  return exitCode === 0 ? stdout.toString() : undefined;
}

/**
 * Parses a domain export into its keys.
 *
 * @param xml - `defaults export` output; missing for a domain that does not exist.
 */
function domainKeys(xml: string | undefined): PlistDict {
  if (!xml) return {};
  const value = parsePlist(xml);
  if (typeof value !== "object" || Array.isArray(value) || value instanceof Date || value instanceof Uint8Array) {
    throw new Error("A preference domain export is not a dictionary");
  }
  return value;
}

/**
 * Parses and validates `macos/defaults.toml` content into a flat list of
 * settings.
 *
 * @param text - TOML source.
 * @throws When the file has a scope other than `user` and `currentHost`, or a
 *   domain that is not a table.
 */
export function parseSettings(text: string): Setting[] {
  const file = Bun.TOML.parse(text) as Record<string, unknown>;
  const unknown = Object.keys(file).filter((scope) => !SCOPES.includes(scope as Scope));
  if (unknown.length) throw new Error(`macos/defaults.toml: unknown scope ${unknown.join(", ")}; use user or currentHost`);

  const settings: Setting[] = [];
  for (const scope of SCOPES) {
    for (const [domain, keys] of Object.entries((file as DefaultsFile)[scope] ?? {})) {
      if (typeof keys !== "object" || Array.isArray(keys)) throw new Error(`macos/defaults.toml: ${domain} is not a table`);
      for (const [key, value] of Object.entries(keys)) settings.push({ scope, domain, key, value });
    }
  }
  return settings;
}

/** Reads and validates `macos/defaults.toml`. */
export async function readSettings(): Promise<Setting[]> {
  return parseSettings(await Bun.file(DEFAULTS_PATH).text());
}

/**
 * Lists the distinct domains the settings touch.
 *
 * @param settings - Settings to group.
 */
function domainsOf(settings: Setting[]): DomainRef[] {
  const seen = new Map<string, DomainRef>();
  for (const { scope, domain } of settings) seen.set(`${scope} ${domain}`, { scope, domain });
  return [...seen.values()];
}

/**
 * Compares every setting with this machine.
 *
 * @param settings - Settings from `macos/defaults.toml`.
 * @returns The settings whose value differs, with the machine's value.
 */
export async function findDrift(settings: Setting[]): Promise<Drift[]> {
  const refs = domainsOf(settings);
  const exports = await Promise.all(refs.map(exportDomain));
  const current = new Map(refs.map(({ scope, domain }, i) => [`${scope} ${domain}`, domainKeys(exports[i])]));

  return settings
    .map((setting) => ({ ...setting, current: current.get(`${setting.scope} ${setting.domain}`)?.[setting.key] }))
    .filter(({ value, current }) => !samePlist(current, value));
}

/**
 * Describes a setting's domain and key for output, with `-currentHost` marked.
 *
 * @param setting - Setting to describe.
 */
function label({ scope, domain, key }: Setting): string {
  return `${scope === "currentHost" ? "currentHost " : ""}${domain} ${key}`;
}

/**
 * Shortens a value for a one-line report.
 *
 * @param value - Value to show; missing prints as `unset`.
 */
function preview(value: PlistValue | undefined): string {
  const literal = value === undefined ? undefined : toTomlLiteral(value);
  const text = value === undefined ? "unset" : literal === undefined ? "(date or data)" : tomlLiteral(literal);
  return text.length > 60 ? `${text.slice(0, 57)}...` : text;
}

/**
 * Converts a plist value to TOML, which has no `data` type and whose dates the
 * settings never need.
 *
 * @param value - Value to convert.
 * @returns The value, or `undefined` when it holds a date or data.
 */
function toTomlLiteral(value: PlistValue): TomlLiteral | undefined {
  if (value instanceof Date || value instanceof Uint8Array) return undefined;
  if (Array.isArray(value)) {
    const items: TomlLiteral[] = [];
    for (const item of value) {
      const literal = toTomlLiteral(item);
      if (literal === undefined) return undefined;
      items.push(literal);
    }
    return items;
  }
  if (typeof value === "object") {
    const table: TomlTable = {};
    for (const [key, item] of Object.entries(value)) {
      const literal = toTomlLiteral(item);
      if (literal === undefined) return undefined;
      table[key] = literal;
    }
    return table;
  }
  return value;
}

/**
 * Writes the drifted settings, then restarts the processes that read them.
 *
 * @param drift - Settings to write.
 */
async function apply(drift: Drift[]): Promise<void> {
  step(`macOS settings (${drift.length} to change)`);
  const written: Drift[] = [];
  for (const setting of drift) {
    const { scope, domain, key, value } = setting;
    const result = await $`defaults ${scopeArgs(scope)} write ${domain} ${key} ${toPlistXml(value)}`.quiet().nothrow();
    if (result.exitCode === 0) {
      ok(label(setting), `${preview(setting.current)} → ${preview(value)}`);
      written.push(setting);
    } else {
      fail(label(setting), [result.stderr.toString().trim() || `defaults exited with ${result.exitCode}`]);
    }
  }

  const processes = new Set(written.flatMap(({ domain }) => (RESTART[domain] ? [RESTART[domain]] : [])));
  for (const name of processes) await $`killall ${name}`.quiet().nothrow();
  if (written.some(({ domain }) => ACTIVATED_DOMAINS.test(domain))) await $`${ACTIVATE_SETTINGS} -u`.quiet().nothrow();

  const failures = drift.length - written.length;
  if (processes.size) ok("Restarted", [...processes].join(", "));
  summary(
    failures ? `${counted(failures, "setting")} failed to apply` : "macOS settings applied; some take effect after logging out",
    failures === 0,
  );
  process.exitCode = failures ? 1 : 0;
}

/**
 * Reports drifted settings.
 *
 * @param drift - Settings whose value differs.
 */
function check(drift: Drift[]): void {
  step("macOS settings");
  for (const setting of drift) fail(label(setting), [`is ${preview(setting.current)}, want ${preview(setting.value)}`]);
  const differ = `${counted(drift.length, "setting differs", "settings differ")}; run just macos`;
  summary(drift.length ? differ : "macOS settings match", drift.length === 0);
  process.exitCode = drift.length ? 1 : 0;
}

/**
 * Lists every preference domain of a scope, plus the global domain, which
 * `defaults domains` leaves out.
 *
 * @param scope - Scope to list.
 */
async function listDomains(scope: Scope): Promise<string[]> {
  const output = await $`defaults ${scopeArgs(scope)} domains`.quiet().text();
  return ["NSGlobalDomain", ...output.split(",").map((domain) => domain.trim()).filter(Boolean)];
}

/**
 * Exports every domain of both scopes, a few at a time.
 *
 * @returns Domain XML per scope; domains that fail to export are left out.
 */
async function takeSnapshot(): Promise<Snapshot> {
  const snapshot: Snapshot = { user: {}, currentHost: {} };
  for (const scope of SCOPES) {
    const domains = await listDomains(scope);
    for (let start = 0; start < domains.length; start += EXPORT_CONCURRENCY) {
      const batch = domains.slice(start, start + EXPORT_CONCURRENCY);
      const exports = await Promise.all(batch.map((domain) => exportDomain({ scope, domain })));
      batch.forEach((domain, i) => {
        const xml = exports[i];
        if (xml !== undefined) snapshot[scope][domain] = xml;
      });
    }
  }
  return snapshot;
}

/**
 * Prints the keys that changed between two snapshots as TOML tables ready to
 * paste into `macos/defaults.toml`.
 *
 * @param before - Snapshot from the first run.
 * @param after - Snapshot taken now.
 */
function printChanges(before: Snapshot, after: Snapshot): void {
  let changed = 0;
  let hidden = 0;
  for (const scope of SCOPES) {
    const domains = new Set([...Object.keys(before[scope]), ...Object.keys(after[scope])]);
    for (const domain of [...domains].sort()) {
      if (before[scope][domain] === after[scope][domain]) continue;
      const old = domainKeys(before[scope][domain]);
      const now = domainKeys(after[scope][domain]);
      const lines: string[] = [];
      for (const key of [...new Set([...Object.keys(old), ...Object.keys(now)])].sort()) {
        if (samePlist(old[key], now[key])) continue;
        if (NOISE.test(key)) {
          hidden++;
          continue;
        }
        const value = now[key] === undefined ? undefined : toTomlLiteral(now[key]);
        if (now[key] === undefined) lines.push(`# ${tomlKey(key)} was removed (was ${preview(old[key])})`);
        else if (value === undefined) lines.push(`# ${tomlKey(key)} holds a date or data value, which the file cannot set`);
        else lines.push(`${tomlKey(key)} = ${tomlLiteral(value)}`);
      }
      if (!lines.length) continue;
      changed += lines.length;
      console.log(`\n[${scope}.${tomlKey(domain)}]\n${lines.join("\n")}`);
    }
  }
  const note = hidden ? `; ${counted(hidden, "analytics or window-state key")} hidden` : "";
  summary(changed ? `${counted(changed, "key")} changed${note}` : `No setting changed${note}`, true);
}

/**
 * First run: saves a snapshot. Second run: prints what changed since and
 * removes the snapshot.
 */
async function diff(): Promise<void> {
  const baseline = await readText(BASELINE_PATH);
  if (baseline === undefined) {
    await mkdir(dirname(BASELINE_PATH), { recursive: true });
    await Bun.write(BASELINE_PATH, JSON.stringify(await takeSnapshot()));
    await chmod(BASELINE_PATH, 0o600);
    ok("Saved a snapshot of every preference domain");
    console.log("  Change the setting in System Settings, then run just macos-diff again.");
    return;
  }
  printChanges(JSON.parse(baseline) as Snapshot, await takeSnapshot());
  await unlink(BASELINE_PATH);
}

/**
 * Runs `apply`, `check`, or `diff`.
 *
 * @param command - Subcommand from the command line.
 */
async function main(command: string | undefined): Promise<void> {
  if (command === "diff") return diff();
  if (command !== "apply" && command !== "check") throw new Error("Usage: bun macos-defaults.ts apply|check|diff");
  const drift = await findDrift(await readSettings());
  if (command === "apply") await apply(drift);
  else check(drift);
}

// doctor imports readSettings and findDrift; only a direct run acts.
if (import.meta.main) await runMain(() => main(Bun.argv[2]));
