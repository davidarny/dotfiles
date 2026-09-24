/**
 * JSON files as the scripts read and write them: parse errors name the file,
 * and output matches the two-space style the agents write.
 */
import { readText } from "./fs";

/**
 * Formats a value as JSON the way the agents write it.
 *
 * @param value - Value to serialize.
 */
export function formatJson(value: unknown): string {
  return `${JSON.stringify(value, null, 2)}\n`;
}

/**
 * Serializes a value with object keys sorted, so key order does not affect a
 * comparison.
 *
 * @param value - Value to serialize.
 */
export function canonicalJson(value: unknown): string {
  return JSON.stringify(value, (_key, item: unknown) =>
    item && typeof item === "object" && !Array.isArray(item)
      ? Object.fromEntries(Object.entries(item).sort(([a], [b]) => a.localeCompare(b)))
      : item,
  );
}

/**
 * Reads and parses a JSON file.
 *
 * @param path - File to read.
 * @returns The parsed value, or `undefined` when the file does not exist.
 * @throws When the file is not valid JSON, naming the file.
 */
export async function readJson<T>(path: string): Promise<T | undefined> {
  const text = await readText(path);
  if (text === undefined) return undefined;
  try {
    return JSON.parse(text) as T;
  } catch (error) {
    throw new Error(`${path}: ${error instanceof Error ? error.message : String(error)}`);
  }
}
