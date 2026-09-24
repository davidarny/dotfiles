// Versioned imports that Bun auto-installs at run time; TypeScript cannot
// resolve a version in the specifier, so declare what the scripts use.
declare module "dotenv@16.6.1" {
  export function parse(src: string): Record<string, string>;
}
