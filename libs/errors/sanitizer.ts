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
        public readonly internalDetails?: unknown,
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
    sanitize: (err: unknown, contextLabel: string): SymphonyError => {
        // If it's already a SymphonyError, just return it
        if (err instanceof SymphonyError) return err;

        let originalErrorMessage: string | undefined;
        let originalErrorStack: string | undefined;

        if (err instanceof Error) {
            originalErrorMessage = err.message;
            originalErrorStack = err.stack;
        } else if (typeof err === 'string') {
            originalErrorMessage = err;
        } else if (err && typeof err === 'object' && 'message' in err) {
            const errObj = err as Record<string, unknown>;
            if (typeof errObj.message === 'string') {
                originalErrorMessage = errObj.message;
            }
            if (typeof errObj.stack === 'string') {
                originalErrorStack = errObj.stack;
            }
        } else {
            originalErrorMessage = String(err);
        }

        // Otherwise, wrap it to hide raw DB/Stack details
        return new SymphonyError(
            `An internal system error occurred. Please contact support with ID: ${contextLabel}`,
            { originalError: originalErrorMessage, stack: originalErrorStack, context: contextLabel },
            'OPS'
        );
    }
};
