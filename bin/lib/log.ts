/**
 * Console output shared by the bin scripts.
 *
 * Colors are the 16 standard ANSI colors, so they follow whatever theme the
 * terminal uses. `styleText` drops them when stdout is not a TTY or NO_COLOR is
 * set, so piped output stays plain text. (`Bun.color` would emit fixed RGB
 * values instead of theme colors.)
 */
import { styleText } from "node:util";

/**
 * Prints a section header, e.g. `▸ Global skills`.
 *
 * @param title - Section name.
 */
export function step(title: string): void {
  console.log(`\n${styleText("blue", "▸")} ${styleText("bold", title)}`);
}

/**
 * Prints a success line with an optional dimmed detail aligned after it.
 *
 * @param text - What succeeded.
 * @param detail - Extra context, such as a source or a path.
 */
export function ok(text: string, detail?: string): void {
  const line = detail ? `${text.padEnd(28)} ${styleText("dim", detail)}` : text;
  console.log(`  ${styleText("green", "✓")} ${line}`);
}

/**
 * Prints a failure line followed by indented detail lines.
 *
 * @param text - What failed.
 * @param details - One line per problem or hint.
 */
export function fail(text: string, details: string[] = []): void {
  console.log(`  ${styleText("red", "✗")} ${text}`);
  for (const detail of details) console.log(`    ${styleText("dim", `└ ${detail}`)}`);
}

/**
 * Prints the closing summary line with the time since the script started.
 *
 * @param text - Summary, e.g. `All 9 checks passed`.
 * @param success - Whether the run succeeded; picks green or red.
 */
export function summary(text: string, success: boolean): void {
  // Bun.nanoseconds() counts from process start.
  const seconds = (Bun.nanoseconds() / 1e9).toFixed(1);
  const mark = success ? styleText("green", "✓") : styleText("red", "✗");
  console.log(`\n${mark} ${styleText("bold", text)} ${styleText("dim", `in ${seconds}s`)}`);
}
