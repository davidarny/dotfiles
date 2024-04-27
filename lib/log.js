import chalk from "chalk";

export const logger = {
  info(...args) {
    console.log(chalk.green(...args));
  },

  error(...args) {
    console.log(chalk.red(...args));
  },

  warn(...args) {
    console.log(chalk.yellow(...args));
  },
};
