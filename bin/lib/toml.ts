/**
 * TOML output for the scripts that write TOML: keys and inline values. Bun
 * parses TOML but has no writer.
 */

/** A value that can be written inline in TOML. */
export type TomlLiteral = string | number | boolean | TomlLiteral[] | TomlTable;

/** A TOML table, written inline as `{ key = value }`. */
export interface TomlTable {
  [key: string]: TomlLiteral;
}

/** A key that TOML accepts without quotes. */
const BARE_KEY = /^[A-Za-z0-9_-]+$/;

/**
 * Formats a key, quoting it when it is not a bare key.
 *
 * @param key - Key to format.
 */
export function tomlKey(key: string): string {
  return BARE_KEY.test(key) ? key : tomlString(key);
}

/**
 * Formats a basic string. JSON escapes are valid TOML escapes; DEL, which JSON
 * leaves as is, must be escaped in TOML.
 *
 * @param text - String to format.
 */
function tomlString(text: string): string {
  return JSON.stringify(text).replaceAll("\u007f", "\\u007F");
}

/**
 * Formats a value inline: strings, numbers, booleans, arrays, and tables.
 *
 * @param value - Value to format.
 */
export function tomlLiteral(value: TomlLiteral): string {
  if (typeof value === "string") return tomlString(value);
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  if (Array.isArray(value)) return `[${value.map(tomlLiteral).join(", ")}]`;
  const entries = Object.entries(value).map(([key, item]) => `${tomlKey(key)} = ${tomlLiteral(item)}`);
  return entries.length ? `{ ${entries.join(", ")} }` : "{}";
}
