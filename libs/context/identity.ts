/**
 * Symphony Identity Envelope (v1)
 * Cryptographically verifiable identity context
 */
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
}

export type ValidatedIdentityContext = Readonly<IdentityEnvelopeV1>;
