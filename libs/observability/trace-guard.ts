import { ValidatedIdentityContext } from "../context/identity.js";

/**
 * INV-OPS-01: Trace Context Isolation
 * Ensures that identity context does not bleed raw sensitive data into observability traces.
 */
export const traceGuard = {
    /**
     * Sanitizes identity context for tracing.
     * Explicitly strips all claims and non-essential metadata.
     */
    sanitizeForTrace: (context: ValidatedIdentityContext) => {
        // We only propagate structural identifiers and routing context
        return {
            traceId: context.requestId, // We use requestId as the root trace identifier
            tenantId: context.tenantId,
            origin: context.issuerService,
            subjectType: context.subjectType
            // subjectId and raw claims are EXCLUDED to prevent identity-trace overlap (INV-OPS-01)
        };
    }
};
