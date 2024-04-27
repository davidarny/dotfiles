import ps from "node:process";
import { logger } from "./log.js";

export const panic = (...args) => {
  logger.error(...args);
  ps.exit(-1);
};
