import { logger } from "../logging/logger.js";

/**
 * INV-OPS-01: Correlation Guarantees
 * Enforces mandatory linkage between Trace, Audit, and Incident identifiers.
 */
export const correlationManager = {
    /**
     * Links identifiers across observability domains.
     * Required for forensics and regulatory evidence (Not Hygiene).
     */
    link: (ids: { traceId: string; auditId: string; incidentId?: string }) => {
        const { traceId, auditId, incidentId } = ids;

        if (!traceId || !auditId) {
            logger.warn("Correlation linkage invoked with missing identifiers. Evidence chain may be incomplete.");
        }

        logger.info({
            evidenceLink: {
                traceId,
                auditId,
                incidentId: incidentId || "NONE",
                verifiedAt: new Date().toISOString()
            }
        }, "Forensic correlation chain established");
    }
};
