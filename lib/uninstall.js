import os from "node:os";
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
    message: "Select packages to unlink:",
    choices: packages,
  },
]);

if (!answers.selected.length) {
  panic("No packages selected");
}

for (const module of answers.selected) {
  const target = homedir.trim();
  logger.warn(`☐ Unlinking package ${chalk.blue(module)} at target ${chalk.blue(target)}`);

  const cmd = `stow --delete --target ${target} ${module}`;
  const wd = `${cwd}/packages`;

  logger.info(`☐ Executing command "${chalk.blue(cmd)}"`);
  cp.execSync(cmd, { cwd: wd });
  logger.info(`☑︎ Package ${chalk.blue(module)} is unlinked`);
}
