/**
 * XML property lists: parsing `defaults export` output and serializing values
 * for `defaults write`, which accepts an XML plist fragment as the value and
 * keeps its types. (`plutil -convert json` cannot help: it rejects the `date`
 * and `data` values many preference domains hold.)
 */

/** A value in a property list. Integers and reals both become numbers. */
export type PlistValue = string | number | boolean | Date | Uint8Array | PlistValue[] | PlistDict;

/** A property list dictionary. */
export interface PlistDict {
  [key: string]: PlistValue;
}

/** One XML token: a tag or the text between tags. */
interface Token {
  kind: "open" | "close" | "empty" | "text";
  /** Tag name for tags, e.g. `dict`; empty for text. */
  name: string;
  /** Decoded text for text tokens; empty for tags. */
  text: string;
}

/** Position in the token list while parsing. */
interface Cursor {
  tokens: Token[];
  index: number;
}

/** A tag without attributes, or a run of text. */
const TOKEN = /<(\/?)([a-z]+)\s*(\/?)>|([^<]+)/g;

/** XML entities plists use in strings and keys. */
const ENTITIES: Record<string, string> = { amp: "&", lt: "<", gt: ">", quot: '"', apos: "'" };

/**
 * Decodes XML entities, including numeric ones.
 *
 * @param text - Raw text between tags.
 */
function decode(text: string): string {
  return text.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (entity, body: string) => {
    if (body[0] !== "#") return ENTITIES[body] ?? entity;
    const hex = body[1] === "x" || body[1] === "X";
    return String.fromCodePoint(Number.parseInt(body.slice(hex ? 2 : 1), hex ? 16 : 10));
  });
}

/**
 * Escapes text for an XML element.
 *
 * @param text - Text to escape.
 */
function escape(text: string): string {
  return text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
}

/**
 * Splits the body of a plist (inside `<plist>`) into tokens, dropping the
 * whitespace between elements but keeping all text inside `<string>` and
 * `<key>`, where spaces are content.
 *
 * @param body - XML inside the `<plist>` element.
 */
function tokenize(body: string): Token[] {
  const tokens: Token[] = [];
  for (const [, slash, name, selfClosing, text] of body.matchAll(TOKEN)) {
    if (text !== undefined) {
      const previous = tokens.at(-1);
      const isContent = previous?.kind === "open" && (previous.name === "string" || previous.name === "key");
      if (isContent || text.trim()) tokens.push({ kind: "text", name: "", text: decode(text) });
    } else {
      tokens.push({ kind: slash ? "close" : selfClosing ? "empty" : "open", name, text: "" });
    }
  }
  return tokens;
}

/**
 * Reads the text of a `<key>`, `<string>`, or scalar element whose opening tag
 * was just consumed, and its closing tag. An element may be empty.
 *
 * @param cursor - Parser position.
 * @param name - Element name.
 */
function readText(cursor: Cursor, name: string): string {
  const token = cursor.tokens[cursor.index];
  const text = token?.kind === "text" ? token.text : "";
  if (token?.kind === "text") cursor.index++;
  const close = cursor.tokens[cursor.index++];
  if (close?.kind !== "close" || close.name !== name) throw new Error(`Malformed plist: unclosed <${name}>`);
  return text;
}

/**
 * Parses the value at the cursor.
 *
 * @param cursor - Parser position; advanced past the value.
 */
function parseValue(cursor: Cursor): PlistValue {
  const token = cursor.tokens[cursor.index++];
  if (!token || token.kind === "close" || token.kind === "text") throw new Error("Malformed plist: expected a value");

  if (token.kind === "empty") {
    switch (token.name) {
      case "true":
        return true;
      case "false":
        return false;
      case "string":
        return "";
      case "array":
        return [];
      case "dict":
        return {};
      case "data":
        return new Uint8Array();
      default:
        throw new Error(`Malformed plist: unexpected <${token.name}/>`);
    }
  }

  switch (token.name) {
    case "string":
      return readText(cursor, "string");
    case "integer":
    case "real":
      return Number(readText(cursor, token.name));
    case "date":
      return new Date(readText(cursor, "date"));
    case "data":
      return Uint8Array.from(Buffer.from(readText(cursor, "data").replace(/\s+/g, ""), "base64"));
    case "array": {
      const items: PlistValue[] = [];
      while (cursor.tokens[cursor.index]?.kind !== "close") items.push(parseValue(cursor));
      cursor.index++;
      return items;
    }
    case "dict": {
      const dict: PlistDict = {};
      while (cursor.tokens[cursor.index]?.kind !== "close") {
        const key = cursor.tokens[cursor.index++];
        if (key?.name !== "key") throw new Error("Malformed plist: expected <key>");
        const name = key.kind === "empty" ? "" : readText(cursor, "key");
        dict[name] = parseValue(cursor);
      }
      cursor.index++;
      return dict;
    }
    default:
      throw new Error(`Malformed plist: unexpected <${token.name}>`);
  }
}

/**
 * Parses an XML property list, such as `defaults export <domain> -` prints.
 *
 * @param xml - Complete XML plist document.
 * @throws When the document is not a well-formed XML plist.
 */
export function parsePlist(xml: string): PlistValue {
  const body = xml.match(/<plist[^>]*>([\s\S]*)<\/plist>/)?.[1];
  if (body === undefined) throw new Error("Malformed plist: no <plist> element");
  const cursor: Cursor = { tokens: tokenize(body), index: 0 };
  const value = parseValue(cursor);
  if (cursor.index !== cursor.tokens.length) throw new Error("Malformed plist: trailing content");
  return value;
}

/**
 * Serializes a value as an XML plist fragment, the form `defaults write`
 * takes to keep types. Whole numbers become integers, others reals.
 *
 * @param value - Value to serialize.
 */
export function toPlistXml(value: PlistValue): string {
  if (typeof value === "string") return `<string>${escape(value)}</string>`;
  if (typeof value === "boolean") return value ? "<true/>" : "<false/>";
  if (typeof value === "number") return Number.isInteger(value) ? `<integer>${value}</integer>` : `<real>${value}</real>`;
  if (value instanceof Date) return `<date>${value.toISOString().replace(/\.\d{3}Z$/, "Z")}</date>`;
  if (value instanceof Uint8Array) return `<data>${Buffer.from(value).toString("base64")}</data>`;
  if (Array.isArray(value)) return `<array>${value.map(toPlistXml).join("")}</array>`;
  const entries = Object.entries(value).map(([key, item]) => `<key>${escape(key)}</key>${toPlistXml(item)}`);
  return `<dict>${entries.join("")}</dict>`;
}

/**
 * Compares two plist values structurally. Numbers compare by value, so an
 * integer and a real with the same value are equal; dictionary key order does
 * not matter.
 *
 * @param a - First value; `undefined` for a missing key.
 * @param b - Second value; `undefined` for a missing key.
 */
export function samePlist(a: PlistValue | undefined, b: PlistValue | undefined): boolean {
  if (a instanceof Date || b instanceof Date) {
    return a instanceof Date && b instanceof Date && a.getTime() === b.getTime();
  }
  if (a instanceof Uint8Array || b instanceof Uint8Array) {
    return a instanceof Uint8Array && b instanceof Uint8Array && Buffer.from(a).equals(Buffer.from(b));
  }
  if (Array.isArray(a) || Array.isArray(b)) {
    return Array.isArray(a) && Array.isArray(b) && a.length === b.length && a.every((item, i) => samePlist(item, b[i]));
  }
  if (typeof a === "object" && typeof b === "object") {
    const keys = Object.keys(a);
    return keys.length === Object.keys(b).length && keys.every((key) => key in b && samePlist(a[key], b[key]));
  }
  return a === b;
}
