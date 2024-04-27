import fs from "node:fs/promises";
import { isNotJunk } from "junk";

const files = await fs.readdir("./packages");
export const packages = files.filter(isNotJunk);
