/**
 * Symphony Identity Envelope (v1)
 * Cryptographically verifiable identity context
 *
 * Phase 7.1 Enhancement:
 * Added participant identity fields for regulated actor tracking.
 */

import type { ParticipantRole, ParticipantStatus } from '../participant/participant.js';

export interface IdentityEnvelopeV1 {
    version: 'v1';
    requestId: string;
    issuedAt: string;        // ISO-8601
    issuerService: string;   // e.g. 'control-plane', 'ingest-api'
    subjectType: 'client' | 'service';
    subjectId: string;       // client_id or service_id
    tenantId: string;
    policyVersion: string;
    roles: string[];         // DB / service roles
    signature: string;       // HMAC-sha256 in v1
    trustTier: 'external' | 'internal';
    certFingerprint?: string; // Phase 6.4: mTLS proof

    // Phase 7.1: Participant Identity (Regulated Actor)
    participantId?: string;           // Resolved participant ID
    participantRole?: ParticipantRole;    // BANK, PSP, OPERATOR, SUPERVISOR
    participantStatus?: ParticipantStatus; // ACTIVE, SUSPENDED, REVOKED
}

export type ValidatedIdentityContext = Readonly<IdentityEnvelopeV1>;
