import { cryptoAudit } from '../crypto/keyManager.js';
import { logger } from '../logging/logger.js';
import crypto from 'crypto';

/**
 * HIGH-SEC-003: Error Information Disclosure Prevention
 * Sanitizes internal errors by wrapping them in a generic message
 * and providing a unique IncidentID for log correlation.
 */

export class SymphonyError extends Error {
    public readonly incidentId: string;
    public readonly timestamp: string;

    constructor(
        public readonly publicMessage: string,
        public readonly internalDetails?: any,
        public readonly category: 'SEC' | 'OPS' | 'FIN' = 'OPS'
    ) {
        super(publicMessage);
        this.incidentId = crypto.randomUUID();
        this.timestamp = new Date().toISOString();

        // Log the full internal details with the IncidentID
        logger.error({
            incidentId: this.incidentId,
            category: this.category,
            internalDetails,
            stack: this.stack
        }, publicMessage);
    }
}

export const ErrorSanitizer = {
    /**
     * Catches and wraps any error into a sanitized SymphonyError.
     */
    sanitize: (err: any, contextLabel: string): SymphonyError => {
        // If it's already a SymphonyError, just return it
        if (err instanceof SymphonyError) return err;

        // Otherwise, wrap it to hide raw DB/Stack details
        return new SymphonyError(
            `An internal system error occurred. Please contact support with ID: ${contextLabel}`,
            { originalError: err.message, stack: err.stack, context: contextLabel },
            'OPS'
        );
    }
};
