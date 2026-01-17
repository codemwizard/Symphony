import { ZodSchema } from 'zod';
import { logger } from '../logging/logger.js';

/**
 * HIGH-SEC-002: Validation Middleware
 * Returns a validation function that throws a strictly typed error on failure.
 * Used for "Fail-Closed" ingress validation.
 */
export function validate<T>(schema: ZodSchema<T>, data: unknown, context: string): T {
    const result = schema.safeParse(data);

    if (!result.success) {
        const errorDetails = result.error.issues.map(e => ({
            path: e.path.join('.'),
            message: e.message
        }));


        logger.warn({
            context,
            errors: errorDetails,
            // Don't log full data if it contains PII/Credentials, but for strict-typed schemas it's usually safe structures
            // We'll log a redacted summary or just the fact it failed.
        }, "Input Validation Failure (HIGH-SEC-002)");

        throw new Error(`Validation Violation in ${context}: ${JSON.stringify(errorDetails)}`);
    }

    return result.data;
}

/**
 * Factory for creating verified envelope validators.
 */
export const createValidator = <T>(schema: ZodSchema<T>) => {
    return (data: unknown, contextLabel: string) => validate(schema, data, contextLabel);
};
