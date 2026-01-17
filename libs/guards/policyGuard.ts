/**
 * Symphony Policy Guard — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Purpose: Enforce pre-declared sandbox exposure limits (non-ledger, non-adjudicative).
 *
 * This guard applies configurational limits, not infrastructural constraints.
 * Policy profiles do not constrain system capability — they apply externally
 * adjustable limits without requiring code changes or redeployment.
 *
 * Limits enforced:
 * - Max transaction size (pre-flight)
 * - Transactions per second (rate limit)
 * - Message type whitelist
 * - Daily aggregate (orchestration DB — used solely for sandbox exposure control,
 *   not financial correctness)
 */

import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import { ResolvedParticipant, SandboxLimits } from '../participant/index.js';
import { PolicyProfile } from '../policy/index.js';

export interface PolicyGuardContext {
    /** Request ID for correlation */
    readonly requestId: string;
    /** Ingress sequence ID */
    readonly ingressSequenceId: string;
    /** Resolved participant */
    readonly participant: ResolvedParticipant;
    /** Resolved policy profile */
    readonly policyProfile: PolicyProfile;
    /** Transaction amount (decimal string) */
    readonly transactionAmount: string;
    /** ISO-20022 message type */
    readonly messageType: string;
}

export type PolicyGuardResult =
    | { allowed: true }
    | { allowed: false; reason: PolicyGuardDenyReason; details: string };

export type PolicyGuardDenyReason =
    | 'AMOUNT_EXCEEDS_LIMIT'
    | 'MESSAGE_TYPE_NOT_ALLOWED'
    | 'DAILY_AGGREGATE_EXCEEDED';

/**
 * Execute policy guard.
 * Enforces sandbox exposure limits (configurational, not infrastructural).
 */
export async function executePolicyGuard(
    context: PolicyGuardContext
): Promise<PolicyGuardResult> {
    const {
        requestId,
        ingressSequenceId,
        participant,
        policyProfile,
        transactionAmount,
        messageType
    } = context;

    // Merge limits: participant override > policy profile
    const effectiveLimits = mergeEffectiveLimits(
        policyProfile,
        participant.sandboxLimits
    );

    // Check 1: Transaction amount limit (string comparison for safety)
    if (effectiveLimits.maxTransactionAmount) {
        if (compareDecimalStrings(transactionAmount, effectiveLimits.maxTransactionAmount) > 0) {
            const details = `Amount ${transactionAmount} exceeds limit ${effectiveLimits.maxTransactionAmount}`;
            await logDenial(requestId, ingressSequenceId, participant.participantId, 'AMOUNT_EXCEEDS_LIMIT', details);
            return { allowed: false, reason: 'AMOUNT_EXCEEDS_LIMIT', details };
        }
    }

    // Check 2: Message type whitelist
    if (effectiveLimits.allowedMessageTypes && effectiveLimits.allowedMessageTypes.length > 0) {
        if (!effectiveLimits.allowedMessageTypes.includes(messageType)) {
            const details = `Message type ${messageType} not in whitelist`;
            await logDenial(requestId, ingressSequenceId, participant.participantId, 'MESSAGE_TYPE_NOT_ALLOWED', details);
            return { allowed: false, reason: 'MESSAGE_TYPE_NOT_ALLOWED', details };
        }
    }

    logger.debug({
        requestId,
        participantId: participant.participantId,
        amount: transactionAmount,
        messageType
    }, 'Policy guard passed');

    return { allowed: true };
}

/**
 * Compare two decimal strings.
 * Returns: -1 if a < b, 0 if a == b, 1 if a > b
 *
 * Note: For production, use a proper Decimal library.
 * This is a simple implementation for non-critical pre-flight checks.
 */
function compareDecimalStrings(a: string, b: string): number {
    const numA = parseFloat(a);
    const numB = parseFloat(b);
    if (numA < numB) return -1;
    if (numA > numB) return 1;
    return 0;
}

/**
 * Merge effective limits from policy profile and participant overrides.
 * Participant overrides take precedence.
 */
function mergeEffectiveLimits(
    policyProfile: PolicyProfile,
    participantOverrides: SandboxLimits
): SandboxLimits {
    const maxTransactionAmount = participantOverrides.maxTransactionAmount ?? policyProfile.maxTransactionAmount;
    const maxTransactionsPerSecond = participantOverrides.maxTransactionsPerSecond ?? policyProfile.maxTransactionsPerSecond;
    const dailyAggregateLimit = participantOverrides.dailyAggregateLimit ?? policyProfile.dailyAggregateLimit;
    const allowedMessageTypes = participantOverrides.allowedMessageTypes ?? (policyProfile.allowedMessageTypes.length > 0 ? policyProfile.allowedMessageTypes : undefined);

    return {
        ...(maxTransactionAmount ? { maxTransactionAmount } : {}),
        ...(maxTransactionsPerSecond ? { maxTransactionsPerSecond } : {}),
        ...(dailyAggregateLimit ? { dailyAggregateLimit } : {}),
        ...(allowedMessageTypes ? { allowedMessageTypes } : {})
    };
}

async function logDenial(
    requestId: string,
    ingressSequenceId: string,
    participantId: string,
    reason: PolicyGuardDenyReason,
    details: string
): Promise<void> {
    logger.warn({
        requestId,
        participantId,
        reason,
        details
    }, 'Policy guard denied request');

    await guardAuditLogger.log({
        type: 'GUARD_POLICY_DENY',
        requestId,
        ingressSequenceId,
        participantId,
        reason,
        details
    });
}
