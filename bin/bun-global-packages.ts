interface BunGlobalManifest {
  dependencies?: Record<string, string>;
}

const path = process.argv[2];

if (!path) {
  throw new Error("Usage: bun bun-global-packages.ts <manifest>");
}

const manifest = (await Bun.file(path).json()) as BunGlobalManifest;

for (const [name, version] of Object.entries(manifest.dependencies ?? {})) {
  console.log(`${name}@${version}`);
}
