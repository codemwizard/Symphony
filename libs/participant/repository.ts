/**
 * Symphony Participant Repository — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Database access layer for participant identity.
 * All queries use parameterized statements and explicit column lists.
 */

import { db } from '../db/index.js';
import {
    Participant,
    ParticipantStatus,
    ParticipantRole,
    LedgerScope,
    SandboxLimits
} from './participant.js';

interface ParticipantRow {
    participant_id: string;
    legal_entity_ref: string;
    mtls_cert_fingerprint: string;
    role: ParticipantRole;
    policy_profile_id: string;
    ledger_scope: LedgerScope;
    sandbox_limits: SandboxLimits;
    status: ParticipantStatus;
    status_changed_at: string;
    status_reason: string | null;
    created_at: string;
    updated_at: string;
    created_by: string;
}

/**
 * Find participant by mTLS certificate fingerprint.
 * Returns null if not found — does NOT throw.
 */
export async function findByFingerprint(fingerprint: string): Promise<Participant | null> {
    const result = await db.query(
        `SELECT
            participant_id,
            legal_entity_ref,
            mtls_cert_fingerprint,
            role,
            policy_profile_id,
            ledger_scope,
            sandbox_limits,
            status,
            status_changed_at,
            status_reason,
            created_at,
            updated_at,
            created_by
        FROM participants
        WHERE mtls_cert_fingerprint = $1
        LIMIT 1`,
        [fingerprint]
    );

    if (result.rows.length === 0) {
        return null;
    }

    const row = result.rows[0] as ParticipantRow;
    return mapRowToParticipant(row);
}

/**
 * Find participant by ID.
 * Returns null if not found — does NOT throw.
 */
export async function findById(participantId: string): Promise<Participant | null> {
    const result = await db.query(
        `SELECT
            participant_id,
            legal_entity_ref,
            mtls_cert_fingerprint,
            role,
            policy_profile_id,
            ledger_scope,
            sandbox_limits,
            status,
            status_changed_at,
            status_reason,
            created_at,
            updated_at,
            created_by
        FROM participants
        WHERE participant_id = $1
        LIMIT 1`,
        [participantId]
    );

    if (result.rows.length === 0) {
        return null;
    }

    const row = result.rows[0] as ParticipantRow;
    return mapRowToParticipant(row);
}

/**
 * Check if participant status is ACTIVE.
 * Non-ACTIVE participants are fail-closed at ingress.
 */
export function isParticipantActive(participant: Participant): boolean {
    return participant.status === 'ACTIVE';
}

/**
 * Map database row to Participant object.
 */
function mapRowToParticipant(row: ParticipantRow): Participant {
    return Object.freeze({
        participantId: row.participant_id,
        legalEntityRef: row.legal_entity_ref,
        mtlsCertFingerprint: row.mtls_cert_fingerprint,
        role: row.role,
        policyProfileId: row.policy_profile_id,
        ledgerScope: row.ledger_scope,
        sandboxLimits: row.sandbox_limits,
        status: row.status,
        statusChangedAt: row.status_changed_at,
        statusReason: row.status_reason,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        createdBy: row.created_by
    });
}
