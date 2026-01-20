/**
 * Symphony Idempotency Guard — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Pre-flight idempotency check to prevent duplicate instruction creation.
 *
 * INVARIANT BINDING:
 * IdempotencyGuard enforces INV-PERSIST-03 before instruction creation.
 *
 * REGULATORY GUARANTEE:
 * Retry does not create a new instruction; it re-issues the same
 * instruction under the same idempotency key.
 */

import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import { db } from '../db/index.js';
import { DbRole } from '../db/roles.js';

/**
 * Idempotency guard context.
 */
export interface IdempotencyGuardContext {
    /** Idempotency key from request */
    readonly idempotencyKey: string;
    /** Request ID for correlation */
    readonly requestId: string;
    /** Ingress sequence ID */
    readonly ingressSequenceId: string;
    /** Participant ID */
    readonly participantId: string;
}

/**
 * Idempotency guard result.
 */
export type IdempotencyGuardResult =
    | { allowed: true; isRetry: false }
    | { allowed: true; isRetry: true; existingInstructionId: string }
    | { allowed: false; reason: IdempotencyDenyReason };

export type IdempotencyDenyReason =
    | 'INVALID_KEY_FORMAT'
    | 'KEY_TOO_SHORT'
    | 'KEY_TOO_LONG'
    | 'DUPLICATE_WITH_TERMINAL_STATE';

/**
 * Idempotency key format requirements.
 */
const MIN_KEY_LENGTH = 16;
const MAX_KEY_LENGTH = 128;
const KEY_PATTERN = /^[a-zA-Z0-9_-]+$/;

/**
 * Execute idempotency guard.
 *
 * Enforces INV-PERSIST-03: Retries must be idempotent.
 */
export async function executeIdempotencyGuard(
    role: DbRole,
    context: IdempotencyGuardContext
): Promise<IdempotencyGuardResult> {
    const { idempotencyKey, requestId, ingressSequenceId, participantId } = context;

    // Validate key format
    const validationResult = validateKeyFormat(idempotencyKey);
    if (validationResult.valid === false) {
        await logDenial(role, requestId, ingressSequenceId, participantId, validationResult.reason);
        return { allowed: false, reason: validationResult.reason };
    }


    // Check for existing instruction with same key
    const existing = await findExistingInstruction(role, idempotencyKey, participantId);

    if (!existing) {
        // No existing instruction — new creation allowed
        logger.debug({
            requestId,
            idempotencyKey,
            participantId
        }, 'Idempotency guard passed: new instruction');

        return { allowed: true, isRetry: false };
    }

    // Existing instruction found — check if it's terminal
    if (existing.isTerminal) {
        // Terminal instruction cannot be retried
        await logDenial(role, requestId, ingressSequenceId, participantId, 'DUPLICATE_WITH_TERMINAL_STATE');
        return { allowed: false, reason: 'DUPLICATE_WITH_TERMINAL_STATE' };
    }

    // Non-terminal instruction — this is a valid retry
    logger.info({
        requestId,
        idempotencyKey,
        existingInstructionId: existing.instructionId
    }, 'Idempotency guard passed: valid retry');

    return {
        allowed: true,
        isRetry: true,
        existingInstructionId: existing.instructionId
    };
}

/**
 * Validate idempotency key format.
 */
function validateKeyFormat(key: string): { valid: true } | { valid: false; reason: IdempotencyDenyReason } {
    if (!key || key.length < MIN_KEY_LENGTH) {
        return { valid: false, reason: 'KEY_TOO_SHORT' };
    }

    if (key.length > MAX_KEY_LENGTH) {
        return { valid: false, reason: 'KEY_TOO_LONG' };
    }

    if (!KEY_PATTERN.test(key)) {
        return { valid: false, reason: 'INVALID_KEY_FORMAT' };
    }

    return { valid: true };
}

interface ExistingInstruction {
    instructionId: string;
    isTerminal: boolean;
}

/**
 * Find existing instruction by idempotency key.
 */
async function findExistingInstruction(
    role: DbRole,
    idempotencyKey: string,
    participantId: string
): Promise<ExistingInstruction | null> {
    // Query local idempotency tracking table
    const result = await db.queryAsRole(
        role,
        `SELECT instruction_id, is_terminal
         FROM instruction_idempotency
         WHERE idempotency_key = $1 AND participant_id = $2
         LIMIT 1`,
        [idempotencyKey, participantId]
    );

    if (result.rows.length === 0) {
        return null;
    }

    const row = result.rows[0] as { instruction_id: string; is_terminal: boolean };
    return {
        instructionId: row.instruction_id,
        isTerminal: row.is_terminal
    };
}

async function logDenial(
    role: DbRole,
    requestId: string,
    ingressSequenceId: string,
    participantId: string,
    reason: IdempotencyDenyReason
): Promise<void> {
    logger.warn({
        requestId,
        participantId,
        reason
    }, 'Idempotency guard denied request');

    await guardAuditLogger.log(role, {
        type: 'GUARD_POLICY_DENY', // Reuse existing guard event type
        requestId,
        ingressSequenceId,
        participantId,
        reason: `IDEMPOTENCY: ${reason}`
    });
}
