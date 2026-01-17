/**
 * Symphony Participant Resolver — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Resolution service implementing the Phase 7.1 execution flow:
 * 1. TLS handshake (infrastructure)
 * 2. Certificate validation (infrastructure)
 * 3. Participant resolution <-- THIS COMPONENT
 * 4. Policy binding
 * 5. Execution authorization
 *
 * INVARIANT SYS-7-1-A:
 * No execution intent may be processed unless an ingress attestation
 * record with a valid sequence ID exists.
 *
 * A request without a resolved participant identity cannot execute.
 */

import { TrustFabric } from '../auth/trustFabric.js';
import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import {
    ParticipantResolutionResult,
    ParticipantResolutionFailure
} from './participant.js';
import { findByFingerprint, isParticipantActive } from './repository.js';
import { findById as findPolicyProfile } from '../policy/repository.js';

export interface ParticipantResolutionContext {
    /** Request ID for correlation */
    readonly requestId: string;
    /** mTLS certificate fingerprint from TLS context */
    readonly certFingerprint: string;
    /** Ingress sequence ID (INVARIANT SYS-7-1-A) */
    readonly ingressSequenceId: string;
}

/**
 * Resolve participant identity from mTLS certificate fingerprint.
 *
 * This is the critical identity resolution step in the execution flow.
 * Failure results in request rejection (fail-closed).
 *
 * @param context Resolution context with fingerprint and audit correlation
 * @returns Resolution result with participant or failure reason
 */
export async function resolveParticipant(
    context: ParticipantResolutionContext
): Promise<ParticipantResolutionResult> {
    const { requestId, certFingerprint, ingressSequenceId } = context;

    // Step 1: Validate certificate is not revoked in Trust Fabric
    const trustIdentity = TrustFabric.resolveIdentity(certFingerprint);
    if (!trustIdentity) {
        await logResolutionFailure(requestId, ingressSequenceId, 'CERTIFICATE_REVOKED', certFingerprint);
        return { success: false, reason: 'CERTIFICATE_REVOKED' };
    }

    // Step 2: Resolve participant from fingerprint
    const participant = await findByFingerprint(certFingerprint);
    if (!participant) {
        await logResolutionFailure(requestId, ingressSequenceId, 'FINGERPRINT_NOT_FOUND', certFingerprint);
        return { success: false, reason: 'FINGERPRINT_NOT_FOUND' };
    }

    // Step 3: Check participant status (fail-closed for non-ACTIVE)
    if (!isParticipantActive(participant)) {
        const reason: ParticipantResolutionFailure =
            participant.status === 'SUSPENDED' ? 'PARTICIPANT_SUSPENDED' : 'PARTICIPANT_REVOKED';

        await logResolutionFailure(requestId, ingressSequenceId, reason, certFingerprint, participant.participantId);
        return { success: false, reason };
    }

    // Step 4: Validate policy profile exists
    const policyProfile = await findPolicyProfile(participant.policyProfileId);
    if (!policyProfile) {
        await logResolutionFailure(requestId, ingressSequenceId, 'POLICY_PROFILE_NOT_FOUND', certFingerprint, participant.participantId);
        return { success: false, reason: 'POLICY_PROFILE_NOT_FOUND' };
    }

    // Step 5: Log successful resolution
    await guardAuditLogger.log({
        type: 'PARTICIPANT_RESOLVED',
        requestId,
        ingressSequenceId,
        participantId: participant.participantId,
        role: participant.role,
        legalEntityRef: participant.legalEntityRef,
        policyProfileId: participant.policyProfileId
    });

    logger.info({
        requestId,
        participantId: participant.participantId,
        role: participant.role
    }, 'Participant resolved successfully');

    return { success: true, participant };
}

/**
 * Log participant resolution failure for audit trail.
 */
async function logResolutionFailure(
    requestId: string,
    ingressSequenceId: string,
    reason: ParticipantResolutionFailure,
    certFingerprint: string,
    participantId?: string
): Promise<void> {
    logger.warn({
        requestId,
        reason,
        certFingerprint: certFingerprint.substring(0, 16) + '...' // Truncate for log safety
    }, 'Participant resolution failed');

    await guardAuditLogger.log({
        type: 'PARTICIPANT_RESOLUTION_FAILED',
        requestId,
        ingressSequenceId,
        reason,
        participantId: participantId ?? null
    });
}
