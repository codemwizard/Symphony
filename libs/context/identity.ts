/**
 * Symphony Identity Envelope (v1)
 * Cryptographically verifiable identity context
 *
 * Phase 7.1 Enhancement:
 * Added participant identity fields for regulated actor tracking.
 */

import type { ParticipantRole, ParticipantStatus } from '../participant/participant.js';
export type { ParticipantRole, ParticipantStatus };

type TrustTier = 'external' | 'internal' | 'user';

type BaseEnvelopeV1 = {
    version: 'v1';
    requestId: string;
    issuedAt: string;       // ISO-8601
    issuerService: string;  // e.g. 'control-plane', 'ingest-api'
    subjectId: string;      // client_id / service_id / user sub
    tenantId: string;       // tenant scope for the request
    policyVersion: string;
    roles: string[];        // DB/service roles (sorted before signing)
    signature: string;      // HMAC-SHA256 in v1
    trustTier: TrustTier;
    // certFingerprint REMOVED from base to enforce strict typing per variant
};

export type ClientIdentityEnvelopeV1 = BaseEnvelopeV1 & {
    subjectType: 'client';
    trustTier: 'external'; // locked
    // certFingerprint REMOVED (client cannot be mTLS principal)
};

export type ServiceIdentityEnvelopeV1 = BaseEnvelopeV1 & {
    subjectType: 'service';
    trustTier: 'internal'; // locked
    certFingerprint: string; // REQUIRED for service
};

export type UserIdentityEnvelopeV1 = BaseEnvelopeV1 & {
    subjectType: 'user';
    trustTier: 'user'; // locked, unambiguous
    participantId: string; // MANDATORY tenant anchor
    participantRole: ParticipantRole;
    participantStatus: ParticipantStatus;
    // certFingerprint forbidden
};

export type IdentityEnvelopeV1 =
    | ClientIdentityEnvelopeV1
    | ServiceIdentityEnvelopeV1
    | UserIdentityEnvelopeV1;

export type ValidatedIdentityContext = Readonly<IdentityEnvelopeV1>;
