import { db } from "../db/index.js";
import { logger } from "../logging/logger.js";
import { ErrorSanitizer } from "../errors/sanitizer.js";
import { DbRole } from "../db/roles.js";

/**
 * SYM-OPS-002: Idempotency Enforcement
 * Ensures financial operations are executed exactly once per unique request ID.
 */
export class IdempotencyGuard {
    /**
     * Attempts to claim a request ID for execution.
     * Returns true if the ID is new and claimed, false if it's already being processed or completed.
     */
    static async claim(role: DbRole, idempotencyKey: string): Promise<boolean> {
        try {
            // Use an UPSERT or specific INSERT to claim the key
            // This assumes an 'idempotency_keys' table exists.
            await db.queryAsRole(
                role,
                "INSERT INTO idempotency_keys (key, status, created_at) VALUES ($1, 'PROCESSING', NOW())",
                [idempotencyKey]
            );
            return true;
        } catch (err: unknown) {
            if (typeof err === 'object' && err !== null && 'code' in err && (err as { code: unknown }).code === '23505') { // Unique violation
                logger.info({ idempotencyKey }, "IdempotencyGuard: Key already exists");
                return false;
            }
            throw ErrorSanitizer.sanitize(err, "IdempotencyGuard:ClaimFailure");
        }
    }

    /**
     * Marks a request ID as completed with a response snapshot.
     */
    static async finalize(role: DbRole, idempotencyKey: string, responseSnapshot: unknown): Promise<void> {
        try {
            await db.queryAsRole(
                role,
                "UPDATE idempotency_keys SET status = 'COMPLETED', response = $2, updated_at = NOW() WHERE key = $1",
                [idempotencyKey, JSON.stringify(responseSnapshot)]
            );
        } catch (err: unknown) {
            throw ErrorSanitizer.sanitize(err, "IdempotencyGuard:FinalizeFailure");
        }
    }
}
