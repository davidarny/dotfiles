import { readFileSync, statSync } from 'node:fs';
import { parse } from 'dotenv@16.6.1';

try {
  let files = process.argv.slice(2);
  if (files.length === 0) {
    files = ['.env', '.env.local'].filter((file) => {
      try {
        statSync(file);
        return true;
      } catch (error) {
        if (error.code === 'ENOENT') return false;
        throw error;
      }
    });
    if (files.length === 0) throw new Error('no .env or .env.local found');
  }

  const values = new Map();
  for (const file of files) {
    const stat = statSync(file);
    if (!stat.isFile() && !stat.isFIFO()) {
      throw new Error(`${JSON.stringify(file)}: expected a regular file or FIFO`);
    }
    const content = readFileSync(file, 'utf8');
    if (content.includes('\0')) throw new Error(`${JSON.stringify(file)}: NUL bytes are not supported`);
    for (const [key, value] of Object.entries(parse(content))) {
      if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key)) {
        throw new Error(`${JSON.stringify(file)}: invalid environment variable name`);
      }
      values.set(key, value);
    }
  }

  process.stdout.write([...values].map(([key, value]) => `${key}\0${value}\0`).join(''));
} catch (error) {
  // Quote paths to escape control characters; never print file contents or values.
  const path = error.path ? `${JSON.stringify(error.path)}: ` : '';
  console.error(`dotenv: ${path}${error.code || error.message}`);
  process.exitCode = 1;
}
