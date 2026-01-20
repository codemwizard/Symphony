/**
 * Symphony Retry Evaluator — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Evaluates whether retry is safe for a failed execution.
 *
 * REGULATORY GUARANTEES:
 * - Retry does not create a new instruction; it re-issues the same
 *   instruction under the same idempotency key.
 * - Retries are permissioned, not automatic.
 * - Retries must be idempotent (INV-PERSIST-03).
 */

import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import { FailureClassification, RetryDecision } from './failureTypes.js';
import { isRetryable, requiresRepair } from './failureClassifier.js';
import { isTerminal } from './instructionStateClient.js';
import { DbRole } from '../db/roles.js';

/**
 * Context for retry evaluation.
 */
export interface RetryEvaluationContext {
    /** Instruction ID to evaluate */
    readonly instructionId: string;
    /** Idempotency key (must be present) */
    readonly idempotencyKey: string;
    /** Failure classification from previous attempt */
    readonly failureClassification: FailureClassification;
    /** Ingress sequence ID */
    readonly ingressSequenceId: string;
    /** Request ID for correlation */
    readonly requestId: string;
}

/**
 * Evaluate whether retry is allowed for a failed execution.
 *
 * Retry is allowed when:
 * 1. Instruction has no terminal state (.NET authority)
 * 2. Failure class allows retry
 * 3. Idempotency key is present
 *
 * @returns RetryDecision with shouldRetry, shouldRepair, and reason
 */
export async function evaluateRetry(role: DbRole, context: RetryEvaluationContext): Promise<RetryDecision> {
    const { instructionId, idempotencyKey, failureClassification, ingressSequenceId, requestId } = context;
    const failureClass = failureClassification.failureClass;

    // Pre-condition: idempotency key must be present
    if (!idempotencyKey || idempotencyKey.trim() === '') {
        const decision = createDecision(false, false, 'Missing idempotency key', instructionId, '');

        await logRetryDecision(role, requestId, ingressSequenceId, instructionId, decision, 'BLOCKED');
        return decision;
    }

    // Check 1: Failure class allows retry?
    if (!isRetryable(failureClass)) {
        // Check if repair is required instead
        if (requiresRepair(failureClass)) {
            const decision = createDecision(false, true, `Failure class ${failureClass} requires repair, not retry`, instructionId, idempotencyKey);

            await logRetryDecision(role, requestId, ingressSequenceId, instructionId, decision, 'BLOCKED');
            return decision;
        }

        const decision = createDecision(false, false, `Failure class ${failureClass} does not allow retry`, instructionId, idempotencyKey);

        await logRetryDecision(role, requestId, ingressSequenceId, instructionId, decision, 'BLOCKED');
        return decision;
    }

    // Check 2: Instruction is not in terminal state?
    const terminal = await isTerminal(instructionId);
    if (terminal) {
        const decision = createDecision(false, false, 'Instruction is already in terminal state', instructionId, idempotencyKey);

        await logRetryDecision(role, requestId, ingressSequenceId, instructionId, decision, 'BLOCKED');
        return decision;
    }

    // All checks passed: retry is allowed
    const decision = createDecision(true, false, 'Retry allowed: non-terminal instruction with retryable failure', instructionId, idempotencyKey);

    await logRetryDecision(role, requestId, ingressSequenceId, instructionId, decision, 'ALLOWED');

    logger.info({
        instructionId,
        idempotencyKey,
        failureClass,
        requestId
    }, 'Retry allowed');

    return decision;
}

function createDecision(
    shouldRetry: boolean,
    shouldRepair: boolean,
    reason: string,
    instructionId: string,
    idempotencyKey: string
): RetryDecision {
    return Object.freeze({
        shouldRetry,
        shouldRepair,
        reason,
        instructionId,
        idempotencyKey
    });
}

async function logRetryDecision(
    role: DbRole,
    requestId: string,
    ingressSequenceId: string,
    instructionId: string,
    decision: RetryDecision,
    outcome: 'ALLOWED' | 'BLOCKED'
): Promise<void> {
    await guardAuditLogger.log(role, {
        type: 'RETRY_EVALUATED',
        requestId,
        ingressSequenceId,
        instructionId,
        shouldRetry: decision.shouldRetry,
        shouldRepair: decision.shouldRepair,
        reason: decision.reason
    });

    if (outcome === 'ALLOWED') {
        await guardAuditLogger.log(role, {
            type: 'RETRY_ALLOWED',
            requestId,
            ingressSequenceId,
            instructionId
        });
    } else {
        await guardAuditLogger.log(role, {
            type: 'RETRY_BLOCKED',
            requestId,
            ingressSequenceId,
            instructionId,
            reason: decision.reason
        });
    }
}
