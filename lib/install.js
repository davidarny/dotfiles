import os from "node:os";
import fs from "node:fs";
import fsp from "node:fs/promises";
import cp from "node:child_process";
import ps from "node:process";
import chalk from "chalk";
import inquirer from "inquirer";
import { packages } from "./packages.js";
import { panic } from "./handle.js";
import { logger } from "./log.js";

const cwd = ps.cwd();
const homedir = os.homedir();

const answers = await inquirer.prompt([
  {
    type: "checkbox",
    name: "selected",
    message: "Select packages to link:",
    choices: packages,
  },
]);

if (!answers.selected.length) {
  panic("No packages selected");
}

for (const module of answers.selected) {
  const anchor = await fsp.readFile(`./packages/${module}/.anchor`, "utf8");
  const target = (homedir + (anchor ? "/" + anchor : "")).trim();
  logger.info(`☐ Linking package ${chalk.blue(module)} to target ${chalk.blue(target)}`);

  const cmd = `stow --ignore='\.anchor' --target ${target} ${module}`;
  const wd = `${cwd}/packages`;

  if (!fs.existsSync(target)) {
    await fsp.mkdir(target, { recursive: true });
  }

  logger.info(`☐ Executing command "${chalk.blue(cmd)}"`);
  cp.execSync(cmd, { cwd: wd });
  logger.info(`☑︎ Package ${chalk.blue(module)} linked to ${chalk.blue(target)}`);
}
