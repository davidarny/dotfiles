import { expect, test } from "bun:test";
import { type PlistValue, parsePlist, samePlist, toPlistXml } from "./plist";

/**
 * Wraps a fragment in a plist document, as `defaults export` prints one.
 *
 * @param fragment - XML of the root value.
 */
function document(fragment: string): string {
  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
${fragment}
</plist>
`;
}

test("parses every plist type, including empty and whitespace-only elements", () => {
  const xml = document(`<dict>
	<key>bool</key>
	<true/>
	<key>int</key>
	<integer>-3</integer>
	<key>real</key>
	<real>0.25</real>
	<key>text</key>
	<string>a &amp; &lt;b&gt; &#x201C;q&#8221;</string>
	<key>space</key>
	<string> </string>
	<key>empty</key>
	<string/>
	<key>date</key>
	<date>2026-09-23T10:46:45Z</date>
	<key>data</key>
	<data>
	AQID
	</data>
	<key>list</key>
	<array>
		<dict>
			<key>on</key>
			<integer>1</integer>
		</dict>
		<array/>
	</array>
	<key>nested</key>
	<dict/>
</dict>`);

  const value = parsePlist(xml) as Record<string, PlistValue>;

  expect(value.bool).toBe(true);
  expect(value.int).toBe(-3);
  expect(value.real).toBe(0.25);
  expect(value.text).toBe("a & <b> “q”");
  expect(value.space).toBe(" ");
  expect(value.empty).toBe("");
  expect(value.date).toEqual(new Date("2026-09-23T10:46:45Z"));
  expect(value.data).toEqual(new Uint8Array([1, 2, 3]));
  expect(value.list).toEqual([{ on: 1 }, []]);
  expect(value.nested).toEqual({});
});

test("serializing and parsing back keeps the value", () => {
  const value: PlistValue = {
    "key with <special> & chars": [true, false, 2, 1.5, "x", { deep: [" "] }],
    date: new Date("2026-01-02T03:04:05Z"),
    data: new Uint8Array([0, 255]),
  };

  expect(samePlist(parsePlist(document(toPlistXml(value))), value)).toBe(true);
});

test("whole numbers serialize as integers and fractions as reals", () => {
  expect(toPlistXml(15)).toBe("<integer>15</integer>");
  expect(toPlistXml(0.25)).toBe("<real>0.25</real>");
});

test("samePlist compares by value and ignores dictionary key order", () => {
  expect(samePlist({ a: 1, b: [2] }, { b: [2], a: 1 })).toBe(true);
  expect(samePlist(2, 2.0)).toBe(true);
  expect(samePlist(0, false)).toBe(false);
  expect(samePlist({ a: 1 }, { a: 1, b: 2 })).toBe(false);
  expect(samePlist(undefined, 0)).toBe(false);
});

test("malformed input fails instead of returning a partial value", () => {
  expect(() => parsePlist("<dict></dict>")).toThrow("no <plist> element");
  expect(() => parsePlist(document("<dict><key>a</key></dict>"))).toThrow();
  expect(() => parsePlist(document("<string>a"))).toThrow("unclosed <string>");
});
