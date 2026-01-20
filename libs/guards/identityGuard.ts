/**
 * Symphony Identity Guard — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Purpose: Reject unauthenticated or non-ACTIVE execution.
 *
 * This guard is a pre-flight filter, not a decision engine.
 * It operates on attested requests only (INVARIANT SYS-7-1-A).
 *
 * Behavior:
 * - Validates mTLS context is present
 * - Validates participant resolution succeeded
 * - Rejects SUSPENDED or REVOKED participants → logs PARTICIPANT_STATUS_DENY
 * - Fail-closed on missing context
 */

import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import { ResolvedParticipant, ParticipantStatus } from '../participant/index.js';
import { DbRole } from '../db/roles.js';

export interface IdentityGuardContext {
    /** Request ID for correlation */
    readonly requestId: string;
    /** Ingress sequence ID (INVARIANT SYS-7-1-A) */
    readonly ingressSequenceId: string;
    /** mTLS certificate fingerprint (may be absent) */
    readonly certFingerprint: string | undefined;
    /** Resolved participant (may be absent) */
    readonly participant: ResolvedParticipant | undefined;
}

export type IdentityGuardResult =
    | { allowed: true }
    | { allowed: false; reason: IdentityGuardDenyReason };

export type IdentityGuardDenyReason =
    | 'NO_MTLS_CONTEXT'
    | 'NO_PARTICIPANT_RESOLVED'
    | 'PARTICIPANT_STATUS_DENY';

/**
 * Execute identity guard.
 * Fail-closed: Any missing context results in denial.
 */
export async function executeIdentityGuard(
    role: DbRole,
    context: IdentityGuardContext
): Promise<IdentityGuardResult> {
    const { requestId, ingressSequenceId, certFingerprint, participant } = context;

    // Check 1: mTLS context must be present
    if (!certFingerprint) {
        await logDenial(role, requestId, ingressSequenceId, 'NO_MTLS_CONTEXT');
        return { allowed: false, reason: 'NO_MTLS_CONTEXT' };
    }

    // Check 2: Participant must be resolved
    if (!participant) {
        await logDenial(role, requestId, ingressSequenceId, 'NO_PARTICIPANT_RESOLVED');
        return { allowed: false, reason: 'NO_PARTICIPANT_RESOLVED' };
    }

    // Check 3: Participant must be ACTIVE
    if (participant.status !== 'ACTIVE') {
        await logStatusDenial(role, requestId, ingressSequenceId, participant.participantId, participant.status);
        return { allowed: false, reason: 'PARTICIPANT_STATUS_DENY' };
    }

    logger.debug({ requestId, participantId: participant.participantId }, 'Identity guard passed');
    return { allowed: true };
}

async function logDenial(
    role: DbRole,
    requestId: string,
    ingressSequenceId: string,
    reason: IdentityGuardDenyReason
): Promise<void> {
    logger.warn({ requestId, reason }, 'Identity guard denied request');

    await guardAuditLogger.log(role, {
        type: 'GUARD_IDENTITY_DENY',
        requestId,
        ingressSequenceId,
        reason
    });
}

async function logStatusDenial(
    role: DbRole,
    requestId: string,
    ingressSequenceId: string,
    participantId: string,
    status: ParticipantStatus
): Promise<void> {
    logger.warn({ requestId, participantId, status }, 'Participant status denial');

    await guardAuditLogger.log(role, {
        type: 'PARTICIPANT_STATUS_DENY',
        requestId,
        ingressSequenceId,
        participantId,
        status
    });
}
