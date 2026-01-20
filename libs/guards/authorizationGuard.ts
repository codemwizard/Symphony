/**
 * Symphony Authorization Guard — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Purpose: Enforce participant scope (non-ledger).
 *
 * This guard is a pre-flight filter, not a decision engine.
 * It validates capabilities against participant role before execution.
 *
 * Critical Constraint:
 * SUPERVISOR role is non-executing: blocked from all execution capabilities.
 * SUPERVISOR has read-only, evidence-access only.
 */

import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import { ResolvedParticipant, ParticipantRole } from '../participant/index.js';
import { Capability } from '../auth/capabilities.js';
import { DbRole } from '../db/roles.js';

export interface AuthorizationGuardContext {
    /** Request ID for correlation */
    readonly requestId: string;
    /** Ingress sequence ID */
    readonly ingressSequenceId: string;
    /** Resolved participant */
    readonly participant: ResolvedParticipant;
    /** Requested capability */
    readonly requestedCapability: Capability;
}

export type AuthorizationGuardResult =
    | { allowed: true }
    | { allowed: false; reason: AuthorizationGuardDenyReason };

export type AuthorizationGuardDenyReason =
    | 'SUPERVISOR_CANNOT_EXECUTE'
    | 'CAPABILITY_NOT_ALLOWED_FOR_ROLE';

/**
 * Capabilities allowed for SUPERVISOR (read-only, evidence-access).
 */
const SUPERVISOR_ALLOWED_CAPABILITIES: readonly Capability[] = [
    'instruction:read',
    'audit:read',
    'status:read',
    'policy:read'
];

/**
 * Execute authorization guard.
 * Enforces role-based capability restrictions.
 */
export async function executeAuthorizationGuard(
    role: DbRole,
    context: AuthorizationGuardContext
): Promise<AuthorizationGuardResult> {
    const { requestId, ingressSequenceId, participant, requestedCapability } = context;

    // SUPERVISOR role: non-executing, read-only access only
    if (participant.role === 'SUPERVISOR') {
        if (!SUPERVISOR_ALLOWED_CAPABILITIES.includes(requestedCapability)) {
            await logDenial(
                role,
                requestId,
                ingressSequenceId,
                participant.participantId,
                participant.role,
                requestedCapability,
                'SUPERVISOR_CANNOT_EXECUTE'
            );
            return { allowed: false, reason: 'SUPERVISOR_CANNOT_EXECUTE' };
        }
    }

    logger.debug({
        requestId,
        participantId: participant.participantId,
        role: participant.role,
        capability: requestedCapability
    }, 'Authorization guard passed');

    return { allowed: true };
}

async function logDenial(
    dbRole: DbRole,
    requestId: string,
    ingressSequenceId: string,
    participantId: string,
    role: ParticipantRole,
    capability: Capability,
    reason: AuthorizationGuardDenyReason
): Promise<void> {
    logger.warn({
        requestId,
        participantId,
        role,
        capability,
        reason
    }, 'Authorization guard denied request');

    await guardAuditLogger.log(dbRole, {
        type: 'GUARD_AUTHORIZATION_DENY',
        requestId,
        ingressSequenceId,
        participantId,
        role,
        capability,
        reason
    });
}
