import pino from "pino";
import { ValidatedIdentityContext } from "../context/identity.js";

import { REDACT_KEYS, REDACT_CENSOR } from "./redactionConfig.js";

export const logger = pino({
  level: "info",
  base: {
    system: "symphony"
  },
  redact: {
    paths: REDACT_KEYS,
    censor: REDACT_CENSOR
  }
});

/**
 * Returns a child logger with identity context attached.
 */
export function getContextLogger(context: ValidatedIdentityContext) {
  return logger.child({
    requestId: context.requestId,
    subjectId: context.subjectId,
    issuerService: context.issuerService,
    tenantId: context.tenantId
  });
}
