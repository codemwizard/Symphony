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
    public readonly contextLabel?: string;
    public readonly sqlState?: string;
    public override cause?: unknown;

    constructor(
        public readonly publicMessage: string,
        public readonly internalDetails?: unknown,
        public readonly category: 'SEC' | 'OPS' | 'FIN' = 'OPS',
        options?: { cause?: unknown; contextLabel?: string; sqlState?: string }
    ) {
        super(publicMessage);
        this.incidentId = crypto.randomUUID();
        this.timestamp = new Date().toISOString();
        this.contextLabel = options?.contextLabel;
        this.sqlState = options?.sqlState;
        this.cause = options?.cause;

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
        let sqlState: string | undefined;

        if (err instanceof Error) {
            originalErrorMessage = err.message;
            originalErrorStack = err.stack;
            sqlState = typeof (err as { code?: unknown }).code === 'string'
                ? ((err as { code?: string }).code)
                : undefined;
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
            if (typeof errObj.code === 'string') {
                sqlState = errObj.code;
            }
        } else {
            originalErrorMessage = String(err);
        }

        // Otherwise, wrap it to hide raw DB/Stack details
        return new SymphonyError(
            `An internal system error occurred. Please contact support with ID: ${contextLabel}`,
            { originalError: originalErrorMessage, stack: originalErrorStack, context: contextLabel },
            'OPS',
            { cause: err, contextLabel, sqlState }
        );
    }
};
