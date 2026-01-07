import pino from "pino";
import { ValidatedIdentityContext } from "../context/identity";

export const logger = pino({
  level: "info",
  base: {
    system: "symphony"
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
